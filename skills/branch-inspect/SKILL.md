---
name: branch-inspect
description: Inspect other branches — who committed what, file overlaps, predicted conflicts. Triggers: "was machen die anderen", "welche branches gibt es", "compare branches", "wer hat was gemacht", /branch-inspect.
---

# Branch Inspect

See what's happening on other branches — who committed what, what changed, and where your branch might conflict with theirs. Predicts conflicts before they happen so you can prepare.

## Safety (always apply)
- Always `git fetch origin` before reading branch data — stale refs give wrong results
- Never run `git log` without a range or limit
- Check for detached HEAD and missing remote before starting

**Default branch:** Commands below write `origin/main` for readability — detect the actual default branch first (Branch Detection in `references/git-safety.md`) and substitute if the repo uses something else.

## Workflow

### Step 1: Show All Branches

```bash
git fetch origin --quiet
git branch -r --sort=-committerdate --format='%(refname:short) %(committerdate:relative) %(authorname)'
```

Run `git fetch origin --quiet` at the start — stale refs make every comparison below wrong.

Filter out `origin/HEAD`. Present as numbered list: `[N] branch — time ago (author)`. Highlight the user's current branch. Hide branches with no activity in the last 90 days unless asked.

Ask: **"Which branch do you want to inspect? (number, name, or 'compare' for overlap analysis)"**

### Step 2: Branch Details

When the user picks a branch, show:

**Commit summary:**
```bash
git log --oneline origin/main..origin/<branch> | head -20
git shortlog -sn origin/main..origin/<branch>
```

Show commit count per author, commit list (`--oneline`), and `--stat` for files changed. Then write a human-readable one-sentence summary of what the branch is doing based on commit messages.

### Step 3: Compare With Your Branch

This is the most valuable part — finding potential conflicts before they happen.

```bash
# Files you both changed since main
comm -12 \
  <(git diff --name-only origin/main..HEAD | sort) \
  <(git diff --name-only origin/main..origin/<branch> | sort)
```

If there are overlapping files, show each with: what your side changed, what their side changed, and a risk rating. For each overlapping file, read both sides' diffs to assess conflict risk:
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

If the user says "compare" or asks about all branches, show a cross-branch overlap matrix: NxN table of branch pairs with overlap count and ⚠️/✓ indicators.

## Next Steps

After the inspection, offer relevant follow-ups based on findings:

- If conflicts predicted: "Run `/conflict-simulator` for detailed severity analysis, or `/smart-sync` to resolve now."
- If the user wants specific files from another branch: "Run `/selective-merge` or `/cherry-pick` to bring changes over."
- If own branch is behind: "Run `/smart-sync` to catch up with main."

## Token Efficiency

- Branch listing: ~1 line per branch
- Commit summary: use `--oneline`, limit to 20
- Overlap detection: `comm` command produces minimal output
- Only read individual file diffs when assessing conflict risk for overlapping files
