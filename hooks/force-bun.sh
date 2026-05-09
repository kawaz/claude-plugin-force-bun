#!/bin/bash
set -euo pipefail

suggest_deny() {
    local reason="$1"
    jq -cn \
        --arg reason "$reason" \
        '{
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": $reason
            }
        }'
    exit 1
}

# 標準入力から JSON を読み取り
input=$(</dev/stdin)
# コマンドチェックの際に複数行がある場合は最初の行のみを使用
command=$(jq -r '.tool_input.command // empty' <<< "$input")

# 引用符以降は無視する（コミットメッセージとかのコメント文字列に含む場合などの誤検知回避のため）
command=${command%%[\'\"]*}

# コマンドが空の場合は何もチェックしない
[[ -z "$command" ]] && exit 0

# コマンド区切りパターン（行頭 or シェル区切り文字の後）
CMD_PREFIX='(^|[|&;({][[:space:]]*)'

# Bun に置き換えを推奨
if [[ $command =~ ${CMD_PREFIX}(npx|npm\ x|npm\ exec)([[:space:]]|$) ]]; then
    suggest_deny "Use 'bunx' instead of npx, npm x, or npm exec"
fi

# npm version と npm publish は許可（bun に代替機能がないため）
if [[ $command =~ ${CMD_PREFIX}npm\ (version|publish) ]]; then
    exit 0
fi

# その他の npm コマンドは Bun を推奨
if [[ $command =~ ${CMD_PREFIX}npm([[:space:]]|$) ]]; then
    suggest_deny "Use 'bun' instead of npm"
fi

exit 0
