# git-superpowers — Design Spec

> Claude Code Skill-Paket fuer intelligente Git-Workflows mit KI-gestuetzter Topic-Erkennung, Hunk-Level Splitting und proaktiver Fehlervermeidung.

## Motivation

Teams die in Feature-Branches arbeiten kaempfen mit:
- **Gemischte Aenderungen**: Mehrere Features/Bugfixes in derselben Branch, teilweise in denselben Dateien
- **Merge-Conflict-Chaos**: Beim Rebase von main kommen Conflicts in Dateien die Aenderungen aus verschiedenen Topics enthalten (z.B. Amazon-Imports + Bugfix in einer Datei)
- **Unfertiges wird mitgepusht**: Beim Pushen landen halbfertige Features mit im Commit
- **Fehlender Ueberblick**: Kein schneller Weg zu sehen wo alle Repos stehen und was andere Branches machen
- **Git-Fehler**: console.log im Push, vergessene Conflict-Marker, Secrets im Diff

## Architektur

### Ansatz: Pure Skills mit Smart-Querying

Keine Scripts, keine MCP-Server, keine Dependencies. Alles liegt in SKILL.md Dateien die Claude's natuerliche Faehigkeiten (Diffs lesen, Code verstehen) nutzen.

**Token-Effizienz durch gezieltes Querying:**
- `git diff --stat` und `--name-only` fuer Ueberblick (wenige Zeilen)
- Nur bei Bedarf: `git diff <datei>` fuer einzelne Dateien
- Nie den gesamten Diff in den Kontext laden

### Repo-Struktur

```
git-superpowers/
├── skills/
│   ├── smart-commit/SKILL.md
│   ├── smart-sync/SKILL.md
│   ├── repo-overview/SKILL.md
│   ├── safe-push/SKILL.md
│   └── branch-inspect/SKILL.md
├── references/
│   ├── topic-detection.md
│   ├── hunk-analysis.md
│   ├── conflict-resolution.md
│   ├── git-safety.md
│   └── branch-history.md
├── README.md
└── LICENSE (MIT)
```

### Installation

```bash
git clone https://github.com/Fxbio04/git-superpowers.git ~/.claude/plugins/git-superpowers
```

Plugin-Pfad in Claude Code Settings registrieren. Keine weitere Config noetig.

### Optionale Config: `.claude-git.yml`

Nicht required. Wer will, kann im Repo-Root custom Topic-Mappings definieren:

```yaml
scan_dirs:
  - ~/source/
  - ~/projects/

topics:
  amazon:
    paths: ["src/amazon/", "departments/amazon"]
  shopify:
    paths: ["src/shopify/", "departments/shopifySync"]
```

Ohne Config erkennt Claude Topics rein KI-basiert aus Pfaden und Diff-Inhalten.

---

## Skills

### 1. Smart Commit (`/smart-commit`)

Selektives Committen nach Topics mit Hunk-Level Granularitaet.

#### Ablauf

1. **Preflight**
   - Pruefen ob Git-Repo, aktuelle Branch zeigen
   - `git status` (nicht `-uall`)
   - Falls keine Aenderungen: stoppen

2. **Schnelle Analyse (Token-effizient)**
   - `git diff --stat` + `git diff --name-only` fuer Ueberblick
   - Keine vollen Diffs in den Kontext laden

3. **Topic-Erkennung**
   - Dateien nach Topics gruppieren basierend auf:
     - Pfadstruktur (erste Heuristik)
     - `.claude-git.yml` Mappings falls vorhanden
     - Bei unklaren Dateien: gezielt `git diff <datei>` lesen und semantisch zuordnen
   - **Generisch**: Keine hardcoded Department-Tabelle. Claude erkennt Topics dynamisch.
     - Repo A: erkennt "Amazon", "Shopify", "Lager"
     - Repo B: erkennt "API", "Frontend", "Auth"

4. **Gemischte Dateien erkennen**
   - Wenn eine Datei Hunks von verschiedenen Topics enthaelt → ⚡-Markierung
   - Nur fuer diese Dateien wird `git diff <datei>` gelesen

5. **Uebersicht anzeigen**
   ```
   Topics erkannt:

   [1] Bugfix Login-Redirect (3 Dateien)
       M  src/auth/login.tsx
       M  src/auth/redirect.ts
       M  src/utils/url.ts

   [2] Amazon Analytics Feature (5 Dateien)
       A  src/amazon/dashboard.tsx
       A  src/amazon/charts.tsx
       M  src/utils/url.ts ⚡ (auch in Topic 1)

   [3] Dependency Updates (1 Datei)
       M  package.json

   ⚡ = Datei enthaelt Aenderungen aus mehreren Topics
   ```

6. **User waehlt Topics** — per AskUserQuestion: "1,3" oder "alle"

7. **Hunk-Level Splitting** — Bei ⚡-Dateien: Claude kann `git add -p` nicht interaktiv nutzen. Stattdessen:
   - Datei lesen, die Aenderungen des NICHT-gewaehlten Topics temporaer zuruecknehmen
   - `git add <datei>` (jetzt nur mit den gewaehlten Aenderungen)
   - Datei wiederherstellen mit allen Aenderungen via `git checkout -- <datei>` NICHT ausfuehren — stattdessen die zurueckgenommenen Aenderungen als unstaged belassen
   - Alternativ: `git diff <datei>` in einzelne Hunks splitten, gewaehlte Hunks als Patch via `echo '...' | git apply --cached` anwenden

8. **Staged Review** — `git diff --cached --stat` zeigen zur Bestaetigung

9. **Commit-Message** — Conventional Commits, Claude schlaegt vor, User bestaetigt per AskUserQuestion

10. **Optional Push** — Fragt ob direkt gepusht werden soll

11. **Loop** — Verbleibende Aenderungen zeigen, fragen ob weitere Topics committet werden sollen

#### Regeln
- NIEMALS `git add .` oder `git add -A`
- IMMER spezifische Dateien/Hunks stagen
- IMMER Commit-Message dem User zur Bestaetigung zeigen
- IMMER `git diff --cached --stat` nach dem Stagen zeigen
- Bei Pre-Commit Hook Fehler: neuen Commit erstellen, nicht `--amend`

---

### 2. Smart Sync (`/smart-sync`)

Intelligenter Rebase mit Topic-aware Conflict Resolution.

#### Ablauf

1. **Preflight**
   - Uncommitted Changes → `git stash push -m "smart-sync auto-stash"`
   - `git fetch origin`
   - `git log --oneline HEAD..origin/main` → was kommt rein
   - Falls nichts: "Branch ist bereits aktuell." und stoppen

2. **Pre-Rebase Analyse**
   - Zeigt: "X Commits von main kommen rein"
   - `git diff --stat HEAD...origin/main` → betroffene Dateien
   - Warnt wenn Dateien betroffen sind die der User auch geaendert hat

3. **Rebase starten**
   - `git rebase origin/main`
   - Bei Erfolg ohne Conflicts → direkt zu Schritt 6

4. **Conflict-Analyse (Topic-Level)**
   - `git diff --name-only --diff-filter=U` → Conflict-Dateien
   - Claude liest jeden Conflict, analysiert Hunks, gruppiert nach Topics:
     ```
     Merge Conflicts erkannt:

     [Bugfix Login] 1 Conflict in src/auth/login.tsx
       → Dein Fix fuer den Redirect-Bug vs. Refactoring aus main

     [Amazon Feature] 2 Conflicts
       → src/utils/api.ts: Deine Amazon-Imports vs. neue API-Struktur
       → src/routes.tsx: Deine neue Route vs. Route-Refactoring

     [Gemischt] 1 Conflict
       → src/config.ts: Enthaelt Aenderungen fuer Bugfix UND Amazon
     ```

5. **Resolution pro Topic**
   - Optionen per AskUserQuestion:
     - **Behalten** — Deine Version (`--theirs` bei Rebase!)
     - **Main uebernehmen** — Version aus main (`--ours` bei Rebase!)
     - **Manuell** — Claude zeigt Conflict, User entscheidet
   - **Wichtig**: Bei Rebase ist `--ours`/`--theirs` invertiert gegenueber Merge. Der Skill kommuniziert das klar.
   - Bei gemischten Conflicts: Hunk-Level Resolution mit Topic-Labels
   - Nach jeder Datei: `git add <datei>` → `git rebase --continue`
   - Jederzeit: `git rebase --abort` als Option
   - Bei >5 Conflicts: aktiv fragen ob abort sinnvoller waere

6. **Safe Push**
   - `git push --force-with-lease origin <branch>`
   - Falls fehlschlaegt (jemand hat gepusht): warnen und fragen
   - `--force` nur mit expliziter User-Bestaetigung

7. **Cleanup**
   - Stash poppen falls vorhanden
   - `git log --oneline <branch>..origin/main` → Behind: 0 verifizieren
   - Zusammenfassung zeigen

#### Regeln
- Nie `git merge`, immer `git rebase`
- Nie `--force`, immer `--force-with-lease` als Default
- `--ours`/`--theirs` Invertierung bei Rebase IMMER klar kommunizieren
- Nie `git rebase -i` (interaktiv nicht supported in CLI)

---

### 3. Repo Overview (`/repo-overview`)

Multi-Repo Dashboard mit Ueberblick ueber alle Repos.

#### Ablauf

1. **Repos finden**
   - Scannt konfigurierbare Verzeichnisse (Default: `~/source/`)
   - `.claude-git.yml` mit `scan_dirs` falls vorhanden
   - Fallback: aktuelles Verzeichnis + Geschwister-Repos

2. **Pro Repo sammeln (Token-effizient, alles via `git -C`):**
   - `branch --show-current` → aktuelle Branch
   - `fetch origin --quiet` → aktualisieren
   - `rev-list --count HEAD..origin/main` → Behind main
   - `rev-list --count origin/main..HEAD` → Ahead of main
   - `status --porcelain` → Uncommitted Changes zaehlen
   - `log --oneline -3` → Letzte 3 Commits

3. **Dashboard anzeigen:**
   ```
   Repo Overview (5 Repos in ~/source/)

   Repo                  Branch  Behind  Ahead  Uncommitted
   ─────────────────────────────────────────────────────────
   connector             fb      12 ⚠️    3      7 files
   ews-connector         fb       0 ✓     1      0 files
   brognoMicroServices   fb       4 ⚠️    0      2 files
   shopify-connector     fb       0 ✓     5      0 files
   brognoMCP             main     0 ✓     0      0 files

   ⚠️ 2 Repos sind behind main
   ```

4. **Aktionen anbieten:**
   - "Willst du ein Repo syncen?" → Smart Sync ausfuehren
   - "Details zu einem Repo?" → Commits, Changes, diff --stat
   - Kein Batch "sync all" — jeder Sync braucht Aufmerksamkeit

---

### 4. Safe Push (`/safe-push`)

Pre-Push Audit mit aktiven Fixes.

#### Ablauf

1. **Was geht raus?**
   - `git log --oneline origin/<branch>..HEAD` → Commits
   - `git diff --stat origin/<branch>..HEAD` → Datei-Uebersicht
   - Falls nichts: stoppen

2. **Audit-Checks:**
   - **Unfertige Topics** — Claude erkennt ob zusammengehoerige Aenderungen fehlen
   - **Debug-Artefakte** — `console.log`, `debugger`, `TODO`, `FIXME`, `HACK`
   - **Secrets** — Patterns die wie API-Keys, Tokens, Passwoerter aussehen
   - **Grosse Dateien** — Binaere oder ungewoehnlich grosse Dateien
   - **Conflict-Marker** — Vergessene `<<<<<<<` / `=======` / `>>>>>>>`

3. **Report + direkte Aktion:**
   ```
   Safe Push Audit fuer fb → origin/fb

   3 Commits, 8 Dateien

   ✓ Keine Secrets gefunden
   ✓ Keine Conflict-Marker

   Gefundene Issues:
   [1] console.log in src/amazon/dashboard.tsx:45
   [2] console.log in src/amazon/dashboard.tsx:89
   [3] Fehlender Import: ProductChart wird genutzt aber nicht im Push
   [4] TODO in src/utils/api.ts:12
   ```

   Dann per AskUserQuestion multiSelect:
   ```
   Welche Issues soll ich fixen?
   □ [1] console.log entfernen (Zeile 45)
   □ [2] console.log entfernen (Zeile 89)
   □ [3] ProductChart-Datei zum Commit hinzufuegen
   □ [4] TODO entfernen / implementieren
   □ Alle fixen
   □ Ignorieren und trotzdem pushen
   ```

4. **Claude fixt ausgewaehlte Issues:**
   - Entfernt Debug-Artefakte direkt
   - Staged fehlende Dateien nach
   - Bei TODOs: fragt was rein soll oder entfernt Kommentar
   - Erstellt Cleanup-Commit (nie `--amend` auf bereits gepushte Commits)
   - Zeigt `git diff --cached --stat` zur Bestaetigung

5. **Push** — `git push origin <branch>`, bei Fehler Loesung anbieten

---

### 5. Branch Inspect (`/branch-inspect`)

Zeigt was andere Branches machen und warnt vor potenziellen Conflicts.

#### Ablauf

1. **Alle Branches zeigen:**
   ```bash
   git branch -r --sort=-committerdate --format='%(refname:short) %(committerdate:relative) %(authorname)'
   ```
   ```
   Aktive Branches:

   [1] origin/bb    — vor 2 Stunden (Bobby)
   [2] origin/fb    — vor 1 Tag (du)
   [3] origin/it    — vor 3 Tagen (IT)
   [4] origin/main  — vor 5 Stunden (merged)
   ```

2. **User waehlt Branch** → Claude zeigt:
   - `git log --oneline origin/main..origin/<branch>` → Commits seit main
   - `git diff --stat origin/main..origin/<branch>` → geaenderte Dateien
   - `git shortlog -sn origin/main..origin/<branch>` → wer hat was committed
   - Zusammenfassung: "Bobby arbeitet an Ticket-System und Lager-Bugfixes"

3. **Vergleich mit deiner Branch:**
   ```
   Ueberschneidungen fb ↔ bb:

   ⚠️ 3 Dateien in beiden Branches geaendert:
     src/utils/api.ts  — du: Amazon-Imports / bb: Ticket-API
     src/routes.tsx     — du: neue Route / bb: neue Route
     package.json       — du: neue Dep / bb: andere Dep

   → Wenn bb zuerst in main merged, wirst du 3 Conflicts haben
   ```

4. **Proaktive Empfehlung:**
   - Erkennt potenzielle Conflicts BEVOR sie passieren
   - Schlaegt vor: "Bobby's Aenderungen an routes.tsx sind klein — du koenntest deinen Teil jetzt anpassen"

---

## Shared References

### `references/topic-detection.md`

Anleitung fuer KI-basierte Topic-Erkennung:
- Erst `--stat`/`--name-only` fuer Ueberblick (Token-effizient)
- Pfad-Heuristik als erste Gruppierung
- Nur bei unklaren Dateien: gezielt `git diff <datei>` lesen
- Semantische Analyse: Imports, Funktionsnamen, Kommentare
- `.claude-git.yml` Mappings nutzen wenn vorhanden
- Gemischte Dateien mit ⚡ markieren

### `references/hunk-analysis.md`

Hunk-Level Splitting Anleitung:
- `git add -p` ist interaktiv und kann von Claude nicht direkt genutzt werden
- Stattdessen: Datei editieren (nicht-gewaehlte Aenderungen zuruecknehmen), stagen, dann Datei mit allen Aenderungen wiederherstellen
- Alternative: Hunks als Patch extrahieren und via `git apply --cached` anwenden
- Wann splitten (gemischte Topics) vs. ganze Datei stagen
- Hunks lesen und Topics zuordnen
- Sicherheit: nach Staging immer `git diff --cached` verifizieren

### `references/conflict-resolution.md`

Conflict-Resolution Strategien:
- Conflict-Marker Format: `<<<<<<<`, `=======`, `>>>>>>>`
- `--ours` vs `--theirs` Invertierung bei Rebase klar erklaeren
- Topic-basierte Resolution: erst Ueberblick auf Topic-Ebene, dann Hunk-Level bei gemischten
- Wann `--abort` empfehlen (>5 Conflicts, unuebersichtlich)
- Wann `--skip` sicher ist

### `references/git-safety.md`

Shared Safety-Regeln fuer alle Skills:

| Situation | Claude reagiert |
|---|---|
| Datei hat `<<<<<<<` Conflict-Marker | Blockiert, zeigt Stelle, fixt |
| Commit enthaelt `console.log` / `debugger` | Warnt, bietet Entfernung an |
| Push enthaelt unvollstaendige Features | Zeigt was fehlt, fragt ob gewollt |
| Branch ist >20 Commits behind main | Warnt: "Sync empfohlen" |
| Gleiche Datei in mehreren Topics | ⚡-Markierung, Hunk-Level Handling |
| Vergessener Stash existiert | Erinnert mit Datum |
| Letzter Commit ist Merge statt Rebase | Warnt |
| Force-Push noetig | Immer `--force-with-lease`, erklaert warum |
| Ungewoehnliche Git-History | Zeigt was los ist, fragt bevor weitergemacht wird |
| Secrets im Diff erkannt | Blockiert Push, zeigt Pattern |

Zusaetzlich:
- Nie `git add .` oder `git add -A`
- Nie `--force` ohne explizite User-Bestaetigung
- Nie ohne `git fetch` pushen
- Immer `--force-with-lease` statt `--force`
- Immer Commit-Messages zur Bestaetigung zeigen

### `references/branch-history.md`

Git-History zuverlaessig lesen (damit Claude nicht an Commit-IDs scheitert):
- `--oneline` fuer Ueberblick, `--stat` fuer Details
- `git log origin/main..origin/<branch>` fuer "was hat Branch gemacht seit main"
- `git log --all --oneline --graph --decorate -20` fuer visuellen Ueberblick
- `git shortlog -sn origin/main..origin/<branch>` fuer Commit-Verteilung
- Nie blind `git log` ohne Range — immer eingrenzen
- `git diff --stat origin/main..origin/<branch>` fuer Datei-Vergleich

---

## Branch-Erkennung

Generisch, keine Konvention erzwungen:
- **Main-Branch**: erkennt `main` oder `master` (was existiert)
- **Deine Branch**: die Branch auf der du gerade bist
- Optionale Config fuer Defaults, aber out-of-the-box funktioniert es

---

## Proaktivitaets-Prinzip

Alle Skills folgen dem gleichen Muster:
1. **Warnen** bevor was schiefgeht
2. **Konkreten Fix zeigen** mit Zeilennummer und Kontext
3. **Direkt fixen** was der User auswaehlt (per AskUserQuestion multiSelect)
4. **Nachfragen** bei Unsicherheit
5. **Nie still zerstoeren** — vor jedem destruktiven Schritt zeigen was passiert

---

## Skill-Frontmatter (nach Anthropic Skill-Creator Spec)

Jeder Skill hat:
- `name`: kebab-case, max 64 Zeichen
- `description`: max 1024 Zeichen, beschreibt wann der Skill triggern soll ("pushy" genug fuer zuverlaessiges Triggering)
- Body: SKILL.md unter 500 Zeilen, References fuer Details

---

## Nicht im Scope

- Branch-Cleanup / Branch-Loeschen (Teams arbeiten dauerhaft in eigenen Branches)
- Batch-Operationen ueber mehrere Repos (zu riskant ohne Einzelkontrolle)
- MCP-Server oder Helper-Scripts (pure Skills reichen, keine Dependencies)
- CI/CD Integration
- PR-Management (kann spaeter ergaenzt werden)
