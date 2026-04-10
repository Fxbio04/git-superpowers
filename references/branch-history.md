# Branch History

How to reliably read and present git history without depending on commit IDs.

## Core Principle

Never run `git log` without a range or limit. Unbounded log output wastes tokens and overwhelms the user. Always scope your queries.

## Essential Commands

### What has a branch done since main?
```bash
git log --oneline origin/main..origin/<branch>
```
Shows all commits on `<branch>` that aren't in main. This is the single most useful history command.

### Who committed what?
```bash
git shortlog -sn origin/main..origin/<branch>
```
Shows commit counts per author. Quick way to see who's been active on a branch.

### What files changed?
```bash
git diff --stat origin/main..origin/<branch>
```
Shows changed files with insertions/deletions. No commit details, just the aggregate diff.

### Visual branch overview
```bash
git log --all --oneline --graph --decorate -20
```
Shows the last 20 commits across all branches with a visual graph. Good for understanding how branches relate. Limit to 20-30 lines to keep it readable.

### What's the latest activity across all branches?
```bash
git branch -r --sort=-committerdate --format='%(refname:short) %(committerdate:relative) %(authorname)'
```
Lists remote branches sorted by last commit date. Shows who last committed and when.

### How far apart are two branches?
```bash
git rev-list --count origin/main..origin/<branch>   # branch is ahead by N
git rev-list --count origin/<branch>..origin/main   # branch is behind by N
```

### What changed in a specific commit?
```bash
git show --stat <commit-hash>      # files changed
git show <commit-hash> -- <file>   # specific file in that commit
```
Only use when the user asks about a specific commit. Don't read full commit diffs by default.

## Comparing Branches

To find files modified in both branches (potential conflicts):
```bash
comm -12 \
  <(git diff --name-only origin/main..origin/<branch-a> | sort) \
  <(git diff --name-only origin/main..origin/<branch-b> | sort)
```

This shows files that both branches have modified since diverging from main — these are likely conflict points when one branch merges first.

## Presenting History to the User

When showing branch activity:
1. Start with the summary — "Branch X has 15 commits, 3 authors, touching 23 files"
2. Show the commit list (`--oneline`) for detail
3. Only read individual commit diffs if the user asks

When comparing branches:
1. Show ahead/behind counts first
2. List overlapping files (potential conflicts)
3. Summarize what each branch is working on based on commit messages

## Token Efficiency

| Command | Approximate output | When to use |
|---|---|---|
| `rev-list --count` | 1 line | Always — cheapest overview |
| `branch -r --format` | 1 line per branch | For multi-branch overview |
| `diff --stat` | 1 line per file | To see what changed |
| `log --oneline` | 1 line per commit | For commit details |
| `shortlog -sn` | 1 line per author | To see who's active |
| `log --stat` | ~3-5 lines per commit | Only when user wants detail |
| `show <commit>` | Full diff | Only for specific commit inspection |

Always start from the top of this table and work down as needed.
