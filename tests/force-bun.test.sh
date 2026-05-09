#!/usr/bin/env bash
# force-bun.sh をドライランで検証。JSON で食わせ、exit code を確認する。
# block (exit=2) / pass (exit=0) / fail-open (exit=0) を網羅。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/force-bun.sh"
export CLAUDE_PLUGIN_ROOT="$REPO_ROOT"

[ -x "$HOOK" ] || { echo "FAIL: $HOOK not found or not executable" >&2; exit 1; }

fail=0

# usage: assert_case <label> <expected_exit> <json_command>
assert_case() {
  local label="$1"; shift
  local expected="$1"; shift
  local input="$1"; shift
  local actual
  actual=$(printf '%s' "$input" | "$HOOK" >/dev/null 2>&1; echo $?)
  actual=$(echo "$actual" | tail -1)
  if [ "$actual" = "$expected" ]; then
    printf 'PASS  %-55s (exit=%s)\n' "$label" "$actual"
  else
    printf 'FAIL  %-55s expected=%s actual=%s\n' "$label" "$expected" "$actual" >&2
    fail=$((fail+1))
  fi
}

# ---- block (exit=2): npm ----
assert_case "npm install"                       2 '{"tool_input":{"command":"npm install"}}'
assert_case "npm run build"                      2 '{"tool_input":{"command":"npm run build"}}'
assert_case "npm i lodash"                        2 '{"tool_input":{"command":"npm i lodash"}}'
assert_case "npm ci after && (連結検出)"           2 '{"tool_input":{"command":"git commit -m fix && npm ci"}}'
assert_case "npm after ; (連結検出)"               2 '{"tool_input":{"command":"cd app; npm install"}}'
assert_case "npm after | (pipe)"                  2 '{"tool_input":{"command":"echo y | npm install"}}'
assert_case "npm inside subshell ("              2 '{"tool_input":{"command":"(npm install)"}}'

# ---- block (exit=2): npx / npm x / npm exec ----
assert_case "npx create-foo"                      2 '{"tool_input":{"command":"npx create-foo"}}'
assert_case "npm x foo"                            2 '{"tool_input":{"command":"npm x foo"}}'
assert_case "npm exec foo"                         2 '{"tool_input":{"command":"npm exec foo"}}'

# ---- pass (exit=0): allowed npm subcommands ----
assert_case "npm version patch (許可)"            0 '{"tool_input":{"command":"npm version patch"}}'
assert_case "npm publish (許可)"                   0 '{"tool_input":{"command":"npm publish"}}'

# ---- pass (exit=0): unrelated / bun ----
assert_case "bun install"                          0 '{"tool_input":{"command":"bun install"}}'
assert_case "bunx foo"                             0 '{"tool_input":{"command":"bunx foo"}}'
assert_case "echo with npm substring word"         0 '{"tool_input":{"command":"echo running tests"}}'
# npm が単語先頭でなく別語の一部 (npmrc 等) は対象外
assert_case "cat .npmrc (npmrc は別語)"            0 '{"tool_input":{"command":"cat .npmrc"}}'

# ---- false positive 境界 ----
# 位置アンカー方式なので、引用文字列内でも先頭がセパレータ直後でなければ pass する。
assert_case "引用文字列内 npm (mid-string は pass)"  0 '{"tool_input":{"command":"echo \"run npm install first\""}}'
# ただし引用文字列内にセパレータ (&&/;/|) を含むと誤検知し得る (検出漏れ回避優先, README 明記)。
assert_case "引用内 separator+npm は誤検知 (許容)"   2 '{"tool_input":{"command":"echo \"x && npm install\""}}'

# ---- edge: empty / malformed input は fail-open (exit=0) ----
assert_case "empty stdin"                          0 ''
assert_case "no tool_input.command"                0 '{"tool_input":{}}'
assert_case "malformed json (fail-open)"           0 '{not-json'

if [ "$fail" -gt 0 ]; then
  echo "" >&2
  echo "FAILED: $fail case(s)" >&2
  exit 1
fi

echo ""
echo "All cases passed."
