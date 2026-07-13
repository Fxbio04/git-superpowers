---
name: deploy-check
description: Catch deploy-config foot-guns before they crash the VM — hardcoded port collisions across branches, fixed container names, missing healthchecks, first-deploy audit. Reads configs via git, needs no Docker access. Triggers: "deploy check", "port belegt", "wird das deployment krachen", "container crash beim deploy", "docker-compose prüfen", "erster deploy", "check before deploy", /deploy-check.
---

# Deploy Check

A deploy config that works alone can still crash a shared VM: two branches declaring the same host port, a fixed `container_name` colliding with the running stack, a zero-downtime setup without healthchecks. This skill finds those problems **in git** — diffing configs and comparing them across all branches — before anything reaches the VM.

## Safety (always apply)
- This skill only reads — it never deploys, restarts, or touches containers
- Findings name the concrete failure ("port 8080 also declared on origin/feature-x → bind error on shared VM"), not vague warnings
- The root fix is usually infra-side (dynamic ports, proxy) — always say so; a git check is the seatbelt, not the engine

## Workflow

### Step 1: Find the Deploy Surface

```bash
git ls-files | grep -iE '(^|/)(docker-)?compose[^/]*\.ya?ml$|(^|/)Dockerfile|\.service$|(^|/)Procfile$|(^|/)(k8s|deploy|manifests)/.*\.ya?ml$|(^|/)\.env(\.|$)|(^|/)(nginx|caddy|traefik)[^/]*\.(conf|ya?ml)$'
```

Nothing found → "No deploy configs tracked in this repo." Stop. Otherwise state what the deploy surface is (compose file(s), Dockerfiles, unit files, …) and which of it the current branch **changed** vs. the default branch (`git diff --name-only origin/<base>...HEAD` filtered by the same pattern).

### Step 2: Static Foot-Gun Audit

Read each deploy file the branch touches (full read for changed files only — unchanged configs just take part in Step 3). Check for:

**Port collisions waiting to happen**
- Hardcoded host ports: `- "8080:80"`, `- 127.0.0.1:8080:80`, long syntax `published: 8080`. A fixed host port means: second stack on the same VM (another branch, another project, the old container during deploy) → `bind: address already in use` → crash.
- Duplicate host ports *within* the same file (two services claiming one port).

**Zero-downtime killers**
- `container_name:` — fixed names prevent rolling replacement and collide across stacks; compose derives unique names when you drop it.
- No `healthcheck:` on services behind a proxy — the proxy/`--wait` cannot know when the new container is ready, so traffic switches into a booting container.
- Missing `restart:` policy — a VM reboot silently kills the service.

**Reproducibility & data risks**
- `image: something:latest` — the deploy you tested is not the deploy you get.
- Host-path volumes (`/opt/data:...`) shared by stacks that don't expect sharing.
- `.env` files with real-looking values committed (cross-check secret patterns from `references/git-safety.md`).

### Step 3: Cross-Branch Collision Matrix

The incident this catches: branch-based deploys on a shared VM, each branch carrying its own compose file — two branches declaring the same host port or container name crash on deploy. Compare **all** branches without checking anything out:

```bash
for b in $(git branch -r --format='%(refname:short)' | grep -v HEAD); do
  for f in $(git ls-tree -r --name-only "$b" 2>/dev/null | grep -iE '(docker-)?compose[^/]*\.ya?ml$'); do
    git show "$b:$f" 2>/dev/null | grep -nE '^\s*-?\s*"?([0-9.]+:)?[0-9]{2,5}:[0-9]+"?\s*$|published:\s*[0-9]+|^\s*container_name:' \
      | sed "s|^|$b : |"
  done
done
```

Extract host ports and container names per branch, then report every value claimed by more than one branch (and note which branch is currently deployed, if the user knows):

```
Cross-branch deploy collisions:

  Host port 8080:  main, feature/analytics ⚠️
    → deploying feature/analytics next to main WILL fail (bind error)
  container_name "app-api":  main, feature/analytics ⚠️
    → second stack can't start while the first runs

  Host port 8081:  only feature/checkout ✓
```

Also check the current branch against the running convention: if all other branches use `${HOST_PORT:-…}` env-var ports and this branch hardcodes one, flag the deviation.

### Step 4: First-Deploy / New-Repo Audit

When the user says this is a new repo or first deploy, run Steps 1-2 on everything (not just the diff) plus:

- `.env` in `.gitignore`? An `.env.example` without real values present?
- Image tags pinned, restart policy set, healthcheck present?
- Which host ports does the config claim? List them and hand off the one check git cannot do:
  ```
  On the target VM, verify these ports are free before the first deploy:
    ss -tlnp | grep -E ':(8080|5432)\b'
  ```

### Step 5: Recommend the Real Fix

Findings from Steps 2-3 get the infra-grade recommendation, not just "change the number":

1. **Let Docker assign host ports** (`ports: - "80"`) and route by name via a reverse proxy (traefik labels / nginx upstream) — collisions become impossible.
2. **Or parameterize**: `"${HOST_PORT:-8080}:80"` plus per-branch derivation (e.g. CI sets `HOST_PORT` from the branch/PR number) — branch deploys stop sharing a port by construction.
3. **Scope the stack**: set `COMPOSE_PROJECT_NAME` per branch/environment so container/network/volume names never collide; drop `container_name:` entirely.
4. **Zero-downtime**: healthcheck + `docker compose up -d --wait` (or rolling `deploy.replicas` behind the proxy) — the old container keeps serving until the new one is healthy.

Offer to apply the config changes (edit compose, add healthcheck, parameterize ports) — those edits then go through the normal /smart-commit → /safe-push → /pr-prep flow.

## Rules

- Read-only toward infrastructure: analysis via git, verification commands for the VM are handed to the user, never run against remote hosts
- Every collision finding names both sides (which branches, which file, which line)
- Cross-branch analysis uses `git show branch:path` — never check out branches for this
- No new dependencies: detection is grep-based on YAML/config text; if a repo needs real YAML parsing, say so instead of guessing
- When the config is fine but the incident class is possible (branch deploys + shared VM), still surface recommendation 1-3 once — prevention beats detection
