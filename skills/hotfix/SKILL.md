---
name: hotfix
description: Emergency fix workflow — stash current work, branch from main, apply the fix, push, and create a PR marked as HOTFIX. Use when production is broken and speed matters, or the user says things like "production is broken", "hotfix needed", "notfall", "production bug", "schnell fixen und deployen", "emergency fix", "dringend", "kritischer bug", "prod ist down", or "sofort fixen". Also triggers on /hotfix.
---

# Hotfix

Apply an emergency fix to production without contaminating your in-progress work. This workflow is optimized for speed — it minimizes questions and moves in a straight line from broken to fixed.

Read `references/git-safety.md` before your first action. Even under time pressure, the secret scan and conflict markers check are non-negotiable.

## Workflow

### Step 1: Save Your Current Work

First, record the current branch name — you need it in Step 8 to return.

```bash
PREVIOUS_BRANCH=$(git branch --show-current)
```

Then, protect whatever you're in the middle of so nothing gets lost.

```bash
git status --porcelain
```

If there are uncommitted changes:
```bash
git stash push -m "hotfix auto-stash $(date +%Y-%m-%d-%H%M)"
```

Confirm: "Stashed your current work. It'll be waiting when you return."

If the working tree is clean: "Nothing to stash — workspace is clean."

### Step 2: Create Hotfix Branch from Main

Fetch first to ensure the hotfix starts from the latest production state:

```bash
git fetch origin
```

Ask for a short description of the issue (used in the branch name):
```
What's broken? (brief, e.g. "login-crash" or "checkout-404")
```

Sanitize the input — lowercase, spaces to hyphens, remove special characters.

```bash
git checkout -b hotfix/<description> origin/main
```

Confirm:
```
Hotfix branch created: hotfix/<description>
Starting from: origin/main (latest)
```

### Step 3: Apply the Fix

Tell the user: "Make your fix now. I'll wait."

Then assist with the fix if asked. When the user signals they're done (or commits manually), continue.

If Claude is helping write the fix:
- Read the relevant files first
- Make targeted, minimal changes — hotfixes should be surgical, not sweeping
- Avoid refactoring alongside the fix; that belongs in a normal branch

### Step 4: Audit the Fix

Even under time pressure, do a focused audit on the outgoing diff. A bad hotfix to production is worse than a slightly delayed one.

Run against `git diff origin/main..HEAD`:

**Conflict markers** (would cause syntax errors in production):
```bash
git diff origin/main..HEAD | grep -n "^+.*<<<<<<\|^+.*======\|^+.*>>>>>>"
```

**Secret patterns** — scan for patterns from `references/git-safety.md`. Block if found.

**Debug artifacts**:
- `console.log`, `debugger` in the fix

**Scope check**: Is this change minimal? If the diff is large (>10 files or >200 lines), flag it:
```
This diff is large for a hotfix (12 files, +245 lines).
Hotfixes should be targeted — large changes introduce new risk.
Are you sure this is all necessary for the emergency fix? (y/n)
```

If any issues are found, offer to fix them inline before committing.

### Step 5: Commit the Fix

Use a `fix:` prefix — this is required for semantic versioning pipelines to recognize hotfixes.

Propose a commit message from the branch name and diff:
```bash
git diff --stat origin/main..HEAD
```

```
Proposed commit message:

fix(<scope>): <description of what was fixed>

OK, or change it?
```

Commit with HEREDOC format:
```bash
git add <specific-files>
git commit -m "$(cat <<'EOF'
fix(<scope>): <description>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Never use `git add .` — stage specific files only (safety rule).

### Step 6: Push the Hotfix Branch

```bash
git push origin hotfix/<description>
```

If push fails due to remote changes:
```bash
git pull --rebase origin hotfix/<description>
```

Then retry the push. Hotfix branches are new so this should never happen, but handle it anyway.

### Step 7: Create the PR

Create a PR to main with a HOTFIX label so it's visible in the review queue.

First, check if `gh` CLI is available:
```bash
command -v gh >/dev/null 2>&1
```

If not available: push the branch and create the PR manually at the GitHub web interface. Skip to Step 8.

If available:
```bash
gh pr create \
  --title "fix: <description>" \
  --body "$(cat <<'EOF'
## HOTFIX

**Problem:** <what was broken in production>

**Fix:** <what was changed and why it resolves the issue>

## Changes
<diff summary>

## Test Plan
- [ ] Verify the fix resolves the reported issue
- [ ] Confirm no regressions in adjacent functionality
- [ ] Check production logs after deploy

🚨 This is a hotfix — please review and merge promptly.
EOF
)" \
  --base main \
  --label "hotfix"
```

If the `hotfix` label doesn't exist yet (`gh` returns an error), create the PR without it and note: "Label 'hotfix' not found — add it manually on GitHub if needed."

Show the PR URL:
```
Hotfix PR created: https://github.com/<org>/<repo>/pull/<number>
Share this with reviewers now.
```

### Step 8: Return to Your Previous Work

Ask: **"Switch back to your previous branch?"**

Default is yes — suggest the branch the user was on before.

```bash
git checkout <previous-branch>
```

If a stash was created in Step 1:
```bash
git stash pop
```

Confirm:
```
Back on <previous-branch>. Your stashed work has been restored.
```

If `git stash pop` conflicts (rare but possible — stash was made before a file the hotfix touched):
```
Stash conflict in <file>. Your stashed changes and the hotfix both touched this file.
Let me help you resolve it.
```

Run the conflict resolution from `references/conflict-resolution.md`.

### Step 9: Remind About Post-Merge Sync

After the hotfix PR is merged, the main branch will have changed. Remind the user:

```
After the hotfix is merged to main, sync your branch:
  Run smart-sync on <previous-branch> to get the fix into your work.

This prevents conflicts later and ensures your branch builds on the fixed production code.
```

## Rules

- Always stash before branching — never risk losing in-progress work
- Always start the hotfix branch from `origin/main` (freshly fetched), never from a feature branch
- The secret scan is mandatory even under time pressure — a leaked key in a hotfix is a catastrophe
- Commit message must use `fix:` prefix — hotfixes go through the same semantic versioning as everything else
- Always return the user to their original branch at the end — leave the workspace as found
- Always remind about post-merge sync — the hotfix changes main, and all branches need to know
