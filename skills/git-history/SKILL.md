---
name: git-history
description: File/function/line history as a readable narrative — who changed what, when, and why. Triggers: blame, history, "wer hat das geändert", "warum sieht das so aus", "who changed this", /git-history.
---

# Git History

Investigate the history of a file, function, or specific lines. The goal is a narrative — not a wall of commit hashes. Start with summaries, go deep only when needed.

## Safety (always apply)
- Never run `git log` without a range or limit — unbounded output wastes tokens
- Start with `--oneline` summaries, full diffs only when asked
- Use `--follow` to track files across renames
- See `references/branch-history.md` for efficient command patterns

## Workflow

### Step 1: Determine the Investigation Target

Ask if not clear from context:

- **File history**: "Show me the history of `src/api/orders.ts`"
- **Function history**: "Who changed `processOrder`?"
- **Line range**: "What happened to lines 45–80 of `src/utils/format.ts`?"
- **Blame**: "Who wrote this?" (with a file or function in context)

If the user refers to "this file" or "this function", ask which file/function they mean. Do not guess.

### Step 2: File History

For file-level history, start with the lightweight overview:

```bash
git log --oneline --follow -- <file>
```

The `--follow` flag tracks the file across renames.

Also check if the file has been renamed:

```bash
git log --oneline --follow --diff-filter=R -- <file>
```

Produce a summary:

```
src/api/orders.ts — History

Created:   6 months ago (a1b2c3d) by Alice — "feat(orders): initial order API"
Modified:  12 times by 3 contributors
Last change: 3 days ago (d4e5f6g) by Bob — "fix(orders): null check on empty result"
Renamed:   was src/api/ordersService.ts (renamed 2 months ago)

Commit timeline:
  3d ago  d4e5f6g  Bob      fix(orders): null check on empty result
  2w ago  e7f8g9h  Alice    refactor(orders): move to async/await
  1mo ago f9g0h1i  Charlie  chore: rename file to orders.ts
  2mo ago a2b3c4d  Alice    feat(orders): add pagination support
  ...
```

Ask: "Want to see what changed in a specific commit?"

### Step 3: Function or Line History

For function history, git can track a named function across commits:

```bash
git log -p -L :<funcname>:<file>
```

This shows every commit that touched that function and the exact diff each time.

For a line range (when the user knows the lines or you can identify them):

```bash
git log -p -L <start>,<end>:<file>
```

Token-efficiency: `-p` produces a lot of output. Read the first few commits first:

```bash
git log --oneline -L :<funcname>:<file>
```

Show the commit list first, then ask: "Which of these commits do you want to see in detail?"

Present:
```
processOrder() — Function History

First written: 4 months ago by Alice (feat: order processing pipeline)
Changed 5 times:

  3d ago  d4e5f6g  Bob     — added null check for missing customer
  2w ago  e7f8g9h  Alice   — refactored to async/await
  5w ago  f9g0h1i  Alice   — added retry logic on payment failure
  2mo ago a2b3c4d  Charlie — added logging
  4mo ago b3c4d5e  Alice   — initial implementation
```

### Step 4: Blame

For "who wrote this" questions:

```bash
git blame <file>
```

Or for a specific range:

```bash
git blame -L <start>,<end> <file>
```

Do not dump raw blame output — process it into a useful summary:

1. Group lines by author
2. Note the most recent change date per author
3. Highlight if a section was last touched very recently (possible active development) or long ago (stable or abandoned)

```
git blame summary — src/api/orders.ts (lines 45–80)

  Alice    34 lines  (last changed 2 months ago)
  Bob       2 lines  (last changed 3 days ago — lines 67, 71)
  Charlie   0 lines

Bob's recent changes (lines 67, 71):
  line 67: if (!result || result.rows.length === 0) return null
  line 71: const order = result.rows[0] ?? null
  → Added null safety 3 days ago in fix(orders): null check on empty result
```

### Step 5: Construct the Narrative

Synthesize the findings into a human-readable history. This is the core value of this skill — not raw git output.

Example:

```
History of processOrder()

This function was originally written by Alice 4 months ago as part of the
initial order processing pipeline. It was synchronous at first.

Charlie added logging 2 months ago — the console.log statements you see
are from that commit.

Alice refactored the whole function to async/await 2 weeks ago when the
payment API was updated to return Promises.

Bob's change 3 days ago (the most recent) added a null check — there was
apparently a bug where missing customer records caused a crash.

Most of the current logic is Alice's refactor. The null check on line 67
is Bob's fix.
```

### Step 6: Offer to Go Deeper

After presenting the summary, offer next steps:

```
Want to:
[1] See the full diff of a specific commit
[2] Blame a different file or function
[3] Check when a specific line was introduced (git log -S)
[4] Find which commit deleted a line or function
```

For option 3 (find when a string was introduced or removed):

```bash
git log -S "<search string>" --oneline -- <file>
```

For option 4 (find deleted code):

```bash
git log --all --full-history --oneline -- <file>
git show <commit> -- <file>
```

## Token Efficiency Rules

- Start with `--oneline` summaries — never dump full diffs unless asked
- For `git log -p -L`, read at most the last 5 commits initially
- If a file has more than 30 commits, show the 10 most recent and offer to load more
- For blame, show summaries grouped by author — not every line with a hash
- Only read the full `git show <commit>` output for commits the user specifically asks about
