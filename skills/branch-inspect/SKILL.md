---
name: branch-inspect
description: Inspect what other branches are doing and predict merge conflicts before they happen. Use when the user wants to see what others have been working on, check other branches, compare branches, find potential conflicts, understand branch differences, or says things like "what has Bobby been doing", "show me the other branches", "was machen die anderen", "welche branches gibt es", "gibt es conflicts", "compare branches", or "wer hat was gemacht". Also triggers on /branch-inspect.
---

# Branch Inspect

See what's happening on other branches — who committed what, what changed, and where your branch might conflict with theirs. Predicts conflicts before they happen so you can prepare.

Read `references/git-safety.md` and `references/branch-history.md` before your first action.

## Workflow

### Step 1: Show All Branches

```bash
git fetch origin --quiet
git branch -r --sort=-committerdate --format='%(refname:short) %(committerdate:relative) %(authorname)'
```

Run `git fetch origin --quiet` at the start. If inspecting multiple repos, fetch all in parallel before displaying results.

Filter out `origin/HEAD` and present:

```
Active Branches:

[1] origin/bb    — 2 hours ago (Bobby)
[2] origin/fb    — 1 day ago (you)
[3] origin/it    — 3 days ago (IT)
[4] origin/main  — 5 hours ago (last merge)
```

Highlight the user's current branch. Hide branches with no activity in the last 90 days unless the user asks for all.

Ask: **"Which branch do you want to inspect? (number, name, or 'compare' for overlap analysis)"**

### Step 2: Branch Details

When the user picks a branch, show:

**Commit summary:**
```bash
git log --oneline origin/main..origin/<branch> | head -20
git shortlog -sn origin/main..origin/<branch>
```

```
origin/bb — 8 commits ahead of main

  Bobby (8 commits):
  a1b2c3d feat(tickets): new ticket dashboard
  d4e5f6g feat(tickets): ticket filter component
  e7f8g9h fix(warehouse): stock count correction
  ...
```

**Files changed:**
```bash
git diff --stat origin/main..origin/<branch>
```

**Summary:** Read the commit messages and provide a human-readable summary:
"Bobby is building a new ticket dashboard (6 commits) and fixed a stock counting bug in the warehouse module (2 commits)."

### Step 3: Compare With Your Branch

This is the most valuable part — finding potential conflicts before they happen.

```bash
# Files you both changed since main
comm -12 \
  <(git diff --name-only origin/main..HEAD | sort) \
  <(git diff --name-only origin/main..origin/<branch> | sort)
```

If there are overlapping files:

```
Overlap between fb and bb:

⚠️ 3 files changed in both branches:

  src/utils/api.ts
    You: added Amazon API imports (lines 12-15, 45-50)
    bb:  added Ticket API endpoint (lines 30-35)
    Risk: LOW — changes are in different parts of the file

  src/routes.tsx
    You: added /amazon route
    bb:  added /tickets route
    Risk: MEDIUM — both adding routes, might conflict depending on structure

  package.json
    You: added react-charts dependency
    bb:  added ticket-ui dependency
    Risk: LOW — different dependencies, auto-mergeable
```

For each overlapping file, read both sides' diffs to assess conflict risk:
- **LOW**: Changes in different parts of the file, will auto-merge
- **MEDIUM**: Changes near each other, might conflict
- **HIGH**: Changes on the same lines, will definitely conflict

For a deeper conflict simulation, run `/conflict-simulator`. To see actual code differences, use `/cross-compare`.

### Step 4: Proactive Recommendations

Based on the analysis, suggest actions:

**If conflicts are likely:**
"If bb merges to main before you, you'll likely have conflicts in src/routes.tsx. You could:
1. Sync now (before bb merges) to minimize future conflicts
2. Wait and handle conflicts during your next sync
3. Coordinate with Bobby to merge in a specific order"

**If no conflicts:**
"No overlapping changes — you and bb won't conflict regardless of merge order. ✓"

**If a branch is very stale:**
"Branch origin/it hasn't been updated in 3 days and is 25 commits behind main. It might have significant conflicts when it syncs."

### Step 5: Multi-Branch Comparison (Optional)

If the user says "compare" or asks about all branches:

```
Cross-Branch Overlap Matrix:

         fb    bb    it
fb        —    3 ⚠️   0 ✓
bb       3 ⚠️   —    1 ⚠️
it       0 ✓   1 ⚠️   —

⚠️ fb and bb share 3 modified files
⚠️ bb and it share 1 modified file
✓ fb and it have no overlap
```

## Token Efficiency

- Branch listing: ~1 line per branch
- Commit summary: use `--oneline`, limit to 20
- Overlap detection: `comm` command produces minimal output
- Only read individual file diffs when assessing conflict risk for overlapping files
