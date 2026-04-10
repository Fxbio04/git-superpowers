---
name: pr-prep
description: Prepare a clean, well-described pull request — audit the branch, generate a PR description from commits and diffs, and create the PR via GitHub CLI. Use when the user wants to open a PR, is ready to merge, or says things like "prepare PR", "PR erstellen", "ready for merge", "PR vorbereiten", "make PR to main", "pull request", "ich will mergen", "branch fertig", "PR aufmachen", or "submit for review". Also triggers on /pr-prep.
---

# PR Prep

Turn your branch into a clean, reviewable pull request. This skill audits for issues, checks for conflicts with main, generates a clear description, and creates the PR — so reviewers get context without asking.

Read `references/git-safety.md` before your first action.

## Workflow

### Step 1: Branch Status Check

```bash
git fetch origin
git branch --show-current
git status --porcelain
git log --oneline origin/main..HEAD
```

If there are uncommitted changes, stop:
```
You have uncommitted changes. Commit or stash them before creating a PR.
Run smart-commit to commit them, or: git stash push -m "pr-prep stash"
```

If no commits ahead of main: "This branch has no commits ahead of main — nothing to PR."

Show the summary:
```
Branch: fb
Status: 5 commits ahead of main, 0 uncommitted changes

Commits that will be in this PR:
  a1b2c3d feat(amazon): add analytics dashboard
  d4e5f6g feat(amazon): KPI grid component
  e7f8g9h fix(amazon): correct currency formatting
  f1g2h3i chore(deps): add react-charts
  j4k5l6m refactor(utils): extract API helpers
```

### Step 2: Check if Behind Main

```bash
git log --oneline HEAD..origin/main
```

If there are commits: warn the user.

```
Your branch is 8 commits behind main.
This means:
- Reviewers may see conflicts in the PR diff
- The merge may fail if conflicts exist

Recommended: run smart-sync first to rebase onto the latest main.
Skip anyway? (y/n)
```

Only continue on explicit confirmation. Remember to re-fetch after sync.

### Step 3: Safety Audit

Run the same checks as safe-push — these are the things reviewers will catch if you don't. Read `references/git-safety.md` for the full list of secret patterns.

Scan `git diff origin/main..HEAD` for:

**Debug artifacts:**
- `console.log`, `console.debug`, `debugger` (outside test files)

**Conflict markers:**
```bash
git diff origin/main..HEAD | grep -n "^+.*<<<<<<\|^+.*======\|^+.*>>>>>>"
```

**Secret patterns:**
Scan added lines for patterns from `references/git-safety.md` (API keys, tokens, connection strings).

**Incomplete code signals:**
- Imports referencing files not present in the branch
- TODO/FIXME/HACK in new code
- Commented-out code blocks

If issues found, show them and ask:
```
Issues found before creating PR:
[1] console.log in src/amazon/dashboard.tsx:45
[2] TODO in src/utils/api.ts:12 — "TODO: add error handling"

Fix these before creating the PR? (recommended)
[f] Fix all  [s] Skip and create PR anyway  [c] Cancel
```

### Step 4: Conflict Dry-Run

Check whether this branch would conflict with main if merged right now. This is a read-only simulation — it does not touch your branch.

```bash
# Save current position
CURRENT=$(git branch --show-current)

# Try the merge in a detached HEAD state
git checkout --detach origin/main --quiet
git merge --no-commit --no-ff $CURRENT --quiet 2>&1
MERGE_RESULT=$?

# Clean up regardless of outcome
git merge --abort 2>/dev/null
git checkout $CURRENT --quiet
```

If `MERGE_RESULT` is non-zero, extract the conflicted files:
```bash
git diff --name-only --diff-filter=U
```

Report:
```
Conflict Simulation Result:
  2 files would conflict if merged now:
  - src/amazon/api.ts (both branches modified)
  - src/routes.tsx (both branches modified)

These will show as conflicts in the PR. Run smart-sync to resolve them before merging.
Continue anyway? (y/n)
```

If no conflicts: "No conflicts — this branch merges cleanly into main."

### Step 5: Generate PR Description

Read the commits and their diffs to build a structured description.

```bash
git log --format="%s%n%b" origin/main..HEAD   # subject + body for each commit
git diff --stat origin/main..HEAD             # file summary
```

Group commits by topic: commits sharing a scope (`feat(amazon)`, `fix(amazon)`) belong together. Read `references/topic-detection.md` for grouping logic.

Draft the description using this format:

```markdown
## Summary
- Added Amazon analytics dashboard with KPI overview and trend charts
- Refactored API utilities into a shared helper module

## Changes

### Amazon Analytics
- `DashboardView` — main view with KPI grid (revenue, orders, returns)
- `KPICard` component with sparkline trend support
- Fixed currency formatting for EUR/USD display

### Infrastructure
- Added `react-charts` dependency (v2.1)
- Extracted `fetchWithRetry` and `buildQueryParams` into `src/utils/api.ts`

## Test Plan
- [ ] Open /amazon in dev — dashboard loads without errors
- [ ] KPI cards show correct values from API
- [ ] Currency formatting correct for EUR and USD
- [ ] Charts render on different screen sizes
- [ ] Existing routes still work (no regression)
```

Show the draft and ask:
```
PR Description draft — review and edit, or press Enter to use as-is:
```

Let the user edit the title and body. Suggest a title from the most significant commit or the branch name.

### Step 6: Create the PR

```bash
gh pr create \
  --title "<title>" \
  --body "$(cat <<'EOF'
<description>
EOF
)" \
  --base main \
  --head <branch>
```

If `gh` is not installed: show the title and description formatted for copy-paste into GitHub.

After creation, show:
```
PR created: https://github.com/<org>/<repo>/pull/<number>

Next steps:
- Share the PR URL with reviewers
- After the PR is merged, sync your other branches: run smart-sync on each
```

**Note on GitHub Rebase:** If the repo uses "Rebase and merge" as the merge method, GitHub will create new commit SHAs even for identical changes. This means after your PR is merged, your local branch will diverge from main even though the code is the same. Run `/smart-sync` after merge to clean up.

## Rules

- Never create a PR with conflict markers in the diff
- Never create a PR without showing the outgoing commits first
- Always run the conflict dry-run — reviewers will notice conflicts, even if the user doesn't ask
- The PR description must have a Test Plan section — reviewers need to know what to verify
- Always clean up the detached HEAD state after the conflict simulation, even on error
