---
name: cherry-pick
description: Pick specific commits from other branches with duplicate detection and conflict handling. Triggers: cherry-pick, "hol den fix von", "nimm den commit von", "grab that bugfix from", /cherry-pick.
---

# Cherry-Pick

Apply specific commits from another branch to your current branch — without bringing everything else along. This is the right move when a branch has one useful fix but isn't ready to merge.

## Safety (always apply)
- Always show `git show --stat` before applying — no silent picks
- Always offer `--abort` while a pick is in progress
- Pick in chronological order (oldest first) to respect dependencies
- Check for detached HEAD and missing remote before starting

## Workflow

### Step 1: Identify the Source Branch

If the user named a branch, use it. If not, show available branches:

```bash
git fetch origin --quiet
git branch -r --sort=-committerdate \
  --format='%(refname:short) %(committerdate:relative) %(authorname)' \
  | grep -v 'HEAD'
```

Present them:
```
Remote branches (most recent first):

[1] origin/bb    — 2 hours ago (Bobby)
[2] origin/it    — 1 day ago (IT)
[3] origin/main  — 3 hours ago

Pick from which branch?
```

**Tip:** Use `/branch-inspect` first to see what's on other branches and find the right commits.

### Step 2: Show Available Commits

List commits on that branch that are not yet in main — those are the candidates:

```bash
git log --oneline origin/main..origin/<source-branch>
```

Show them with an index:
```
Commits on origin/bb (not yet in main):

[1] a1b2c3d fix(warehouse): correct stock count calculation
[2] d4e5f6g feat(tickets): new ticket dashboard
[3] e7f8g9h feat(tickets): ticket filter component
[4] f1g2h3i chore: update dependencies
```

Ask: **"Which commits do you want? (numbers, hash, or describe it — e.g. 'the bugfix')"**

If the user describes it in natural language, match to the commit message. Show your match and confirm: "Found this commit — does this look right? `fix(warehouse): correct stock count calculation`"

### Step 3: Preview What's Coming In

Before picking, show the diff of what will be applied. This prevents surprises.

```bash
git show <hash> --stat
```

For each selected commit:
```
Commit a1b2c3d — fix(warehouse): correct stock count calculation

  Files that will change:
    M src/warehouse/stock.ts (+12 -8)
    M src/warehouse/stock.test.ts (+24 -6)
```

Ask: **"Apply this? (y to continue, d for full diff, n to skip)"**

If the user asks for the full diff:
```bash
git show <hash>
```

### Step 4: Check for Duplicate Changes

Before picking, check if the current branch already has an equivalent change — cherry-picking a commit that you already applied creates a confusing duplicate.

```bash
# Check if a similar change exists
git log --oneline --all --grep="<commit subject>" | grep -v <source-hash>

# Also check if the file was already patched the same way
git diff origin/main..HEAD -- <files-in-commit>
```

If similar changes are found, warn:
```
Warning: Your branch may already contain a similar change:
  e9f0g1h fix(warehouse): stock count fix (your branch, 3 days ago)

Cherry-picking might create a duplicate patch. Review and proceed anyway? (y/n)
```

### Step 5: Apply the Commits

Pick commits one by one (in chronological order — oldest first to avoid dependency issues):

```bash
git cherry-pick <hash>
```

After each successful pick, confirm:
```
Applied: a1b2c3d fix(warehouse): correct stock count calculation
```

**On Conflict:**

If `git cherry-pick` reports a conflict:

```bash
git diff --name-only --diff-filter=U    # Show conflicted files
```

```
Conflict in src/warehouse/stock.ts

Your branch changed lines 45-52 (different logic).
The incoming commit also changed lines 44-55.

Options:
[1] Keep your version (skip the incoming change for this file)
[2] Take the incoming version (overwrite your changes in this file)
[3] Combine both — Claude will merge them
[4] Show the conflict
[5] Abort cherry-pick
```

Read `references/conflict-resolution.md` for the "Combine both" strategy.

After resolving:
```bash
git add <resolved-files>
git cherry-pick --continue
```

**Abort option:**
```bash
git cherry-pick --abort
```

Always keep `--abort` visible as an option while a pick is in progress.

### Step 6: Verify the Result

After all commits are applied:

```bash
git log --oneline origin/main..HEAD   # What's now on your branch
git diff --stat <original-tip>..HEAD  # What changed from before the pick
```

Show summary:
```
Cherry-pick complete.

Applied to your branch (fb):
  a1b2c3d fix(warehouse): correct stock count calculation

Your branch is now 6 commits ahead of main (was 5).
```

### Step 7: Push (Optional)

Ask: **"Push these changes to origin/<branch>?"**

If yes, check for remote changes first (required by `references/git-safety.md`):
```bash
git fetch origin
git log --oneline HEAD..origin/<current-branch>
```

If the remote has new commits, warn and suggest `git pull --rebase origin <branch>` first.

Then push:
```bash
git push origin <branch>
```

## Rules

- Always show `git show --stat` before applying a commit — no silent picks
- Always warn about duplicate changes before proceeding
- Always offer `--abort` while a pick is in progress
- Pick commits in chronological order (oldest first) to respect dependencies
- Never use `git cherry-pick -n` (no-commit) silently — it leaves changes unstaged without explanation
- After all picks, always show `git log --oneline` to confirm the result
