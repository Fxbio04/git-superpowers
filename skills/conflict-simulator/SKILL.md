---
name: conflict-simulator
description: Predict merge or rebase conflicts BEFORE they happen, without modifying your branch or working tree. Use when the user wants to check if a sync will go smoothly, or says things like "will there be conflicts", "check for conflicts", "simulate rebase", "gibt es konflikte", "test ob rebase klappt", "conflict check", "dry run rebase", "wird das klappen", "check before merge", "was passiert wenn ich rebase", or "preview conflicts". Also triggers on /conflict-simulator. Also called proactively by safe-push and smart-sync before risky operations.
---

# Conflict Simulator

Predict merge and rebase conflicts before they happen — without touching your branch. This skill is read-only: it simulates, reports, and leaves everything exactly as it found it.

Read `references/git-safety.md` and `references/conflict-resolution.md` before your first action.

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
- Exit code `1` = conflicts detected. The output includes a tree SHA followed by a "Conflicted file info" section listing the conflicted files.

Parse the "Conflicted file info" section from the output to extract the list of conflicted files. Do NOT try to parse the tree SHA or look for conflict markers in the merge-tree output — always rely on the exit status to determine if conflicts exist.

An empty conflicted file list does NOT necessarily mean a clean merge — always check the exit status first.

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

**No conflicts:**
```
Conflict Simulation: fb → origin/main

No conflicts predicted. ✓

5 files changed on both sides — no overlapping sections.
Safe to run /smart-sync when ready.
```

**Conflicts found:**

For each conflicted file, read the conflict output to understand what each side changed. Use `references/topic-detection.md` to group conflicts by topic.

Assess severity per file:
- **Easy** — same file, entirely different sections (git just needs to be told to take both)
- **Medium** — same section of a file modified on both sides in compatible ways
- **Hard** — fundamental restructuring on one side that invalidates the other side's changes

```
Conflict Simulation: fb → origin/main

Predicted conflicts: 4 files

[Easy]   package.json
         Your side:  added "react-charts": "^2.1.0" in dependencies
         Main's side: added "lodash": "^4.17.21" in dependencies
         → Both added different dependencies — combine them, no semantic conflict

[Medium] src/routes.tsx
         Your side:  added /amazon route at the bottom of the routes array
         Main's side: added /reports route in the same location
         → Both added routes to the same section — both changes are valid, order them

[Hard]   src/utils/api.ts
         Your side:  added 3 new imports and a helper function using the old module structure
         Main's side: restructured the entire module — new export pattern, removed old exports
         → Your additions reference exports that no longer exist in main's version
         → Requires manual adaptation of your changes to the new structure

[Medium] src/config.ts
         Your side:  added AMAZON_REGION config key
         Main's side: moved config to a new Config class with typed keys
         → Your key needs to be added to the new class format

Severity summary:
  1 Hard conflict   — api.ts will need careful manual resolution
  2 Medium conflicts — straightforward to resolve
  1 Easy conflict   — near-automatic

Recommendation: The api.ts conflict will get harder the longer you wait —
main's refactor is actively diverging from your structure. Sync soon.
```

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
