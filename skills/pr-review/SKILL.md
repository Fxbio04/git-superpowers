---
name: pr-review
description: Review someone else's pull request — fetch the diff, analyze it like a senior dev, draft comments, submit the review via gh. Triggers: "review PR", "schau dir den PR an", "review #123", "check bobby's PR", "PR reviewen", "was hältst du von dem PR", /pr-review.
---

# PR Review

Review a teammate's pull request end to end: understand what it does, find real problems, and submit an actionable review — approve, comment, or request changes. In a team, half of PR work is reviewing others; this is the counterpart to /pr-prep.

## Safety (always apply)
- Never submit a review without showing the user the full draft first
- Review comments criticize code, never people — concrete, actionable, with a suggested fix
- Never approve a PR the user hasn't seen — the user is the reviewer of record, Claude drafts
- Adapt verbosity to the user (see Adaptive Output in `references/git-safety.md`)

## Workflow

### Step 1: Identify the PR

```bash
gh auth status >/dev/null 2>&1 || echo "gh unavailable"
gh pr list --state open --json number,title,author,updatedAt,reviewDecision \
  --jq '.[] | "#\(.number) \(.title) — \(.author.login) (\(.reviewDecision // "REVIEW PENDING"))"'
```

If the user named a PR (number, branch, or description), resolve it directly with `gh pr view <ref>`. Otherwise show the list and ask which one. Highlight PRs where the user is a requested reviewer:

```bash
gh pr list --search "review-requested:@me" --json number,title
```

### Step 2: Understand the PR

Token-efficient order — metadata and stats first, full diff only after scoping:

```bash
gh pr view <number> --json title,body,author,baseRefName,additions,deletions,changedFiles,commits
gh pr diff <number> --name-only
```

Summarize for the user in 2-3 sentences: what the PR claims to do (from the description) and what it actually touches (from the file list). If description and file list don't match, that's already a finding.

For a large PR (>30 files or >1000 lines), ask which areas to focus on, or review the riskiest files first (source over tests, logic over config).

### Step 3: Read the Diff

```bash
gh pr diff <number>
```

For files where the diff alone lacks context, read the full file at the PR's head:

```bash
gh pr checkout <number>          # only if deeper inspection or running tests is needed
```

If you check out the PR, remember the previous branch and return to it in Step 6 (`git checkout -`). Uncommitted local work → stash first, pop after (same discipline as /hotfix Step 1).

### Step 4: Analyze

Apply the same review categories as /diff-review Step 4 (logic errors, missing error handling at boundaries, security, dead code, async/races, null safety, hardcoded config, jarring inconsistency) — plus PR-level checks:

- **Scope**: Does the PR do one thing? Flag unrelated drive-by changes.
- **Tests**: Does new behavior come with tests? Do changed tests still test the same contract?
- **Breaking changes**: API signatures, DB schemas, config formats — anything a consumer depends on.
- **Description honesty**: Does the Test Plan cover the risky parts?

Only real findings — a review with 2 findings that matter beats 15 nitpicks. No style comments unless it breaks something.

### Step 5: Draft the Review

Show the user the complete draft before anything is submitted:

```
Review draft for #142 "feat: amazon dashboard" (verdict: REQUEST CHANGES)

[1] 🔴 src/amazon/api.ts:45 — fetchOrders ignores the error case;
    on API failure the dashboard renders with undefined data.
    Suggest: propagate the error and show the error state.

[2] 🟡 src/amazon/Dashboard.tsx:112 — useEffect dependency array missing
    `filters` — stale data after filter change.

Overall comment: "Solid structure. Two correctness issues before merge — see inline."

Submit as: [a] Approve  [c] Comment only  [r] Request changes  [e] Edit draft  [x] Cancel
```

Verdict guidance: bugs/security → request changes; only suggestions → comment; clean → approve. The user decides.

### Step 6: Submit

```bash
gh pr review <number> --request-changes --body "$(cat <<'EOF'
<overall comment>
EOF
)"
```

(`--approve` / `--comment` accordingly.) For inline comments on specific lines, use the API:

```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  -f body='<comment>' -f commit_id='<head-sha>' -f path='<file>' -F line=<line> -f side=RIGHT
```

If you checked out the PR in Step 3, return: `git checkout -` (and pop the stash if one was made).

Confirm: "Review submitted: REQUEST CHANGES with 2 inline comments on #142."

## Rules

- The user sees and approves the complete review before submission — no exceptions
- Findings need file:line, the actual code, why it's a problem, and a concrete fix
- Never mix "approve" with unresolved critical findings — that's how bugs get merged
- If the PR is fine, approve with a short specific comment (what was checked) — not just "LGTM"
- Do not push commits onto someone else's PR branch unless the author asked for it
