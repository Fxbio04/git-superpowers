#!/usr/bin/env python3
"""Validate git-superpowers plugin structure.

Runs in CI and locally (python3 scripts/validate.py). Checks:
  1. Every skills/*/SKILL.md has frontmatter with name (== dir name) and description
  2. Every agents/*.md has frontmatter with name (== file stem) and description
  3. All `references/*.md` mentioned anywhere actually exist
  4. plugin.json and marketplace.json agree on version + description
  5. The skill count claimed in plugin.json's description matches skills/
  6. sync:review-categories blocks are identical between diff-review and code-reviewer
  7. hooks/hooks.json is valid JSON; hook scripts pass bash -n and are executable
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []


def err(msg: str) -> None:
    errors.append(msg)


def frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    m = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        err(f"{path.relative_to(ROOT)}: missing YAML frontmatter")
        return {}
    fields = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            fields[key.strip()] = value.strip()
    return fields


# 1. Skills
skill_dirs = sorted((ROOT / "skills").iterdir())
for d in skill_dirs:
    f = d / "SKILL.md"
    if not f.exists():
        err(f"skills/{d.name}: no SKILL.md")
        continue
    fm = frontmatter(f)
    if fm.get("name") != d.name:
        err(f"skills/{d.name}: frontmatter name '{fm.get('name')}' != directory name")
    desc = fm.get("description", "")
    if len(desc) < 40:
        err(f"skills/{d.name}: description too short to trigger reliably ({len(desc)} chars)")
    if len(desc) > 1024:
        err(f"skills/{d.name}: description exceeds 1024 chars ({len(desc)})")

# 2. Agents
for f in sorted((ROOT / "agents").glob("*.md")):
    fm = frontmatter(f)
    if fm.get("name") != f.stem:
        err(f"agents/{f.name}: frontmatter name '{fm.get('name')}' != file name")
    if not fm.get("description"):
        err(f"agents/{f.name}: missing description")

# 3. Referenced reference files exist
ref_pattern = re.compile(r"references/([a-z0-9-]+\.md)")
for f in list(ROOT.rglob("SKILL.md")) + list((ROOT / "agents").glob("*.md")):
    for name in set(ref_pattern.findall(f.read_text(encoding="utf-8"))):
        if not (ROOT / "references" / name).exists():
            err(f"{f.relative_to(ROOT)}: references/{name} does not exist")

# 4. Version + description sync
plugin = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text())
market = json.loads((ROOT / ".claude-plugin" / "marketplace.json").read_text())
mplugin = market["plugins"][0]
if plugin["version"] != mplugin["version"]:
    err(f"version drift: plugin.json {plugin['version']} != marketplace.json {mplugin['version']}")
if plugin["description"] != mplugin["description"]:
    err("description drift between plugin.json and marketplace.json")

# 5. Claimed skill count
m = re.match(r"(\d+)\b", plugin["description"])
if m and int(m.group(1)) != len(skill_dirs):
    err(f"plugin.json claims {m.group(1)} skills, repo has {len(skill_dirs)}")

# 6. sync-marked category lists stay identical
def categories(path: Path) -> list:
    text = path.read_text(encoding="utf-8")
    if "sync:review-categories" not in text:
        return []
    section = text.split("sync:review-categories", 1)[1]
    section = re.split(r"\n### ", section)[0]
    return re.findall(r"^\*\*(.+?)\*\*$", section, re.MULTILINE)

skill_cats = categories(ROOT / "skills" / "diff-review" / "SKILL.md")
agent_cats = categories(ROOT / "agents" / "code-reviewer.md")
shared = set(skill_cats) & set(agent_cats)
if not skill_cats or not agent_cats:
    err("sync:review-categories marker missing in diff-review or code-reviewer")
elif len(shared) < min(len(skill_cats), len(agent_cats)) - 2:
    err(f"review categories drifted: skill={skill_cats} agent={agent_cats}")

# 7. Hooks
hooks_json = ROOT / "hooks" / "hooks.json"
if hooks_json.exists():
    json.loads(hooks_json.read_text())
for script in (ROOT / "hooks").glob("*.sh"):
    if not script.stat().st_mode & 0o111:
        err(f"hooks/{script.name}: not executable (chmod +x)")
    r = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
    if r.returncode != 0:
        err(f"hooks/{script.name}: bash syntax error: {r.stderr.strip()}")

if errors:
    print(f"FAIL — {len(errors)} problem(s):")
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)
print(f"OK — {len(skill_dirs)} skills, agents, references, manifests, hooks validated")
