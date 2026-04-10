# Conflict Resolution

Strategies for resolving merge conflicts during rebase, with topic-aware analysis.

## Conflict Markers

Git marks conflicts with three markers:
```
<<<<<<< HEAD
Code from the base (during rebase: this is main's version)
=======
Code from the branch being applied (during rebase: this is your version)
>>>>>>> commit-message
```

## The Rebase Inversion

This is the single most confusing thing about rebase conflicts and must always be communicated clearly to the user.

During `git rebase origin/main`:
- `--ours` = **main** (the base being rebased onto)
- `--theirs` = **your branch** (the commits being replayed)

This is the **opposite** of `git merge`, where `--ours` is your branch and `--theirs` is main.

When communicating with the user, never use `--ours`/`--theirs` terminology. Instead say:
- "Keep your version" (means `--theirs` during rebase)
- "Take main's version" (means `--ours` during rebase)

## Topic-Aware Conflict Resolution

### Step 1: Survey All Conflicts

```bash
git diff --name-only --diff-filter=U
```

This lists all files with unresolved conflicts. Read each file to understand what the conflict contains.

### Step 2: Categorize by Topic

For each conflicted file, read the conflict markers and determine:
- What topic does YOUR side of the conflict belong to?
- What did main change?
- Is this a single-topic conflict or mixed?

Present a summary grouped by topic:
```
[Bugfix Login] 1 conflict
  → src/auth/login.tsx: your redirect fix vs. main's auth refactor

[Amazon Feature] 2 conflicts
  → src/api.ts: your Amazon imports vs. main's API restructure
  → src/routes.tsx: your new route vs. main's route cleanup

[Mixed] 1 conflict
  → src/config.ts: contains both Bugfix and Amazon changes
```

### Step 3: Resolve by Topic

Offer resolution options per topic group:

**Simple conflicts (single topic):**
- "Keep your version" → `git checkout --theirs <file> && git add <file>`
- "Take main's version" → `git checkout --ours <file> && git add <file>`
- "Let me handle it" → show the conflict, let user decide

**Mixed conflicts:**
These require hunk-level resolution. For each conflict marker in the file:
1. Show the conflict with a topic label
2. Ask the user what to keep
3. Edit the file to resolve — remove conflict markers, keep chosen code
4. `git add <file>` when all conflicts in the file are resolved

### Step 4: Continue or Abort

After resolving all conflicts in the current commit:
```bash
git rebase --continue
```

If new conflicts appear (next commit in rebase), repeat the process.

At any point, the user can abort:
```bash
git rebase --abort
```

## When to Recommend Abort

Suggest aborting when:
- More than 5 conflicted files — the rebase is too complex
- Conflicts touch files the user doesn't recognize
- The same file conflicts repeatedly across multiple rebase steps
- The user seems confused or frustrated

It's always safer to abort and try a different strategy than to push through a messy rebase.

## git rerere — Automatic Conflict Memory

`git rerere` (REuse REcorded REsolution) remembers how you resolved conflicts and automatically applies the same resolution when the same conflict appears again. This is extremely valuable for teams that rebase frequently.

**Enable it (one-time setup):**
```bash
git config --global rerere.enabled true
```

Once enabled, git silently records every conflict resolution. Next time the same conflict appears during rebase, cherry-pick, or merge, git applies the previous resolution automatically. You still need to review and `git add` the result, but the manual editing is done for you.

**Commands:**
- `git rerere status` — show files with recorded resolutions
- `git rerere diff` — show what rerere would apply
- `git rerere forget <file>` — forget a specific resolution (if it was wrong)

**When to recommend enabling rerere:**
- User rebases regularly and hits the same conflicts
- Team members work on overlapping files across branches
- The user has resolved a conflict and it keeps coming back

Always suggest enabling rerere when a user resolves the same conflict pattern more than once.

## After Resolution

When rebase completes successfully:
1. Verify the branch looks right: `git log --oneline -10`
2. Check no conflict markers remain: `grep -rn "<<<<<<" src/` (adapt path)
3. Run a quick build/test if available
