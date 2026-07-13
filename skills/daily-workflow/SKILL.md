---
name: daily-workflow
description: Guided git workflow that chains skills together — sync, commit, review, push, PR in one flow. Triggers: "tagesablauf", "daily workflow", "alles auf einmal", "commit und push", "full workflow", "was muss ich machen", /daily-workflow.
---

# Daily Workflow

A guided, chained workflow that runs the right skills in the right order. Instead of invoking skills one by one, this skill asks what you want to accomplish and walks you through the entire pipeline.

## Safety (always apply)
- Each step uses its own skill's safety rules
- Always confirm before destructive operations
- The user can exit at any point — no step is mandatory

## Workflow

### Step 1: Assess the Situation

Gather the current state in one pass:

```bash
BRANCH=$(git branch --show-current)
git fetch origin --quiet
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@.*/@@'); [ -z "$BASE" ] && BASE=main
BEHIND=$(git rev-list --count HEAD..origin/$BASE 2>/dev/null || echo "?")
AHEAD=$(git rev-list --count origin/$BASE..HEAD 2>/dev/null || echo "?")
UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
UNPUSHED=$(git log --oneline origin/$BRANCH..HEAD 2>/dev/null | wc -l | tr -d ' ')
echo "branch:$BRANCH base:$BASE behind:$BEHIND ahead:$AHEAD uncommitted:$UNCOMMITTED unpushed:$UNPUSHED"
```

Present a status summary:

```
Current state:
  Branch: fb
  Behind main: 12 commits ⚠️
  Ahead of main: 5 commits
  Uncommitted changes: 7 files
  Unpushed commits: 3

Recommended workflow:
```

### Step 2: Suggest a Workflow

Based on the state, suggest the most appropriate flow:

**If behind main + uncommitted changes:**
```
Your branch is behind main AND has uncommitted work.
Recommended order:

[1] Commit first, then sync (safer — your work is saved before rebasing)
    → /smart-commit → /smart-sync → /safe-push

[2] Sync first, then commit (gets latest code, but stashes your work temporarily)
    → /smart-sync → /smart-commit → /safe-push

[3] Full pipeline with review
    → /smart-commit → /diff-review → /smart-sync → /safe-push → /pr-prep

[4] Quick — commit all, sync, push (minimal questions)

Which flow? (1-4, or describe what you need)
```

**If behind main, no uncommitted changes:**
```
Your branch is behind main.

[1] Sync with main → /smart-sync
[2] Sync and push → /smart-sync → /safe-push
[3] Full pipeline → /smart-sync → /safe-push → /pr-prep
```

**If uncommitted changes, not behind:**
```
You have uncommitted work.

[1] Commit → /smart-commit
[2] Commit and push → /smart-commit → /safe-push
[3] Commit, review, push → /smart-commit → /diff-review → /safe-push
[4] Full pipeline → /smart-commit → /diff-review → /safe-push → /pr-prep
[5] Quick — commit all and push (minimal questions)
```

**If unpushed commits, no other work:**
```
You have unpushed commits.

[1] Push → /safe-push
[2] Review first, then push → /diff-review → /safe-push
[3] Push and create PR → /safe-push → /pr-prep
```

**If everything is clean:**
```
Branch is clean and up to date. ✓

[1] Review open PRs waiting on you → /pr-review
[2] Check CI status → /ci-fix
[3] Check other repos → /repo-overview
[4] Inspect other branches → /branch-inspect
[5] Nothing to do
```

### Step 3: Execute the Pipeline

Run each skill in sequence. Between each skill:

1. **Show progress:**
   ```
   Pipeline: ✓ commit → ▶ review → ○ sync → ○ push
   ```

2. **Ask to continue:**
   "Continue to the next step? (y = continue / s = skip this step / x = stop here)"

3. **Handle failures:** If a skill encounters issues (conflicts during sync, audit failures during push), handle them within that skill before continuing. If the user aborts a step, ask: "Skip this step and continue the pipeline, or stop here?"

### Step 4: Quick Mode

When the user selects quick mode or says "schnell", "quick", "just do it":

1. **Commit**: Run smart-commit with strategy "combined" — all changes in one commit, auto-generated message, no review question
2. **Sync** (if behind): Run smart-sync — if conflicts arise, exit quick mode and resolve interactively
3. **Push**: Run safe-push — if audit finds secrets or conflict markers, exit quick mode and show issues. Debug statements and TODOs are auto-fixed without asking.
4. **Summary**: Show what was done

Quick mode still respects all safety rules — secrets block the push, conflicts require attention, destructive operations need confirmation. It only skips optional questions and review steps.

### Step 5: Pipeline Summary

After the pipeline completes (or the user stops), show a summary:

```
Workflow complete:
  ✓ Committed: 2 commits (feat(amazon): dashboard, fix(auth): redirect)
  ✓ Synced: 12 commits from main, 1 conflict resolved
  ✓ Pushed: 5 commits to origin/fb
  ○ Skipped: PR prep

Branch fb is now up to date and pushed.
```

## When NOT to Use This Skill

- If the user asks for a specific operation ("just push"), use that skill directly
- If the user is in the middle of active development and just wants to commit one thing
- This skill is for "I'm done working and want to ship" or "I'm starting my day and need to get organized"

## Rules

- Never skip safety checks even in quick mode
- Always show the pipeline progress so the user knows where they are
- Always allow exiting the pipeline at any point
- Each pipeline step uses the full skill workflow — this skill is an orchestrator, not a replacement
- If a step fails, the pipeline pauses — don't skip ahead silently
