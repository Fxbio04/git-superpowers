# Topic Detection

How to recognize which changes belong to the same logical topic (feature, bugfix, refactor) using minimal tokens.

## Strategy: Progressive Detail

The goal is to group changes by topic while reading as little diff content as possible.

### Level 1: Path-Based Grouping (Zero Diff Reading)

Start here. Run:
```bash
git diff --name-only        # unstaged changes
git diff --cached --name-only  # staged changes
git ls-files --others --exclude-standard  # untracked files
```

Group files by directory structure. Files that share a common parent directory likely belong to the same topic:
- `src/auth/login.tsx` + `src/auth/redirect.ts` → "Auth" topic
- `src/amazon/dashboard.tsx` + `src/amazon/charts.tsx` → "Amazon" topic
- `package.json` + `package-lock.json` → "Dependencies" topic

This is often enough. If all changed files fall neatly into separate directories, you're done grouping.

### Level 2: Config-Based Mapping (Optional)

If a `.claude-git.yml` exists in the repo root, read it. It may contain explicit topic mappings:

```yaml
topics:
  amazon:
    paths: ["src/amazon/", "departments/amazon"]
  shopify:
    paths: ["src/shopify/", "departments/shopifySync"]
```

Apply these mappings before falling through to semantic analysis.

### Level 3: Semantic Analysis (Targeted Diff Reading)

Only read diffs for files that couldn't be grouped by path — typically shared files like `routes.tsx`, `config.ts`, `utils/api.ts`, or root-level files.

```bash
git diff <specific-file>
```

Read the diff and determine the topic by looking at:
- **Import statements** — what module is being imported tells you what feature it's for
- **Function/variable names** — `amazonApi`, `loginRedirect`, `shopifySync` are clear signals
- **Comments and commit context** — TODO comments, feature flags, descriptive variable names
- **Surrounding code** — what does the changed function do, what calls it

### Mixed Files

A file has mixed topics when its diff contains hunks belonging to different topics. Mark these with ⚡.

How to detect:
1. Read the file's diff
2. Look at each hunk (block of consecutive changes)
3. Determine if hunks serve different purposes

Example: `src/routes.tsx` might have one hunk adding an Amazon route and another fixing an auth redirect. These are different topics in the same file.

## Topic Naming

Generate short, descriptive topic names from the content:
- Use the feature/area name: "Amazon Analytics", "Login Bugfix", "Dependency Update"
- Keep names under 5 words
- Be specific enough to distinguish topics from each other

## Token Budget

Target: spend <500 tokens on topic detection for a typical set of changes (10-20 files). Path-based grouping costs nearly nothing. Only read individual file diffs when absolutely necessary.
