---
name: repo-overview
description: Multi-repo dashboard showing the status of all your git repositories at a glance. Use when the user wants to see the state of their repos, check which branches are behind, get an overview of all projects, find uncommitted work across repos, or says things like "show me all repos", "welche repos sind behind", "repo status", "wo steh ich überall", "overview of my projects", or "was hab ich noch offen". Also triggers on /repo-overview.
---

# Repo Overview

Scan all your git repositories and show a dashboard with branch status, ahead/behind counts, and uncommitted changes. Then offer to take action on any repo.

Read `references/git-safety.md` before your first action.

## Workflow

### Step 1: Find Repositories

Scan for git repos in a single command across all common locations:

```bash
find ~/source ~/projects ~/code ~/dev ~/repos ~/work ~ -maxdepth 3 -name ".git" -type d 2>/dev/null | sed 's/\/.git$//' | sort -u
```

This checks all typical developer directories in one pass. Most paths won't exist and are silently ignored via `2>/dev/null`.

If `.claude-git.yml` exists in the current or home directory with `scan_dirs`, scan those paths instead.

If nothing is found, fall back to the current directory's parent.

Keep the list manageable — if more than 20 repos are found, show only those with recent activity (committed within last 30 days).

### Step 2: Gather Status

IMPORTANT: Gather ALL repo data in ONE single Bash call. Do NOT run separate Bash calls per repo — that wastes time and tokens. Use this pattern:

```bash
# Fetch all repos in parallel first
for path in /path/to/repo1 /path/to/repo2 /path/to/repo3; do
  git -C "$path" fetch origin --quiet 2>/dev/null &
done
wait

# Then collect all status in one loop
for path in /path/to/repo1 /path/to/repo2 /path/to/repo3; do
  name=$(basename "$path")
  branch=$(git -C "$path" branch --show-current 2>/dev/null || echo "detached")
  behind=$(git -C "$path" rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
  ahead=$(git -C "$path" rev-list --count origin/main..HEAD 2>/dev/null || echo "?")
  changes=$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  last=$(git -C "$path" log --oneline -1 --format='%cr' 2>/dev/null || echo "no commits")
  remote_url=$(git -C "$path" remote get-url origin 2>/dev/null || echo "no remote")
  echo "$name|$branch|$behind|$ahead|$changes|$last|$remote_url"
done
```

This runs everything in ONE Bash call and outputs a parseable table. The parallel fetch at the top ensures all repos are up to date before reading status.

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

### Step 6: Remote Repos (nicht geklont)

After showing local repos, check if `gh` CLI is available and authenticated:

```bash
gh auth status 2>/dev/null
```

If available, list repos from the user's GitHub organizations that aren't cloned locally:

```bash
# List all repos from user's orgs
gh repo list --limit 50 --json name,owner,updatedAt,defaultBranchRef --jq '.[] | "\(.owner.login)/\(.name) \(.updatedAt)"'
```

Compare with local repos (by name matching). Show repos that exist on GitHub but not locally:

```
Remote Repos (nicht lokal geklont):

  Org/Repo                    Letztes Update
  ──────────────────────────────────────────
  myorg/new-service           vor 2 Tagen
  myorg/internal-tools        vor 1 Woche
  myorg/legacy-api            vor 3 Monaten

  3 Repos in deinen Organisationen sind nicht lokal geklont.
  Klonen? (Nummer oder "skip")
```

If the user selects a repo to clone, ask where to put it (default: `~/source/`) and run `git clone`.

Only show this section if there are actually uncloned repos. Skip silently if `gh` is not available or not authenticated — this is an optional bonus feature.

### Repos von anderen Orgs (via Remote-URL erkannt)

Some local repos may point to organizations the user isn't a member of (e.g., external collaborator). Detect these by checking remote URLs:

```bash
for path in $REPOS; do
  remote_url=$(git -C "$path" remote get-url origin 2>/dev/null)
  # Extract org from URL
done
```

Present these separately from confirmed org memberships:

```
Repos von anderen Orgs (via Remote-URL):

  CPO-Concept-GmbH (kein Org-Mitglied, aber lokale Repos vorhanden):
    connector, EWS
```

Never label these as "Collaborator" or assume the user's role — just state the fact that local repos point to this org.

## Token Efficiency

The entire dashboard scan uses ~2 lines of output per repo. For 10 repos, that's ~20 lines total. No diffs are read unless the user asks for details.

## Edge Cases

- **Repo without remote**: Show "no remote" in Behind/Ahead columns
- **Repo on main/master**: Skip behind/ahead (it IS main)
- **Detached HEAD**: Show the commit hash instead of branch name
- **Fetch fails**: Show last known state, note "(offline)" next to the repo
- **Non-standard main branch**: Use `git symbolic-ref refs/remotes/origin/HEAD` to detect
