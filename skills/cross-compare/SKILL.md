---
name: cross-compare
description: Compare how a specific module, service, or file looks across multiple branches side-by-side. Use when the user wants to see how a particular area of code differs between branches, or says things like "how does amazon look in fb vs bb vs main", "compare routes.tsx across branches", "vergleich die branches", "wie sieht der code in den anderen branches aus", "show me that component in all branches", "was hat sich geändert in den anderen branches", or "which branch has the latest version of X". Also triggers on /cross-compare.
---

# Cross-Compare

Compare a specific file, module, or directory across all branches that have touched it. Instead of switching branches manually, this skill builds a side-by-side picture of how different branches diverge on the same code — and flags which branches would collide if merged.

Read `references/git-safety.md` before your first action.

## Workflow

### Step 1: Identify the Target

If the user named a path or module, use it directly. If vague (e.g., "how does amazon look"), resolve it:

```bash
git diff --name-only origin/main | grep -i <term>
```

Check common patterns: `src/<module>/`, `src/components/<Name>`, `src/pages/<route>`. Confirm with the user if multiple paths match:

```
Found these paths matching "amazon":
[1] src/amazon/
[2] src/components/AmazonWidget.tsx

Which one? (number or type the full path)
```

### Step 2: Discover Relevant Branches

Fetch all remote refs first — stale local refs give wrong results:

```bash
git fetch origin --quiet
git branch -r --sort=-committerdate --format='%(refname:short)'
```

For each remote branch (excluding `origin/HEAD`), check whether it has any changes to the target path compared to the common merge-base:

```bash
git diff --name-only origin/main...origin/<branch> -- <path>
```

If the output is non-empty, the branch has touched that path. Collect the relevant branches.

If no branch has changes to the path: "No branches have modified `<path>` — they all look the same as main." Stop.

### Step 3: Per-Branch Summary

For each relevant branch, show a compact summary. Token-efficient: use `--stat` and commit messages first, not full diffs.

```bash
# Change size
git diff --stat origin/main...origin/<branch> -- <path>

# Commits that touched this path on that branch
git log --oneline origin/main..origin/<branch> -- <path>
```

Format the output as a comparison table:

```
Comparison for src/amazon/ across branches:

┌─────────────────────────────────────────────────────────────────┐
│ Branch    │ Commits │ +Lines │ -Lines │ Summary                  │
├─────────────────────────────────────────────────────────────────┤
│ origin/fb │ 4       │ +312   │ -18    │ new dashboard, 3 charts  │
│ origin/bb │ 2       │ +45    │ -120   │ refactored API calls      │
│ origin/it │ 0       │ —      │ —      │ unchanged from main       │
│ main      │ baseline│        │        │ original                  │
└─────────────────────────────────────────────────────────────────┘
```

For each branch with changes, write a one-sentence human summary based on commit messages and file names. Examples:
- "fb: added analytics dashboard with KPI grid and 3 chart components"
- "bb: replaced inline fetch calls with a centralized API client"

### Step 4: Conflict Prediction

Find branches that both modified the target path and check how their changes overlap:

```bash
# Lines changed in branch A vs branch B (not vs main)
comm -12 \
  <(git diff --unified=0 origin/main...origin/<branch-A> -- <path> | grep '^@@' | grep -oE '\+[0-9]+' | tr -d '+' | sort) \
  <(git diff --unified=0 origin/main...origin/<branch-B> -- <path> | grep '^@@' | grep -oE '\+[0-9]+' | tr -d '+' | sort)
```

Report collision risk for each pair:

```
Merge Collision Forecast:

fb ↔ bb: HIGH RISK
  Both modified src/amazon/api.ts — fb added new functions, bb restructured existing ones.
  Merging bb to main first would force fb to resolve conflicts in that file.

fb ↔ it: NO CONFLICT
  it has no changes to src/amazon/ — safe to merge in any order.
```

Risk levels:
- **HIGH**: Both branches modified the same file in overlapping line ranges
- **MEDIUM**: Both modified the same file but in different sections
- **LOW**: Only one branch modified the file, or changes are in separate files within the path

### Step 5: Optional — Show Full Diff

If the user wants details on a specific branch:

```
See full diff for a branch? (fb / bb / no)
```

If yes:
```bash
git diff origin/main...origin/<branch> -- <path>
```

Show the diff with context. Read `references/hunk-analysis.md` if the diff needs to be annotated by topic.

### Step 6: Recommendations

Based on the analysis, offer clear next steps:

- **If merges would conflict**: "Consider syncing fb from main before bb merges — this keeps your conflicts predictable."
- **If one branch is strictly ahead**: "fb has the most complete version. If main needs this, fb is the candidate to merge."
- **If branches have complementary changes**: "fb and bb changed different parts — both could be merged cleanly if done in order."

Offer to run `cherry-pick` or `branch-inspect` for deeper follow-up.

## Token Efficiency

- Always use `--stat` first; read full diffs only on explicit request
- Use `git log --oneline` for commit summaries (1 line per commit)
- The `comm` overlap check is text-based — no large diff reads needed for collision detection
- If more than 5 branches are relevant, ask the user to narrow down before running full analysis
