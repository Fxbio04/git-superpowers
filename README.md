<h1 align="center">git-superpowers</h1>

<p align="center">
  <img width="1376" height="768" alt="git-superpowers" src="https://github.com/user-attachments/assets/a92ccde2-920d-4b1a-8c99-742388568b8c" />
</p>

<p align="center">
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="License: MIT" />
  </a>
  <img src="https://img.shields.io/badge/Skills-15-orange?style=for-the-badge" alt="15 Skills" />
  <img src="https://img.shields.io/badge/Claude_Code-Plugin-blueviolet?style=for-the-badge&logo=anthropic&logoColor=white" alt="Claude Code Plugin" />
  <img src="https://img.shields.io/badge/Dependencies-0-brightgreen?style=for-the-badge" alt="Zero Dependencies" />
</p>

<p align="center">
  Claude Code Skills für intelligente Git-Workflows.<br>
  Topic-basierte Commits, smartes Rebasing, Multi-Repo Überblick, Pre-Push Auditing, Conflict-Vorhersage und mehr — alles KI-gestützt.
</p>

---

## Inhalt

- [Das Problem](#das-problem)
- [Skills](#skills)
  - [Kern-Workflows](#kern-workflows)
  - [Überblick & Analyse](#überblick--analyse)
  - [Code-Qualität](#code-qualität)
  - [Branch-Operationen](#branch-operationen)
  - [History & Recovery](#history--recovery)
- [Installation](#installation)
- [Optionale Konfiguration](#optionale-konfiguration)
- [Architektur](#architektur)
- [Sicherheit](#sicherheit)
- [Author](#author)
- [Lizenz](#lizenz)

---

## Das Problem

- **Vermischte Änderungen** — mehrere Features und Bugfixes in derselben Branch, teilweise in denselben Dateien
- **Merge-Conflict-Chaos** — beim Rebase von main entstehen Conflicts in Dateien die Änderungen aus verschiedenen Topics enthalten
- **Unfertiges wird mitgepusht** — halbfertige Features landen versehentlich im Commit
- **Kein Überblick** — schwer zu sehen wo alle Repos stehen und was andere Branches machen
- **Vermeidbare Fehler** — Debug-Statements, vergessene Conflict-Marker, Secrets im Diff
- **Schwer nachvollziehbar** — wer hat was wann geändert und warum

---

## Skills

### Kern-Workflows

| Skill | Beschreibung |
|---|---|
| `/git-superpowers:smart-commit` | Gruppiert Änderungen nach Topics per KI-Analyse. Wenn eine Datei Änderungen aus verschiedenen Topics enthält (Bugfix UND Feature), wird auf Hunk-Ebene gesplittet — jeder Commit ist sauber und fokussiert. |
| `/git-superpowers:smart-sync` | Rebased deine Branch auf main mit Topic-basierter Conflict-Resolution. Statt roher Conflict-Diffs siehst du welches Topic jeder Conflict betrifft und wirst durch die Lösung geführt. |
| `/git-superpowers:safe-push` | Pre-Push Audit mit automatischen Fixes. Scannt ausgehende Commits auf Debug-Statements, Conflict-Marker, Secrets, unvollständige Features und große Dateien. Sagt Conflicts vorher und fixt Probleme direkt — nicht nur Warnungen. |

### Überblick & Analyse

| Skill | Beschreibung |
|---|---|
| `/git-superpowers:repo-overview` | Multi-Repo Dashboard: zeigt alle Repos mit Branch-Status, Behind/Ahead, uncommitted Changes und letztem Commit. Bietet direkte Aktionen an. |
| `/git-superpowers:branch-inspect` | Zeigt was auf anderen Branches passiert — wer hat was committed, welche Dateien überschneiden sich, wo wird es Conflicts geben. |
| `/git-superpowers:cross-compare` | Vergleicht wie ein bestimmtes Modul/eine Datei über mehrere Branches hinweg aussieht. Zeigt Unterschiede und potenzielle Kollisionen. |
| `/git-superpowers:conflict-simulator` | Sagt Merge-Conflicts vorher BEVOR sie passieren — ohne den Rebase tatsächlich auszuführen. Zeigt Schweregrad und empfiehlt wann man syncen sollte. |

### Code-Qualität

| Skill | Beschreibung |
|---|---|
| `/git-superpowers:diff-review` | KI-Code-Review deiner Änderungen vor dem Commit. Findet Bugs, Logic-Fehler, Security-Issues und fehlende Edge Cases — kein Linter, sondern ein Senior Dev Review. |
| `/git-superpowers:commit-split` | Teilt einen bestehenden Commit nachträglich in mehrere fokussierte Commits auf. Erkennt Topics automatisch und führt durch den Split. |

### Branch-Operationen

| Skill | Beschreibung |
|---|---|
| `/git-superpowers:cherry-pick` | Holt gezielt einzelne Commits aus anderen Branches. Zeigt vorher was kommt, prüft auf Duplikate und Conflicts. |
| `/git-superpowers:selective-merge` | Bringt einzelne Dateien (nicht ganze Commits) aus einer anderen Branch. Wahlweise komplett ersetzen oder nur bestimmte Änderungen übernehmen. |
| `/git-superpowers:hotfix` | Notfall-Workflow für Produktions-Bugs. Stashed aktuelle Arbeit, erstellt Hotfix-Branch von main, führt durch Fix + Audit + PR, und kehrt zur vorherigen Branch zurück. |

### History & Recovery

| Skill | Beschreibung |
|---|---|
| `/git-superpowers:git-history` | Deep Dive in die Geschichte einer Datei oder Funktion. Wer hat was wann geändert und warum — als lesbare Zusammenfassung, nicht als rohe Git-Ausgabe. |
| `/git-superpowers:git-undo` | Recovery wenn was schiefgeht. Falscher Branch, versehentlich gepusht, Commit rückgängig machen — zeigt immer die sicherste Option zuerst. |
| `/git-superpowers:pr-prep` | Bereitet einen sauberen Pull Request vor. Prüft Status, führt Audit durch, generiert PR-Beschreibung aus Commits, erstellt PR via `gh`. |

---

## Installation

```bash
# 1. Repo clonen
git clone https://github.com/Fxbio04/git-superpowers.git ~/git-superpowers

# 2. Als Plugin registrieren (in installed_plugins.json eintragen)
# Datei: ~/.claude/plugins/installed_plugins.json
# Folgenden Block in "plugins" hinzufügen:
```

```json
"git-superpowers@local": [
  {
    "scope": "user",
    "installPath": "<PFAD-ZU>/git-superpowers",
    "version": "1.0.0",
    "installedAt": "2026-04-11T00:00:00.000Z",
    "lastUpdated": "2026-04-11T00:00:00.000Z"
  }
]
```

```bash
# 3. Claude Code neu starten — alle 15 Skills sind verfügbar als:
#    git-superpowers:smart-commit, git-superpowers:repo-overview, etc.
```

---

## Optionale Konfiguration

Funktioniert ohne jede Config in jedem Git-Repo.

Wer will, kann eine `.claude-git.yml` im Repo-Root anlegen für custom Topic-Mappings:

```yaml
# Optional: Verzeichnisse für repo-overview
scan_dirs:
  - ~/source/
  - ~/projects/

# Optional: Explizite Topic-Zuordnungen für smart-commit
topics:
  amazon:
    paths: ["src/amazon/", "departments/amazon"]
  shopify:
    paths: ["src/shopify/", "departments/shopifySync"]
```

---

## Architektur

```
git-superpowers/
├── skills/
│   ├── smart-commit/          # Topic-basiert committen
│   ├── smart-sync/            # Intelligenter Rebase
│   ├── safe-push/             # Pre-Push Audit + Conflict-Prediction
│   ├── repo-overview/         # Multi-Repo Dashboard
│   ├── branch-inspect/        # Branch-Analyse
│   ├── cross-compare/         # Cross-Branch Vergleich
│   ├── conflict-simulator/    # Conflict-Vorhersage
│   ├── diff-review/           # KI-Code-Review
│   ├── commit-split/          # Commits aufteilen
│   ├── cherry-pick/           # Commits aus anderen Branches
│   ├── selective-merge/       # Dateien aus anderen Branches
│   ├── hotfix/                # Notfall-Workflow
│   ├── git-history/           # File/Function History
│   ├── git-undo/              # Recovery bei Fehlern
│   └── pr-prep/               # PR vorbereiten
├── references/
│   ├── topic-detection.md     # KI-Topic-Erkennung
│   ├── hunk-analysis.md       # Hunk-Level Splitting
│   ├── conflict-resolution.md # Conflict-Strategien
│   ├── git-safety.md          # Shared Safety-Regeln
│   └── branch-history.md      # Git-History Commands
└── docs/specs/                # Design-Dokumentation
```

**Pure Skills, keine Dependencies.** Alles läuft über Claudes natürliche Fähigkeiten — Diffs lesen, Code verstehen, Git-Commands ausführen. Keine Scripts, keine MCP-Server, kein `npm install`.

**Token-effizient by Design.** Skills nutzen `git diff --stat` und `--name-only` für Überblicke, volle Diffs werden nur gelesen wenn semantische Analyse nötig ist.

---

## Sicherheit

- Nie `git add .` oder `git add -A` — immer spezifische Dateien stagen
- Nie `--force` Push — immer `--force-with-lease`
- Immer zeigen was passieren wird bevor es passiert
- Immer bestätigen lassen vor destruktiven Operationen
- Vor jedem Push auf Secrets scannen
- Probleme direkt fixen statt nur warnen
- Bei Unsicherheit nachfragen statt still kaputtmachen

---

## Author

[@Fxbio04](https://github.com/Fxbio04)

## Lizenz

MIT
