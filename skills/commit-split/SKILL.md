---
name: commit-split
description: Split an existing commit into multiple smaller, focused commits — one topic per commit. Use when the user's last commit contains mixed concerns, when a commit is too large, or when they say things like "split this commit", "commit ist zu groß", "too many things in one commit", "aufteilen", "split last commit", "commit has mixed changes", "zu viel in einem commit", or "separate the changes". Also triggers on /commit-split. Rewrites only the last commit (or last N commits) safely.
---

# Commit Split

Split an oversized or mixed-concern commit into multiple focused commits. One commit, one topic — so history stays readable and reviewable. This only works safely on the most recent commit(s); see the constraint section below for commits further back.

Read `references/git-safety.md` before your first action — especially the section on history rewriting.

## Workflow

### Step 1: Identify the Commit to Split

Default: split `HEAD` (the last commit).

Show what is in it:

```bash
git show --stat HEAD
```

Also show whether this commit has already been pushed:

```bash
git fetch origin 2>/dev/null
git log --oneline origin/<branch>..HEAD 2>/dev/null
```

If `git log` returns nothing (the commit is not ahead of origin), the commit is already pushed. Warn the user now — don't wait until the end:

```
⚠ This commit is already on origin/<branch>. Splitting it will rewrite
history. You will need to force-push afterward, which affects anyone
else working on this branch.

Continue anyway?
```

If the user specifies a commit other than HEAD (e.g., "split the third-to-last commit"), see the constraint section at the bottom — explain why this skill can't handle it and stop.

### Step 2: Read the Changes and Detect Topics

Read the full diff of the commit:

```bash
git show HEAD
```

Apply topic detection from `references/topic-detection.md`:

1. **Path-based**: files in `src/amazon/` → Amazon topic; files in `src/auth/` → Auth topic
2. **Config-based**: check for `.claude-git.yml` topic mappings
3. **Semantic**: for shared/ambiguous files, read the diff content — imports, function names, variable names, comments reveal the topic

For each file in the commit, assign it to a topic. Mark files that contain changes from multiple topics with ⚡.

Produce a split plan:

```
Commit: feat(amazon): add dashboard and fix auth redirect

This commit contains 3 topics:

[1] Amazon Dashboard (4 files)
    A  src/amazon/dashboard.tsx
    A  src/amazon/charts.tsx
    M  src/routes.tsx (routes for /amazon)
    M  src/utils/url.ts ⚡ (shared — contains changes for both topic 1 and 2)

[2] Auth Bugfix (2 files)
    M  src/auth/login.tsx
    M  src/utils/url.ts ⚡ (shared — see above)

[3] Dependency Updates (1 file)
    M  package.json

⚡ = file contains changes from multiple topics — will be split at hunk level
```

### Step 3: Confirm the Split Plan

Ask: **"Split into these 3 commits? You can rename topics or merge groups."**

Wait for confirmation before touching anything. This is a history-rewriting operation.

If the user wants to adjust groupings, update the plan and show it again before proceeding.

### Step 4: Propose Commit Messages

For each topic group, propose a commit message using Conventional Commits:

```
Proposed commit messages:

[1] feat(amazon): add analytics dashboard with KPI grid and charts
[2] fix(auth): redirect to intended URL after login
[3] chore(deps): update react-charts to 2.1.0

OK, or adjust any messages?
```

### Step 5: Soft Reset

With confirmation, unstage the commit but keep all changes in the working tree:

```bash
git reset --soft HEAD~1
```

Verify the state — everything should now be staged (all changes from the original commit are in the index):

```bash
git status
```

Tell the user: "The commit has been undone. All changes are staged and ready to be re-committed in groups."

### Step 6: Commit Each Topic Group

For each topic group in order:

**1. Unstage everything:**
```bash
git reset HEAD
```

All changes are now unstaged in the working tree.

**2. Stage only this topic's files:**

For single-topic files:
```bash
git add <file>
```

For ⚡ mixed files, use the hunk-level approach from `references/hunk-analysis.md`:
1. Read the file's full current content
2. Temporarily revert the lines that belong to OTHER topics (restore them to the committed state before this split)
3. `git add <file>`
4. Restore the file to its full content

**3. Verify staging:**
```bash
git diff --cached --stat
```

Show this to the user and confirm it contains only the expected changes for this topic.

**4. Commit:**
```bash
git commit -m "$(cat <<'EOF'
<proposed message for this topic>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Repeat for each topic group.

### Step 7: Verify the Result

```bash
git log --oneline -6
```

Show the new commits. Confirm the original single commit is now gone and replaced by N focused commits.

```
Split complete. Original commit replaced by 3 commits:

a1b2c3d feat(amazon): add analytics dashboard with KPI grid and charts
d4e5f6g fix(auth): redirect to intended URL after login
e7f8g9h chore(deps): update react-charts to 2.1.0
```

### Step 8: Force Push (If Already Pushed)

If the original commit was already on the remote, explain what is needed:

```
The original commit was already on origin/<branch>. The history has been
rewritten locally. To update the remote:

  git push --force-with-lease origin <branch>

This will affect anyone else who has pulled this branch. Coordinate
with your team before force-pushing to a shared branch.

Push now?
```

If confirmed: `git push --force-with-lease origin <branch>`

## Constraints

**Only the last commit (or last N sequential commits) can be split safely.**

For a commit that is not at the tip of the branch, splitting requires an interactive rebase (`git rebase -i`), which needs terminal input that Claude cannot provide.

If the user asks to split a commit further back in history:

```
Splitting commits that are not at the tip of the branch requires
interactive rebase (git rebase -i), which needs interactive terminal
input. Claude cannot do this automatically.

To split <commit> manually:
  git rebase -i <commit>^
  → mark the commit as 'edit'
  → git reset HEAD^ to unstage
  → stage and commit in parts
  → git rebase --continue

I can guide you through each step if you run the rebase yourself.
```

## Rules

- Always confirm the split plan before running `git reset --soft`
- Always warn before any force push — show the exact command and explain the implications
- Show `git diff --cached --stat` after staging each group, before committing
- If a mixed file fails to split cleanly at hunk level, stop and ask the user to resolve it manually rather than creating a wrong commit
- Never skip the verification step — `git log --oneline -6` must confirm the expected result
