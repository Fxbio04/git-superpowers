---
name: safe-push
description: Pre-push audit that scans outgoing commits for issues and fixes them before pushing. Use when the user wants to push changes, make sure their push is clean, check for problems before pushing, or says things like "push my changes", "is it safe to push", "push to origin", "check before push", "pushen", "ab damit", or "hochladen". Also triggers on /safe-push. Catches debug statements, forgotten conflict markers, secrets, incomplete features, and other common mistakes — then offers to fix them directly.
---

# Safe Push

Audit outgoing commits for common mistakes and fix them before pushing. This is not just a linter — it understands your code, catches semantic issues (unused imports from an unfinished feature, missing files that a component depends on), and actively fixes what it finds.

Read `references/git-safety.md` before your first action.

## Workflow

### Step 1: What's Going Out?

```bash
git fetch origin
git log --oneline origin/<branch>..HEAD
```

If nothing to push: "Nothing to push — your branch is up to date with origin." Stop.

Show the outgoing commits and a file summary:
```bash
git diff --stat origin/<branch>..HEAD
```

```
3 commits to push to origin/fb:

a1b2c3d feat(amazon): add analytics dashboard
d4e5f6g fix(auth): login redirect bugfix
e7f8g9h chore(deps): update react-charts

12 files changed, 340 insertions, 45 deletions
```

### Step 1.5: Conflict Prediction

Before auditing code quality, check if your branch will have conflicts when rebasing onto main later. This uses the conflict-simulator approach:

```bash
# Quick overlap check: files changed in both your branch and main
MERGE_BASE=$(git merge-base HEAD origin/main)
comm -12 \
  <(git diff --name-only $MERGE_BASE..HEAD | sort) \
  <(git diff --name-only $MERGE_BASE..origin/main | sort)
```

If overlapping files exist, warn:
```
⚠️ Conflict prediction: 2 files overlap with main
  src/routes.tsx — you and main both modified this
  package.json — different dependency changes

Consider running /smart-sync before pushing to avoid conflicts later.
```

If no overlap: continue silently (don't clutter the output).

For a deeper simulation with severity analysis, suggest: "Run `/conflict-simulator` for a full conflict analysis."

### Step 2: Audit

Run these checks against the outgoing diff (`git diff origin/<branch>..HEAD`):

**Check 1: Debug Artifacts**
Scan for added lines containing:
- `console.log`, `console.debug` (not in test files or logging utilities)
- `debugger` statements
- `print(` that looks like debug output

**Check 2: Conflict Markers**
```bash
git diff origin/<branch>..HEAD | grep -n "^+.*<<<<<<\|^+.*======\|^+.*>>>>>>"
```

**Check 3: Secret Patterns**
Scan added lines for patterns from `references/git-safety.md` secret patterns section.

**Check 4: Incomplete Features**
Read the diff semantically:
- Are there imports for files/modules that don't exist in the push?
- Are there components/functions referenced but not defined?
- Are there TODO/FIXME/HACK comments in new code?

**Check 5: Large Files**
```bash
git diff --stat origin/<branch>..HEAD | grep -E '\d{4,} \+'
```

### Step 3: Report and Fix

If all checks pass:
```
Safe Push Audit ✓

3 commits, 12 files — no issues found.
Push to origin/fb? (y/n)
```

If issues found, show them numbered and offer fixes:

```
Safe Push Audit for fb → origin/fb

3 commits, 12 files

✓ No secrets found
✓ No conflict markers

Issues found:
[1] console.log in src/amazon/dashboard.tsx:45 — "console.log('debug data', data)"
[2] console.log in src/amazon/dashboard.tsx:89 — "console.log('render')"
[3] Missing file: src/amazon/ProductChart.tsx is imported but not in this push
[4] TODO in src/utils/api.ts:12 — "TODO: add error handling for timeout"
```

Then ask with multiSelect: **"Which issues should I fix?"**
- Each numbered issue as an option
- "Fix all"
- "Ignore and push anyway"

### Step 4: Apply Fixes

For each selected fix:

**Debug artifacts**: Read the file, remove the debug line, save. If removing the line would break the code (e.g., it's the only statement in a block), replace with appropriate code or a comment.

**Missing files**: Check if the file exists but wasn't staged. If yes: `git add <file>`. If the file doesn't exist at all, warn: "This file doesn't exist yet — remove the import or create the file?"

**TODOs**: Ask what should happen — implement it, remove the comment, or leave it.

**Secrets**: Show the line (redacted), explain the risk, ask the user to remove it manually or offer to replace with an environment variable reference.

After fixes, create a cleanup commit:
```bash
git add <fixed-files>
git commit -m "$(cat <<'EOF'
chore: cleanup before push

- Remove debug statements
- [other fixes applied]

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Show `git diff --cached --stat` before committing for verification.

### Step 5: Push

```bash
git push origin <branch>
```

If push fails due to remote changes:
```bash
git pull --rebase origin <branch>
```
Then retry the push. If rebase causes conflicts, suggest running smart-sync instead.

Show confirmation: "Pushed 4 commits to origin/fb ✓"

## Rules

- Never push without showing what's going out first
- Always scan for secrets before pushing — this is non-negotiable
- Show each issue with file, line number, and the actual code
- Fix issues directly — don't just warn and leave it to the user
- Create a separate cleanup commit for fixes (never amend existing commits that might already be pushed)
- Use `git push` (not force push) — if force is needed, suggest smart-sync first
