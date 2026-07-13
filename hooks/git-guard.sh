#!/bin/bash
# git-guard — PreToolUse hook for the Bash tool.
#
# Deterministically blocks the git patterns that the git-superpowers safety
# rules forbid, so safety does not depend on the model remembering prose:
#
#   1. git add . / -A / --all          → stage specific files instead
#   2. --no-verify on commit/push      → never bypass hooks
#   3. git push --force / -f           → use --force-with-lease --force-if-includes
#   4. any force push to a protected branch (main, master, develop, dev,
#      staging, production, release/*) → refuse entirely
#
# Blocking = exit 2 with the reason on stderr (shown to Claude, which adjusts).
# Anything unparseable fails OPEN (exit 0) — a broken guard must never break
# the session. Escape hatch for deliberate exceptions, run by the USER only:
#   GIT_SUPERPOWERS_UNSAFE=1 <command>
#
# Known limits (by design — a regex is not a shell parser): commands built via
# variables/aliases/xargs are not caught. The guard is a seatbelt, not a jail.

set -u

[ "${GIT_SUPERPOWERS_UNSAFE:-0}" = "1" ] && exit 0

INPUT=$(cat 2>/dev/null) || exit 0
[ -z "$INPUT" ] && exit 0

# Extract .tool_input.command from the hook JSON. jq first, python3 fallback.
if command -v jq >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
elif command -v python3 >/dev/null 2>&1; then
  CMD=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass' 2>/dev/null) || exit 0
else
  exit 0
fi

[ -z "$CMD" ] && exit 0
case "$CMD" in *git*) ;; *) exit 0 ;; esac

PROTECTED='main|master|develop|dev|staging|production|release(/[^ ]*)?'

block() {
  echo "git-guard blocked this command: $1" >&2
  echo "Rule source: git-superpowers references/git-safety.md — $2" >&2
  exit 2
}

# Evaluate each command in a chain separately (split on ;, &&, ||, |).
# Before matching, drop content that is data, not command: heredoc bodies
# (commit messages quoting git commands must not trigger the guard) and
# quoted strings. awk, not sed: BSD sed treats \n in replacements as 'n'.
printf '%s\n' "$CMD" | awk '
  # skip heredoc bodies: <<EOF / <<-EOF / <<"EOF" / <<'\''EOF'\''
  skip { if ($0 == delim) skip = 0; next }
  match($0, /<<-? *["'\'']?[A-Za-z_][A-Za-z0-9_]*["'\'']?/) {
    delim = substr($0, RSTART, RLENGTH)
    sub(/<<-? */, "", delim); gsub(/["'\'']/, "", delim)
    skip = 1
  }
  { gsub(/&&|\|\||;|\|/, "\n"); print }
' | while IFS= read -r SUB; do
  # strip quoted strings (arguments, messages), then normalize whitespace
  SUB=$(printf '%s' "$SUB" | sed -E "s/\"[^\"]*\"/QUOTED/g; s/'[^']*'/QUOTED/g" | tr '\t' ' ' | sed -E 's/  +/ /g; s/^ //; s/ $//')
  case "$SUB" in *git\ *|git\ *|*git) ;; *) continue ;; esac

  # 1. git add . / -A / --all  (exact args only — "git add ./src/x.ts" is fine)
  if printf '%s' "$SUB" | grep -Eq '(^|[ ;])git +add +([^ ]+ +)*(-A|--all|\.)( |$)'; then
    block "'git add .' / 'git add -A' stages everything blindly." \
          "always stage specific files: git add <file> <file>"
  fi

  # 2. --no-verify on any git command
  if printf '%s' "$SUB" | grep -Eq '(^|[ ;])git .*--no-verify( |$)'; then
    block "'--no-verify' bypasses the repo's hooks." \
          "fix the hook failure instead; only the user may bypass hooks manually"
  fi

  # Force-push checks
  if printf '%s' "$SUB" | grep -Eq '(^|[ ;])git +push( |$| )'; then
    HAS_BARE_FORCE=false
    HAS_LEASE=false
    printf '%s' "$SUB" | grep -Eq -- '(^| )(--force|-f)( |$)' && HAS_BARE_FORCE=true
    printf '%s' "$SUB" | grep -Eq -- '(^| )--force-with-lease' && HAS_LEASE=true

    # 3. bare --force / -f without lease
    if $HAS_BARE_FORCE && ! $HAS_LEASE; then
      block "bare 'git push --force' can overwrite teammates' work." \
            "use: git push --force-with-lease --force-if-includes"
    fi

    # 4. ANY force variant targeting a protected branch (positional or refspec)
    if $HAS_BARE_FORCE || $HAS_LEASE; then
      if printf '%s' "$SUB" | grep -Eq -- "(^| )($PROTECTED)( |$)|(^| )[^ ]*:($PROTECTED)( |$)"; then
        block "force-pushing a protected branch (main/master/develop/staging/production/release/*)." \
              "protected branches are never rewritten; use git revert instead"
      fi
    fi
  fi
done

# The while-loop runs in a subshell; propagate its exit code.
exit $?
