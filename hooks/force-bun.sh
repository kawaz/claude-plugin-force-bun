#!/bin/bash
# PreToolUse(Bash) hook: npm / npx を直接実行させず、bun / bunx へ誘導する。
#
# Claude Code は Bash ツールの `command` 引数をそのまま `bash -c` に流す。
# npm / npx の起動を検出したら exit 2 でブロックし、stderr に bun/bunx への
# 置換案を返す。行頭またはコマンドセパレータ (`&&` / `;` / `||` / `|` / `(` /
# `{`) 直後に現れたケースのみ対象とし、`git commit -m "... npm ..."` のように
# 後続コマンドへ連結された npm も拾う (引用符以降を切り捨てる旧実装はやめた)。
#
# NOTE: `set -e` は使わない。フック自体の不具合 (jq 不在、JSON 不正等) は
# 通過 (exit 0) させて、ユーザの作業を巻き込まないこと。

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$command" ] || exit 0

# コマンド位置アンカー: 行頭 / `&&` / `;` / `||` / `|` / `(` / `{` 直後。
# heredoc やシングルクォート内の文字列リテラルは誤検知し得るが、検出漏れ回避を
# 優先する (echo "npm install と書く" のような引用文字列内マッチは許容、README 参照)。
anchor='(^|&&|[|;({])\s*'

# npm version / npm publish は許可 (bun に対応コマンドが無いため) → 先に通す
if printf '%s' "$command" | grep -qE "${anchor}npm\s+(version|publish)\b"; then
  exit 0
fi

# npx / npm x / npm exec → bunx
if printf '%s' "$command" | grep -qE "${anchor}(npx|npm\s+(x|exec))\b"; then
  cat >&2 <<'EOF'
BLOCK: `npx` / `npm x` / `npm exec` は直接実行できません。

代わりに `bunx` を使ってください:

  bunx <package> ...
EOF
  exit 2
fi

# その他の npm → bun
if printf '%s' "$command" | grep -qE "${anchor}npm\b"; then
  cat >&2 <<'EOF'
BLOCK: `npm` は直接実行できません。

代わりに `bun` を使ってください (例: `npm install` → `bun install`、`npm run` → `bun run`)。

例外として `npm version` / `npm publish` は許可されています (bun に対応コマンドが無いため)。
EOF
  exit 2
fi

exit 0
