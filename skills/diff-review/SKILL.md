---
name: diff-review
description: AI-powered semantic code review of your staged or unstaged changes before committing. Use when the user wants to review their changes, check code quality, validate readiness to commit, or says things like "review my changes", "check my code", "is this ready to commit", "code review", "schau dir meine änderungen an", "review before commit", "was hab ich geändert", "check before commit", or "look at my diff". Also triggers on /diff-review. This is a senior-developer review — semantic understanding of logic, security, and correctness — not a linter.
---

# Diff Review

Review your changes for real problems before they become commits. This skill reasons about logic, security, async correctness, and consistency — not whitespace and style. Fewer findings that actually matter, not 20 nitpicks.

Read `references/git-safety.md` before your first action.

## Workflow

### Step 1: Preflight

```bash
git status
```

Check you're in a git repo with actual changes. If there are no changes at all, say so and stop.

Determine what to review:
- If files are staged (`git diff --cached --stat` shows output): ask "Review staged changes, unstaged changes, or both?"
- Default: staged changes if any exist, otherwise all unstaged changes.

### Step 2: Overview

Get the scope without reading full diffs yet:

```bash
git diff --stat                  # unstaged
git diff --cached --stat         # staged
```

Show a summary: "You have 4 files changed, 128 insertions, 22 deletions."

If the diff is very large (>500 lines), say so and ask: "This is a large diff. Review all files or specific ones?"

### Step 3: Read the Changes

Read the actual diff:

```bash
git diff                         # unstaged changes
# or
git diff --cached                # staged changes
# or both, separated
```

For each file in the diff, understand:
- What this file does in the codebase (from its path and imports)
- What changed — not just the lines, but the intent
- The context around the changes (the unchanged lines surrounding them)

### Step 4: Review Each File

For each changed file, reason through these categories. Only flag something if there is a genuine issue — not a hypothetical.

**Logic errors and bugs**
- Control flow that can't work as written
- Off-by-one errors in loops or array access
- Conditions that are always true or always false
- Wrong operator (assignment instead of comparison, etc.)

**Missing error handling at system boundaries**
- `fetch` / `axios` calls without catch
- File system operations without error checks
- Database queries without null handling on the result
- JSON.parse without try/catch on external data

**Security issues**
- SQL injection: string concatenation into queries instead of parameterized queries
- XSS: user input rendered as HTML without sanitization
- Secrets or credentials hardcoded in the diff
- Insecure direct object references (using user-provided IDs without authorization check)

**Dead code and unused imports being added**
- New imports that are never used in the added code
- Functions defined but never called in the same diff
- Variables assigned but never read

**Async and race conditions**
- Missing `await` on a Promise
- State mutation in async callbacks that may run out of order
- `Promise.all` missing where parallel calls are independent and sequential is unnecessary

**Null and undefined safety**
- Chaining `.property` on values that could be null/undefined from external data
- Array access without bounds check on data from APIs or user input
- Optional values used as required without a guard

**Hardcoded values that belong in config**
- URLs, ports, or hostnames written as string literals
- Magic numbers with no explanation
- Environment-specific values (dev/staging/prod) baked into code

**Consistency with surrounding code**
- Only flag this if the inconsistency would cause a real bug or is very jarring (e.g., a file uses async/await everywhere and new code uses raw `.then()` in a way that breaks the pattern)

### Step 5: Present Findings

Group findings by severity. Only include severities that have at least one finding.

```
Diff Review — 4 files changed

🔴 CRITICAL (must fix before committing)
─────────────────────────────────────────
[1] src/api/orders.ts:34
    const result = JSON.parse(response.body)
    No try/catch around JSON.parse on external API data. A malformed response
    will crash the function.
    Fix: wrap in try/catch and return an error state on parse failure.

🟡 WARNING (should fix)
────────────────────────
[2] src/hooks/useProducts.ts:18
    Missing await: fetchProducts() is called without await — the component
    will render before data arrives.
    Fix: add await, or handle the Promise explicitly.

[3] src/components/Table.tsx:67
    <div dangerouslySetInnerHTML={{ __html: item.description }}>
    item.description comes from user input — this is an XSS vector.
    Fix: sanitize with DOMPurify before rendering, or use a text node instead.

🟢 SUGGESTION (optional)
─────────────────────────
[4] src/utils/format.ts:12
    import { formatDate } from './dates' — this import is never used in the
    added code.
    Fix: remove the import.

3 issues require attention. 1 suggestion.
```

If there are no issues:
```
Diff Review — 4 files changed

Looks good. No significant issues found.

The changes are logically consistent, error boundaries are handled, and
no security concerns were detected. Ready to commit.
```

### Step 6: Fix Selected Issues

If there are findings, ask with a multiSelect:

```
Which issues should I fix?
[ ] [1] Missing JSON.parse error handling (CRITICAL)
[ ] [2] Missing await in useProducts (WARNING)
[ ] [3] XSS via dangerouslySetInnerHTML (WARNING)
[ ] [4] Unused import (SUGGESTION)
[ ] Fix all
[ ] Skip — I'll handle these myself
```

For each selected issue:
- Read the file
- Apply the fix (add try/catch, add await, replace with safe alternative, remove import, etc.)
- Show the changed lines after fixing

### Step 7: Verify

After applying fixes, show the updated diff for confirmation:

```bash
git diff                   # or git diff --cached
```

"Here's the updated diff after fixes. Does this look right?"

If more issues are visible in the updated diff that weren't there before (fixes introducing new problems), flag them.

## Rules

- Do not flag style preferences — only real correctness, security, and reliability issues
- Do not repeat what ESLint or TypeScript would already catch as a compile error
- A finding must include: file and line, the actual code, what is wrong and why, and a concrete fix
- Never create a commit in this skill — the user commits when they are ready
- If the diff has no real issues, say so confidently — "no issues found" is a valid and useful outcome
- Apply fixes directly to files — do not just describe them

## Next Steps

After reviewing, use `/smart-commit` to commit your changes or `/safe-push` to push them.
