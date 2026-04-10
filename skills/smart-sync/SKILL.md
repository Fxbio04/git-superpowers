---
name: smart-sync
description: Rebase your branch onto main with intelligent, topic-aware conflict resolution. Use when the user wants to sync their branch, pull from main, update from main, rebase, get the latest changes, resolve merge conflicts, or says things like "sync my branch", "rebase from main", "ich muss den neusten Stand ziehen", "main in meine branch holen", "merge conflicts lösen", or "branch aktualisieren". Also triggers on /smart-sync. Use this instead of raw git rebase — it analyzes conflicts by topic and guides resolution.
---

# Smart Sync

Rebase your branch onto main with topic-aware conflict resolution. Instead of presenting conflicts as raw file diffs, this skill groups them by topic and guides you through resolution with clear explanations of what each side changed and why.

Read `references/git-safety.md` before your first action.

## Workflow

### Step 1: Preflight

Check for uncommitted changes and stash them:

```bash
git status --porcelain
```

If there are changes:
```bash
git stash push -m "smart-sync auto-stash $(date +%Y-%m-%d-%H%M)"
```

Tell the user: "Stashed your uncommitted changes — they'll be restored after sync."

### Step 2: Fetch and Analyze

```bash
git fetch origin
```

Detect the main branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```
Fallback: check `origin/main`, then `origin/master`.

Check what's coming in:
```bash
git log --oneline HEAD..origin/main
```

If empty: "Your branch is already up to date with main." Pop stash if exists, stop.

Show the user:
```
12 new commits from main:

a1b2c3d feat: new API structure for orders
d4e5f6g fix: auth token refresh
...

These files will be affected:
```
```bash
git diff --stat HEAD...origin/main
```

Warn about potential conflicts — check if any affected files also have local changes:
```bash
comm -12 \
  <(git diff --name-only HEAD...origin/main | sort) \
  <(git diff --name-only $(git merge-base HEAD origin/main)..HEAD | sort)
```

If there's overlap, warn: "These files were changed in both main and your branch — conflicts are likely: ..."

**Tip:** Run `/conflict-simulator` first to preview conflicts without starting the rebase.

### Step 3: Rebase

```bash
git rebase origin/main
```

If it succeeds without conflicts → skip to Step 6.

### Step 4: Conflict Analysis

When conflicts occur, analyze them by topic. For complex conflicts (>3 files), spawn the conflict-resolver agent: read `agents/conflict-resolver.md` and run it as a subagent. For simpler cases, resolve inline.

Read `references/conflict-resolution.md` for the full strategy.

```bash
git diff --name-only --diff-filter=U
```

For each conflicted file, read it and analyze the conflict markers. Group conflicts by topic:

```
Merge Conflicts detected:

[Login Bugfix] 1 conflict
  → src/auth/login.tsx
    Your side: redirect fix after login
    Main's side: auth module refactoring
    Recommendation: both changes are independent — combine them

[Amazon Feature] 2 conflicts
  → src/utils/api.ts
    Your side: new Amazon API imports
    Main's side: API module restructured to new pattern
    Recommendation: adapt your imports to main's new structure

  → src/routes.tsx
    Your side: new /amazon route
    Main's side: routes moved to new router format
    Recommendation: add your route using main's new format

[Mixed] 1 conflict
  → src/config.ts
    Contains changes for BOTH Login Bugfix and Amazon Feature
    → Will resolve hunk by hunk
```

### Step 5: Resolve

For each topic group, ask the user:

**Simple conflicts:**
- **"Keep your version"** → `git checkout --theirs <file> && git add <file>`
  (Yes, `--theirs` — during rebase, YOUR changes are "theirs" because they're being replayed)
- **"Take main's version"** → `git checkout --ours <file> && git add <file>`
- **"Combine both"** → Claude edits the file to merge both changes, removes conflict markers, `git add <file>`
- **"Show me the conflict"** → display the conflicted section with context and let the user decide

**Mixed conflicts:**
Show each conflict hunk with its topic label. Ask per hunk what to do.

After resolving all files in this rebase step:
```bash
git rebase --continue
```

If new conflicts appear (next commit), repeat the analysis.

**Escape hatch:** At any point, offer `git rebase --abort` to undo everything.

**Overwhelm detection:** If there are more than 5 conflicted files, proactively suggest: "This is a complex rebase with many conflicts. Would you rather abort and sync more frequently to avoid this in the future?"

**rerere:** If `git rerere` is enabled (`git config rerere.enabled`), git may have auto-resolved some conflicts using previously recorded resolutions. Check `git rerere status` — if files appear there, show the user: "git rerere auto-resolved these files based on your previous conflict resolutions. Please verify they look correct before continuing." If rerere is NOT enabled and the user just resolved conflicts manually, suggest: "Tip: Enable `git rerere` (`git config --global rerere.enabled true`) to automatically remember these resolutions for next time."

### Step 6: Push

The rebase rewrote history, so a force push is needed:

```bash
git push --force-with-lease origin <branch>
```

If this fails (someone else pushed to the same branch), warn the user and explain the situation. Only use `--force` with explicit confirmation.

### Step 7: Cleanup

Pop the stash if one was created:
```bash
git stash list
```
If the auto-stash is there:
```bash
git stash pop
```

Verify sync:
```bash
git log --oneline <branch>..origin/main
```
Should be empty (Behind: 0).

Show summary: "Branch synced. 12 commits from main applied. 3 conflicts resolved. Behind main: 0."

## Rules

- Never use `git merge` — always `git rebase`
- Never use `--force` — always `--force-with-lease` (unless user explicitly confirms)
- Never use `git rebase -i` (interactive mode requires stdin)
- Always communicate that during rebase, `--ours` = main and `--theirs` = your branch
- Always verify Behind: 0 after push
- Always pop stash after completion
