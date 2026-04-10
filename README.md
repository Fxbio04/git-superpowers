# git-superpowers

Claude Code Skills fuer intelligente Git-Workflows. Topic-basierte Commits, smartes Rebasing, Multi-Repo Ueberblick, Pre-Push Auditing, Conflict-Vorhersage und mehr — alles KI-gestuetzt.

## Das Problem

Teams die in Feature-Branches arbeiten kennen das:
- **Vermischte Aenderungen** — mehrere Features und Bugfixes in derselben Branch, teilweise in denselben Dateien
- **Merge-Conflict-Chaos** — beim Rebase von main entstehen Conflicts in Dateien die Aenderungen aus verschiedenen Topics enthalten
- **Unfertiges wird mitgepusht** — halbfertige Features landen versehentlich im Commit
- **Kein Ueberblick** — schwer zu sehen wo alle Repos stehen und was andere Branches machen
- **Vermeidbare Fehler** — Debug-Statements, vergessene Conflict-Marker, Secrets im Diff
- **Schwer nachvollziehbar** — wer hat was wann geaendert und warum

## Skills

### Kern-Workflows

| Skill | Beschreibung |
|---|---|
| `/smart-commit` | Gruppiert Aenderungen nach Topics per KI-Analyse. Wenn eine Datei Aenderungen aus verschiedenen Topics enthaelt (Bugfix UND Feature), wird auf Hunk-Ebene gesplittet — jeder Commit ist sauber und fokussiert. |
| `/smart-sync` | Rebased deine Branch auf main mit Topic-basierter Conflict-Resolution. Statt roher Conflict-Diffs siehst du welches Topic jeder Conflict betrifft und wirst durch die Loesung gefuehrt. |
| `/safe-push` | Pre-Push Audit mit automatischen Fixes. Scannt ausgehende Commits auf Debug-Statements, Conflict-Marker, Secrets, unvollstaendige Features und grosse Dateien. Sagt Conflicts vorher und fixt Probleme direkt — nicht nur Warnungen. |

### Ueberblick & Analyse

| Skill | Beschreibung |
|---|---|
| `/repo-overview` | Multi-Repo Dashboard: zeigt alle Repos mit Branch-Status, Behind/Ahead, uncommitted Changes und letztem Commit. Bietet direkte Aktionen an. |
| `/branch-inspect` | Zeigt was auf anderen Branches passiert — wer hat was committed, welche Dateien ueberschneiden sich, wo wird es Conflicts geben. |
| `/cross-compare` | Vergleicht wie ein bestimmtes Modul/eine Datei ueber mehrere Branches hinweg aussieht. Zeigt Unterschiede und potenzielle Kollisionen. |
| `/conflict-simulator` | Sagt Merge-Conflicts vorher BEVOR sie passieren — ohne den Rebase tatsaechlich auszufuehren. Zeigt Schweregrad und empfiehlt wann man syncen sollte. |

### Code-Qualitaet

| Skill | Beschreibung |
|---|---|
| `/diff-review` | KI-Code-Review deiner Aenderungen vor dem Commit. Findet Bugs, Logic-Fehler, Security-Issues und fehlende Edge Cases — kein Linter, sondern ein Senior Dev Review. |
| `/commit-split` | Teilt einen bestehenden Commit nachtraeglich in mehrere fokussierte Commits auf. Erkennt Topics automatisch und fuehrt durch den Split. |

### Branch-Operationen

| Skill | Beschreibung |
|---|---|
| `/cherry-pick` | Holt gezielt einzelne Commits aus anderen Branches. Zeigt vorher was kommt, prueft auf Duplikate und Conflicts. |
| `/selective-merge` | Bringt einzelne Dateien (nicht ganze Commits) aus einer anderen Branch. Wahlweise komplett ersetzen oder nur bestimmte Aenderungen uebernehmen. |
| `/hotfix` | Notfall-Workflow fuer Produktions-Bugs. Stashed aktuelle Arbeit, erstellt Hotfix-Branch von main, fuehrt durch Fix + Audit + PR, und kehrt zur vorherigen Branch zurueck. |

### History & Recovery

| Skill | Beschreibung |
|---|---|
| `/git-history` | Deep Dive in die Geschichte einer Datei oder Funktion. Wer hat was wann geaendert und warum — als lesbare Zusammenfassung, nicht als rohe Git-Ausgabe. |
| `/git-undo` | Recovery wenn was schiefgeht. Falscher Branch, versehentlich gepusht, Commit rueckgaengig machen — zeigt immer die sicherste Option zuerst. |
| `/pr-prep` | Bereitet einen sauberen Pull Request vor. Prueft Status, fuehrt Audit durch, generiert PR-Beschreibung aus Commits, erstellt PR via `gh`. |

## Installation

```bash
git clone https://github.com/Fxbio04/git-superpowers.git ~/.claude/plugins/git-superpowers
```

Dann in den Claude Code Settings den Plugin-Pfad registrieren. Fertig — alle 15 Skills sind sofort verfuegbar.

## Optionale Konfiguration

Funktioniert ohne jede Config in jedem Git-Repo.

Wer will, kann eine `.claude-git.yml` im Repo-Root anlegen fuer custom Topic-Mappings:

```yaml
# Optional: Verzeichnisse die repo-overview scannen soll
scan_dirs:
  - ~/source/
  - ~/projects/

# Optional: Explizite Topic-Zuordnungen fuer smart-commit
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

**Pure Skills, keine Dependencies.** Alles laeuft ueber Claudes natuerliche Faehigkeiten — Diffs lesen, Code verstehen, Git-Commands ausfuehren. Keine Scripts, keine MCP-Server, kein `npm install`.

**Token-effizient by Design.** Skills nutzen `git diff --stat` und `--name-only` fuer Ueberblicke, volle Diffs werden nur gelesen wenn semantische Analyse noetig ist.

## Sicherheit

Alle Skills folgen diesen Regeln:
- Nie `git add .` oder `git add -A` — immer spezifische Dateien stagen
- Nie `--force` Push — immer `--force-with-lease`
- Immer zeigen was passieren wird bevor es passiert
- Immer bestaetigen lassen vor destruktiven Operationen
- Vor jedem Push auf Secrets scannen
- Probleme direkt fixen statt nur warnen
- Bei Unsicherheit nachfragen statt still kaputtmachen

## Lizenz

MIT
