---
name: smart-commit
description: Intelligently group and selectively commit changes by topic with hunk-level precision. Use when the user wants to commit changes, push specific features, selectively stage files, commit only part of their work, separate mixed changes into logical commits, or asks things like "commit the bugfix but not the feature work", "push only amazon changes", "was soll ich committen", "commit nach themen", or "nur die fixes committen". Also triggers on /smart-commit.
---

# Smart Commit

Commit changes grouped by topic — not by file. When a single file contains changes from multiple topics (a bugfix AND a feature), this skill splits them at hunk level so each commit is clean and focused.

Read `references/git-safety.md` before your first action — it contains proactive checks that apply to every step below.

## Workflow

### Step 1: Preflight

```bash
git status
```

Check you're in a git repo. Show the current branch. If there are no changes, say so and stop.

### Step 2: Quick Scan

Gather an overview without reading full diffs — this keeps token usage low:

```bash
git diff --name-only                           # unstaged modified files
git diff --cached --name-only                  # already staged files
git ls-files --others --exclude-standard       # untracked files
git diff --stat                                # line-change summary
```

If there are already staged files, ask the user: "Some files are already staged. Should I include them in the topic grouping or leave them as-is?"

### Step 3: Topic Detection

Read `references/topic-detection.md` for the full strategy.

Group all changed files by topic using progressive detail:
1. **Path-based grouping** — files in the same directory likely belong together
2. **Config-based** — if `.claude-git.yml` exists, use its topic mappings
3. **Semantic analysis** — for shared/ambiguous files only, read their diff with `git diff <file>` and determine the topic from code content (imports, function names, comments)

For each file, determine if it contains changes from multiple topics. If yes, mark it with ⚡.

### Step 4: Present Topics

Show the grouped overview:

```
Topics detected:

[1] Login Bugfix (3 files)
    M  src/auth/login.tsx
    M  src/auth/redirect.ts
    M  src/utils/url.ts

[2] Amazon Analytics (5 files)
    A  src/amazon/dashboard.tsx
    A  src/amazon/charts.tsx
    M  src/utils/url.ts ⚡ (shared with Topic 1)

[3] Dependency Updates (1 file)
    M  package.json

⚡ = file contains changes from multiple topics (will be split at hunk level)
```

Ask: **"Which topics do you want to commit? (e.g. '1,3' or 'all')"**

### Step 5: Stage Selected Topics

For **single-topic files**: simply `git add <file>`

For **⚡ mixed files**: use hunk-level splitting. Read `references/hunk-analysis.md` for the detailed approach:
1. Back up the file
2. Edit the file to remove changes belonging to OTHER topics (revert those lines to their original state)
3. `git add <file>`
4. Restore the full file from backup

### Step 6: Verify Staging

```bash
git diff --cached --stat
```

Show this to the user. Ask: "This is what will be committed. Look correct?"

If the user spots something wrong, `git reset HEAD <file>` for the problematic file and redo.

### Step 7: Commit Message

Propose a commit message using Conventional Commits:

**Prefix** based on change type:
- `feat:` — new functionality
- `fix:` — bugfix
- `refactor:` — restructuring without behavior change
- `chore:` — maintenance, dependencies
- `style:` — formatting only
- `docs:` — documentation

**Scope** from the topic: `feat(auth):`, `fix(amazon):`, `chore(deps):`

Show the proposed message and ask for confirmation:
```
Proposed commit message:

feat(amazon): add analytics dashboard with KPI grid and charts

- DashboardView with KPI cards and trend visualization
- ProductAnalysisView with cluster filtering
- ReturnsAnalysisView for returns analysis

OK, or would you like to change it?
```

### Step 8: Commit

Use HEREDOC format:
```bash
git commit -m "$(cat <<'EOF'
feat(amazon): add analytics dashboard with KPI grid and charts

- DashboardView with KPI cards and trend visualization
- ProductAnalysisView with cluster filtering

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### Step 9: Push (Optional)

Ask: "Push to origin/<branch>?"

If yes, check for remote changes first:
```bash
git fetch origin
git log --oneline HEAD..origin/<branch>
```

If remote has new commits, warn and suggest `git pull --rebase origin <branch>` first.

Then push: `git push origin <branch>`

### Step 10: Loop

```bash
git status
```

If more changes remain, show them grouped by topic again and ask: "More topics to commit?"

## Rules

- Never use `git add .` or `git add -A` — always stage specific files or hunks
- Always show `git diff --cached --stat` after staging for verification
- Always show the commit message for user approval before committing
- On pre-commit hook failure: fix the issue and create a NEW commit (never `--amend`)
- Always append `Co-Authored-By: Claude <noreply@anthropic.com>`
