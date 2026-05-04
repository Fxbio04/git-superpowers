# Hunk-Level Analysis and Selective Staging

How to stage only specific parts of a file when it contains changes from multiple topics.

## When to Use Hunk-Level Splitting

Only when a file is marked as ⚡ (mixed topics) and the user wants to commit only one topic. If the entire file belongs to one topic, just `git add <file>`.

## The Problem

`git add -p` is interactive and requires stdin input — Claude cannot use it directly. We need alternative approaches.

## Approach 1: Edit-Stage-Restore (Recommended)

This is the safest and most reliable approach.

1. **Save the full file state:**
   ```bash
   cp <file> <file>.full-backup
   ```

2. **Read the diff and identify hunks:**
   ```bash
   git diff <file>
   ```

3. **Edit the file** — revert the changes that belong to the OTHER topic (the one NOT being committed). Use the Edit tool to put those lines back to their original state. Leave the changes for the WANTED topic in place.

4. **Stage the file:**
   ```bash
   git add <file>
   ```

5. **Restore the full file with all changes:**
   ```bash
   cp <file>.full-backup <file>
   rm <file>.full-backup
   ```

Now the staging area has only the wanted changes, and the working directory has everything.

## Approach 2: Patch Apply (Advanced)

For when you can construct a clean patch:

1. **Extract the wanted hunks** from `git diff <file>` output
2. **Write them to a patch file** with correct headers
3. **Apply to staging area:**
   ```bash
   git apply --cached <patch-file>
   rm <patch-file>
   ```

This is faster but more error-prone — patch headers must be exact.

## Verification

After either approach, always verify:

```bash
git diff --cached <file>    # shows what will be committed — should only contain wanted topic
git diff <file>             # shows what remains unstaged — should contain the other topic(s)
```

Show both outputs to the user for confirmation before proceeding.

## Safety Rules

- Always back up the file before editing for selective staging
- Always verify with `git diff --cached` after staging
- If anything looks wrong, `git reset HEAD <file>` to unstage and start over
- Never lose changes — the working directory must always retain all modifications after staging

## Cleanup on Failure

If the process is interrupted between backup and restore, `.full-backup` files may be left behind. After any hunk-level staging operation, always verify no backup files remain:

```bash
find . -name "*.full-backup" -not -path "./.git/*" 2>/dev/null
```

If found, restore them:
```bash
for f in $(find . -name "*.full-backup" -not -path "./.git/*"); do
  original="${f%.full-backup}"
  mv "$f" "$original"
done
```

Skills using this reference should check for leftover `.full-backup` files at the start of their workflow and offer to restore them.
