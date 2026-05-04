---
name: conflict-simulator
description: Predict rebase/merge conflicts without touching your branch (read-only simulation). Triggers: "gibt es konflikte", "will there be conflicts", "dry run rebase", "wird das klappen", /conflict-simulator.
---

# Conflict Simulator

Predict merge and rebase conflicts before they happen — without touching your branch. This skill is read-only: it simulates, reports, and leaves everything exactly as it found it.

## Safety (always apply)
- This skill MUST NOT modify the working tree, index, or any branch
- Always verify `git status` and `git branch --show-current` match initial state before reporting
- If cleanup fails, stop immediately and report exact state to the user

## Workflow

### Step 1: Preflight

```bash
git status --porcelain
```

Note: this skill works with both clean and dirty working trees. Record the initial state — it must match at the end.

Check you're on a real branch, not detached HEAD:

```bash
git branch --show-current
```

### Step 2: Fetch Latest

Always fetch before simulating — stale remote refs give wrong results:

```bash
git fetch origin
```

### Step 3: Determine What to Simulate

Default target: rebase current branch onto `origin/main` (or `origin/master`).

Detect the main branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```
Fallback order: `origin/main` → `origin/master` → ask the user.

If the user specifies two branches explicitly ("simulate merging feature-x into develop"), use those instead.

Show the simulation target:
```
Simulating: rebase fb → origin/main

Your branch is 8 commits ahead of main.
Main is 5 commits ahead of your branch.
Overlap analysis:
```

### Step 4: Find Overlapping Files

Before running any simulation, do a lightweight check for file overlap. This avoids false alarms and is fast:

```bash
MERGE_BASE=$(git merge-base HEAD origin/main)
git diff --name-only $MERGE_BASE..HEAD > /tmp/branch-files.txt
git diff --name-only $MERGE_BASE..origin/main > /tmp/main-files.txt
comm -12 <(sort /tmp/branch-files.txt) <(sort /tmp/main-files.txt)
```

If no overlapping files:
```
Conflict Simulation: fb → origin/main

No overlapping files detected. Clean rebase predicted.

Your branch and main changed entirely different files.
No conflicts expected. ✓
```
Stop here — no need for the full simulation.

### Step 5: Run the Simulation

Use modern `git merge-tree` (git 2.38+) to simulate the merge without touching any branch:

```bash
# Modern merge-tree — exit code 0 = clean, exit code 1 = conflicts
git merge-tree --write-tree HEAD origin/main 2>&1; echo "EXIT:$?"
```

**Important: Check the EXIT STATUS, not the output content.**
- Exit code `0` = clean merge, no conflicts. The output is a tree SHA.
- Exit code `1` = conflicts detected. The output includes CONFLICT lines.

Extract conflicted files with a concrete grep — never try to parse the tree SHA or infer from output structure:

```bash
MERGE_OUTPUT=$(git merge-tree --write-tree HEAD origin/main 2>&1)
MERGE_EXIT=$?
if [ "$MERGE_EXIT" -ne 0 ]; then
  # Extract conflicted file paths from CONFLICT lines
  echo "$MERGE_OUTPUT" | grep '^CONFLICT' | sed 's/.*Merge conflict in //' | sed 's/CONFLICT .*//'
fi
```

Always rely on the exit status to determine if conflicts exist — an empty grep result with exit code 1 still means conflicts.

**For older git versions** (before 2.38) that do not support `--write-tree`, fall back to the detached HEAD approach:

```bash
# Record current state
CURRENT_BRANCH=$(git branch --show-current)
STASH_MSG="conflict-sim-$(date +%s)"

# Stash if there are uncommitted changes
git stash push -m "$STASH_MSG" 2>/dev/null

# Detach HEAD so we don't modify any branch
git checkout --detach HEAD

# Attempt merge without committing
git merge --no-commit --no-ff origin/main 2>&1

# Capture conflicted files
CONFLICTED=$(git diff --name-only --diff-filter=U)

# Clean up — abort merge and return
git merge --abort 2>/dev/null || true
git checkout "$CURRENT_BRANCH"

# Restore stash if we created one
git stash list | grep -q "$STASH_MSG" && git stash pop 2>/dev/null || true
```

### Step 6: Verify State Was Preserved

Before reporting results, confirm nothing changed:

```bash
git status --porcelain
git branch --show-current
```

These must match the values recorded in Step 1. If they don't, stop and report the discrepancy to the user before doing anything else.

### Step 7: Report Results

**No conflicts:** Report clean simulation, suggest `/smart-sync` when ready.

**Conflicts found:**

For each conflicted file, read the conflict output to understand what each side changed. Group by topic if possible.

Assess severity per file:
- **Easy** — different sections of same file, near-automatic merge
- **Medium** — same section modified in compatible ways, needs ordering
- **Hard** — structural changes that invalidate the other side's approach

For each conflict show: severity tag, file path, what your side changed, what main changed, one-line recommendation. End with a severity summary and a timing recommendation (e.g., "The hard conflict will get worse over time — sync soon").

### Step 8: Offer Next Steps

```
Options:
[1] Run /smart-sync now to resolve these conflicts interactively
[2] Show me the full diff for a specific conflicted file
[3] Explain what main changed in api.ts (show their commits)
[4] Nothing — I just wanted to know
```

If the user chooses option 3:
```bash
git log --oneline $(git merge-base HEAD origin/main)..origin/main -- <file>
git show <commit> -- <file>
```

## Rules

- This skill MUST NOT modify the working tree, index, or any branch
- Always verify `git status` and `git branch --show-current` match the initial state before reporting results
- If cleanup after the fallback approach fails (e.g., merge abort fails), stop immediately and report the exact state to the user so they can recover manually
- Never run `git rebase` as a simulation — it modifies branch history and cannot be reliably undone in all failure cases
- Severity ratings are estimates — flag as Hard when uncertain, not Easy
- Proactive use: safe-push and smart-sync should invoke this skill when overlapping files are detected between the outgoing branch and the target base

## Multi-Branch Simulation

When checking conflicts against multiple branches (e.g., "will fb conflict with bb AND main?"), run simulations in parallel:

```bash
# Check conflicts against multiple targets simultaneously
for target in origin/main origin/<other-branch>; do
  echo "=== vs $target ==="
  git merge-tree --write-tree HEAD $target 2>&1
  echo "EXIT:$?"
done
```
