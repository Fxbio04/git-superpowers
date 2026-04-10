---
name: repo-overview
description: Multi-repo dashboard showing the status of all your git repositories at a glance. Use when the user wants to see the state of their repos, check which branches are behind, get an overview of all projects, find uncommitted work across repos, or says things like "show me all repos", "welche repos sind behind", "repo status", "wo steh ich überall", "overview of my projects", or "was hab ich noch offen". Also triggers on /repo-overview.
---

# Repo Overview

Scan all your git repositories and show a dashboard with branch status, ahead/behind counts, and uncommitted changes. Then offer to take action on any repo.

Read `references/git-safety.md` before your first action.

## Workflow

### Step 1: Find Repositories

Determine which directories to scan:

1. If `.claude-git.yml` exists in the current directory or home directory with `scan_dirs`, use those
2. Otherwise, scan common locations:
   ```bash
   # Find git repos in likely locations (max 2 levels deep)
   find ~/source -maxdepth 2 -name ".git" -type d 2>/dev/null | sed 's/\/.git$//'
   ```
3. If nothing found in `~/source`, try the current directory's parent

Keep the list manageable — if more than 20 repos are found, show only those with recent activity (committed within last 30 days).

### Step 2: Gather Status

For each repo, run these commands using `git -C <repo-path>`:

```bash
git -C <path> branch --show-current
git -C <path> fetch origin --quiet 2>/dev/null
git -C <path> rev-list --count HEAD..origin/main 2>/dev/null || echo "?"
git -C <path> rev-list --count origin/main..HEAD 2>/dev/null || echo "?"
git -C <path> status --porcelain | wc -l
git -C <path> log --oneline -1 --format='%cr'
```

Handle repos without a remote or without `origin/main` — fall back to `origin/master` or show "no remote".

### Step 3: Display Dashboard

```
Repo Overview (6 repos)

Repo                  Branch  Behind  Ahead  Changes  Last Commit
──────────────────────────────────────────────────────────────────
connector             fb        12 ⚠️     3    7 files  2 hours ago
ews-connector         fb         0 ✓      1    0 files  1 day ago
brognoMicroServices   fb         4 ⚠️     0    2 files  3 hours ago
shopify-connector     fb         0 ✓      5    0 files  5 hours ago
brognoMCP             main       0 ✓      0    0 files  2 days ago

⚠️ 2 repos are behind main — consider syncing
```

Sort by: repos with issues first (behind, uncommitted changes), then clean repos.

### Step 4: Offer Actions

Ask: **"Want to do something? Pick a repo number, or:"**
- **"sync <repo>"** → run smart-sync for that repo
- **"details <repo>"** → show last 5 commits, list uncommitted files, diff --stat
- **"commit <repo>"** → run smart-commit for that repo
- **"done"** → exit

When the user selects an action, `cd` into that repo and invoke the appropriate workflow.

### Step 5: Return to Dashboard

After completing an action, show the updated dashboard to reflect changes (re-scan the affected repo).

## Token Efficiency

The entire dashboard scan uses ~2 lines of output per repo. For 10 repos, that's ~20 lines total. No diffs are read unless the user asks for details.

## Edge Cases

- **Repo without remote**: Show "no remote" in Behind/Ahead columns
- **Repo on main/master**: Skip behind/ahead (it IS main)
- **Detached HEAD**: Show the commit hash instead of branch name
- **Fetch fails**: Show last known state, note "(offline)" next to the repo
- **Non-standard main branch**: Use `git symbolic-ref refs/remotes/origin/HEAD` to detect
