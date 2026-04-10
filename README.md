<p align="center">
  <img src="assets/banner.png" alt="git-superpowers" width="100%">
</p>

# git-superpowers

Claude Code Skills für intelligente Git-Workflows. Topic-basierte Commits, smartes Rebasing, Multi-Repo Überblick, Pre-Push Auditing, Conflict-Vorhersage und mehr — alles KI-gestützt.

## Das Problem

- **Vermischte Änderungen** — mehrere Features und Bugfixes in derselben Branch, teilweise in denselben Dateien
- **Merge-Conflict-Chaos** — beim Rebase von main entstehen Conflicts in Dateien die Änderungen aus verschiedenen Topics enthalten
- **Unfertiges wird mitgepusht** — halbfertige Features landen versehentlich im Commit
- **Kein Überblick** — schwer zu sehen wo alle Repos stehen und was andere Branches machen
- **Vermeidbare Fehler** — Debug-Statements, vergessene Conflict-Marker, Secrets im Diff
- **Schwer nachvollziehbar** — wer hat was wann geändert und warum

## Skills

### Kern-Workflows

| Skill | Beschreibung |
|---|---|
| `/smart-commit` | Gruppiert Änderungen nach Topics per KI-Analyse. Wenn eine Datei Änderungen aus verschiedenen Topics enthält (Bugfix UND Feature), wird auf Hunk-Ebene gesplittet — jeder Commit ist sauber und fokussiert. |
| `/smart-sync` | Rebased deine Branch auf main mit Topic-basierter Conflict-Resolution. Statt roher Conflict-Diffs siehst du welches Topic jeder Conflict betrifft und wirst durch die Lösung geführt. |
| `/safe-push` | Pre-Push Audit mit automatischen Fixes. Scannt ausgehende Commits auf Debug-Statements, Conflict-Marker, Secrets, unvollständige Features und große Dateien. Sagt Conflicts vorher und fixt Probleme direkt — nicht nur Warnungen. |

### Überblick & Analyse

| Skill | Beschreibung |
|---|---|
| `/repo-overview` | Multi-Repo Dashboard: zeigt alle Repos mit Branch-Status, Behind/Ahead, uncommitted Changes und letztem Commit. Bietet direkte Aktionen an. |
| `/branch-inspect` | Zeigt was auf anderen Branches passiert — wer hat was committed, welche Dateien überschneiden sich, wo wird es Conflicts geben. |
| `/cross-compare` | Vergleicht wie ein bestimmtes Modul/eine Datei über mehrere Branches hinweg aussieht. Zeigt Unterschiede und potenzielle Kollisionen. |
| `/conflict-simulator` | Sagt Merge-Conflicts vorher BEVOR sie passieren — ohne den Rebase tatsächlich auszuführen. Zeigt Schweregrad und empfiehlt wann man syncen sollte. |

### Code-Qualität

| Skill | Beschreibung |
|---|---|
| `/diff-review` | KI-Code-Review deiner Änderungen vor dem Commit. Findet Bugs, Logic-Fehler, Security-Issues und fehlende Edge Cases — kein Linter, sondern ein Senior Dev Review. |
| `/commit-split` | Teilt einen bestehenden Commit nachträglich in mehrere fokussierte Commits auf. Erkennt Topics automatisch und führt durch den Split. |

### Branch-Operationen

| Skill | Beschreibung |
|---|---|
| `/cherry-pick` | Holt gezielt einzelne Commits aus anderen Branches. Zeigt vorher was kommt, prüft auf Duplikate und Conflicts. |
| `/selective-merge` | Bringt einzelne Dateien (nicht ganze Commits) aus einer anderen Branch. Wahlweise komplett ersetzen oder nur bestimmte Änderungen übernehmen. |
| `/hotfix` | Notfall-Workflow für Produktions-Bugs. Stashed aktuelle Arbeit, erstellt Hotfix-Branch von main, führt durch Fix + Audit + PR, und kehrt zur vorherigen Branch zurück. |

### History & Recovery

| Skill | Beschreibung |
|---|---|
| `/git-history` | Deep Dive in die Geschichte einer Datei oder Funktion. Wer hat was wann geändert und warum — als lesbare Zusammenfassung, nicht als rohe Git-Ausgabe. |
| `/git-undo` | Recovery wenn was schiefgeht. Falscher Branch, versehentlich gepusht, Commit rückgängig machen — zeigt immer die sicherste Option zuerst. |
| `/pr-prep` | Bereitet einen sauberen Pull Request vor. Prüft Status, führt Audit durch, generiert PR-Beschreibung aus Commits, erstellt PR via `gh`. |

## Installation

```bash
git clone https://github.com/Fxbio04/git-superpowers.git ~/.claude/plugins/git-superpowers
```

Dann in den Claude Code Settings den Plugin-Pfad registrieren. Fertig — alle 15 Skills sind sofort verfügbar.

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

## Sicherheit

Alle Skills folgen diesen Regeln:
- Nie `git add .` oder `git add -A` — immer spezifische Dateien stagen
- Nie `--force` Push — immer `--force-with-lease`
- Immer zeigen was passieren wird bevor es passiert
- Immer bestätigen lassen vor destruktiven Operationen
- Vor jedem Push auf Secrets scannen
- Probleme direkt fixen statt nur warnen
- Bei Unsicherheit nachfragen statt still kaputtmachen

## Author

[@Fxbio04](https://github.com/Fxbio04)

## Lizenz

MIT
