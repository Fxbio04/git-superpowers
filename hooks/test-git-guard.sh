#!/bin/bash
# Regression tests for git-guard.sh — run locally or in CI: bash hooks/test-git-guard.sh
set -u
GUARD="$(cd "$(dirname "$0")" && pwd)/git-guard.sh"
PASS=0; FAIL=0

check() { # check <expected-exit> <command-json-string> <label>
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$2" | bash "$GUARD" >/dev/null 2>&1
  local got=$?
  if [ "$got" -eq "$1" ]; then PASS=$((PASS+1));
  else FAIL=$((FAIL+1)); echo "FAIL ($3): expected exit $1, got $got — $2"; fi
}

# Must BLOCK (exit 2)
check 2 '"git add ."'                                            "add-dot"
check 2 '"git add -A"'                                           "add-A"
check 2 '"git add --all"'                                        "add-all"
check 2 '"git commit --no-verify -m x"'                          "no-verify"
check 2 '"git push --force origin fb"'                           "bare-force"
check 2 '"git push -f"'                                          "short-force"
check 2 '"git push --force-with-lease origin main"'              "lease-to-main"
check 2 '"git push -f origin master"'                            "force-to-master"
check 2 '"git push --force origin HEAD:release/1.2"'             "refspec-release"
check 2 '"git status && git push --force origin fb"'             "chained-force"

# Must ALLOW (exit 0)
check 0 '"git add ./src/file.ts"'                                "add-explicit-dotslash"
check 0 '"git add src/a.ts src/b.ts"'                            "add-files"
check 0 '"git push --force-with-lease origin fb"'                "lease-feature"
check 0 '"git push --force-with-lease --force-if-includes origin fb"' "lease-includes"
check 0 '"git push origin main"'                                 "plain-push-main"
check 0 '"git checkout main; git pull"'                          "checkout-main"
check 0 '"git commit -m \"fix --no-verify docs\""'               "no-verify-in-message"
check 0 '"legit push --force"'                                   "legit-not-git"
check 0 '"npm run build"'                                        "non-git"
check 0 '"git log --oneline"'                                    "read-only"

# Heredoc body quoting banned commands must not trigger
printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"$(cat <<'"'"'EOF'"'"'\ndocs: explain why git add . is banned\n\nAlso covers git push --force origin main.\nEOF\n)\""}}' \
  | bash "$GUARD" >/dev/null 2>&1
if [ $? -eq 0 ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL (heredoc-quoted)"; fi

# Malformed input must fail open
printf 'not json' | bash "$GUARD" >/dev/null 2>&1
if [ $? -eq 0 ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL (malformed-input)"; fi

echo "git-guard tests: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
