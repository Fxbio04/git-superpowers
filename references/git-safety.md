# Git Safety Rules

Shared safety rules that apply to all git-superpowers skills. Read this reference on first invocation of any skill in this package.

## Proactive Detection

Always check for these issues and act immediately when found:

| Situation | Response |
|---|---|
| File contains `<<<<<<<` conflict markers | Stop. Show the file and line. Offer to resolve. |
| Diff contains `console.log` or `debugger` | Warn. Show location. Offer to remove. |
| Diff contains patterns resembling secrets (API keys, tokens, passwords, connection strings) | Block the push. Show the pattern (redacted). Explain the risk. |
| Push includes incomplete features (component used but not defined, import without file) | Warn. Show what's missing. Ask if intentional. |
| Branch is >20 commits behind main | Suggest syncing before continuing work. |
| File appears in multiple topics | Mark with ⚡. Use hunk-level handling. |
| A forgotten stash exists | Remind the user with stash date and description. |
| Last commit is a merge commit instead of rebase | Warn. Ask if this was intentional. |
| Force push is needed | Always use `--force-with-lease`. Explain why this is safer. |
| Git history looks unusual (orphan commits, diverged branches) | Show what's happening. Ask before proceeding. |

## Staging Rules

- Never use `git add .` or `git add -A` — always stage specific files
- After staging, always show `git diff --cached --stat` for verification
- For mixed-topic files, use hunk-level staging (see references/hunk-analysis.md)

## Push Rules

- Always `git fetch origin` before pushing to check for remote changes
- Always use `--force-with-lease` instead of `--force`
- Only use `--force` with explicit user confirmation and an explanation of the risk
- Before pushing, check what will go out: `git log --oneline origin/<branch>..HEAD`

## Commit Rules

- Always show the proposed commit message and get user confirmation
- Use Conventional Commits format (feat, fix, refactor, chore, style, docs)
- On pre-commit hook failure: fix the issue and create a NEW commit — never `--amend`
- Always append: `Co-Authored-By: Claude <noreply@anthropic.com>`

## Destructive Operation Safety

Before any destructive operation, always:
1. Show exactly what will happen
2. Explain what could go wrong
3. Ask for explicit confirmation

Destructive operations include:
- `git reset --hard`
- `git checkout -- <file>` (discards changes)
- `git clean -f`
- `git push --force`
- `git rebase` (rewrites history)
- `git stash drop`

## Branch Detection

Detect the main branch automatically:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

Fallback: check if `origin/main` exists, then `origin/master`.

The user's working branch is always the current branch (`git branch --show-current`).

## Secret Patterns

Scan diffs for these patterns before pushing:
- Strings starting with `sk-`, `pk-`, `api_`, `token_`, `secret_`
- Base64-encoded strings longer than 40 characters in assignment context
- Connection strings containing `://` with credentials
- `.env` file content patterns (`KEY=value`)
- AWS access keys (`AKIA...`)
- Private keys (`-----BEGIN`)

When detected: show the line (with value partially redacted), explain the risk, and do not proceed with push until resolved.

## Edge Cases

Check for these situations at the start of any skill:

**Detached HEAD:**
```bash
git branch --show-current
```
If empty, you're in detached HEAD. Warn the user and ask if they want to checkout a branch first. Most skills (push, sync, commit) need a branch name.

**No remote:**
```bash
git remote | head -1
```
If empty, there's no remote configured. Skills that fetch/push won't work. Inform the user.

**Shallow clone:**
```bash
git rev-parse --is-shallow-repository
```
If "true", warn that history commands (log ranges, merge-base, rev-list --count) may produce incomplete results. Suggest `git fetch --unshallow` if needed.

**Empty repo (no commits):**
```bash
git rev-parse HEAD 2>/dev/null
```
If this fails, the repo has no commits. Most skills won't work. Inform the user.
