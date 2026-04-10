# git-superpowers

Claude Code skills for intelligent Git workflows. Topic-aware commits, smart rebasing, multi-repo overview, pre-push auditing, and branch inspection — all powered by AI.

## The Problem

Teams working in feature branches deal with:
- **Mixed changes** — multiple features and bugfixes in the same branch, sometimes in the same file
- **Merge conflict chaos** — rebasing from main creates conflicts in files with changes from different topics
- **Pushing unfinished work** — half-done features accidentally included in commits
- **No overview** — hard to see where all repos stand and what others are doing
- **Preventable mistakes** — debug statements, forgotten conflict markers, secrets in diffs

## Skills

### `/smart-commit` — Topic-Based Selective Commits
Groups your changes by topic using AI analysis. When one file contains changes from multiple topics (a bugfix AND a feature), it splits them at hunk level so each commit is clean.

### `/smart-sync` — Intelligent Rebase
Rebases your branch onto main with topic-aware conflict resolution. Instead of raw conflict diffs, you see which topic each conflict belongs to and get guided resolution.

### `/repo-overview` — Multi-Repo Dashboard
Scans all your repos and shows a dashboard: which branches are behind main, where you have uncommitted work, last commit dates. Then offers to take action.

### `/safe-push` — Pre-Push Audit with Auto-Fix
Scans outgoing commits for debug statements, conflict markers, secrets, incomplete features, and large files. Shows issues and fixes them directly — not just warnings.

### `/branch-inspect` — Branch Comparison & Conflict Prediction
See what other branches are doing, who committed what, and predict merge conflicts before they happen.

## Installation

```bash
# Clone the repo
git clone https://github.com/Fxbio04/git-superpowers.git ~/.claude/plugins/git-superpowers
```

Then register in Claude Code — add the plugin path to your settings.

## Optional Configuration

No configuration required — works out of the box in any git repo.

For custom topic mappings, create a `.claude-git.yml` in your repo root:

```yaml
# Optional: directories to scan for repo-overview
scan_dirs:
  - ~/source/
  - ~/projects/

# Optional: explicit topic mappings for smart-commit
topics:
  amazon:
    paths: ["src/amazon/", "departments/amazon"]
  shopify:
    paths: ["src/shopify/", "departments/shopifySync"]
```

## Architecture

```
git-superpowers/
├── skills/
│   ├── smart-commit/SKILL.md
│   ├── smart-sync/SKILL.md
│   ├── repo-overview/SKILL.md
│   ├── safe-push/SKILL.md
│   └── branch-inspect/SKILL.md
├── references/
│   ├── topic-detection.md      # AI topic recognition strategy
│   ├── hunk-analysis.md        # Hunk-level splitting guide
│   ├── conflict-resolution.md  # Conflict patterns & strategies
│   ├── git-safety.md           # Shared safety rules
│   └── branch-history.md       # Git history commands reference
└── docs/specs/                 # Design documentation
```

**Pure skills, no dependencies.** Everything runs through Claude's natural abilities — reading diffs, understanding code, executing git commands. No scripts, no MCP servers, no npm packages to install.

**Token-efficient by design.** Skills use `git diff --stat` and `--name-only` for overviews, only reading full diffs when semantic analysis is needed.

## Safety

All skills follow these rules:
- Never `git add .` or `git add -A` — always stage specific files
- Never `--force` push — always `--force-with-lease`
- Always show what will happen before doing it
- Always ask for confirmation before destructive operations
- Scan for secrets before every push
- Fix issues directly instead of just warning

## License

MIT
