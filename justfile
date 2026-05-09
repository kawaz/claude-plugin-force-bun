# Claude Code Plugin: force-bun

default:
    @just --list

# CI とローカルの検査範囲を完全一致させる単一エントリ
ci: lint validate check-versions check-translations

# shellcheck (hooks/ 配下の .sh を検査)
lint:
    shellcheck hooks/*.sh

# プラグイン manifest の検証
validate:
    claude plugin validate .

# バージョン表示
version:
    @jq -r '.version' .claude-plugin/plugin.json

# working copy が clean (未確定変更なし) であることを検証
# CI 環境 (git clone) では jj が無いので jj diff も実行されず、結果として clean 扱いになる
# (CI は clean な checkout が前提なので問題なし)
ensure-clean:
    @[ -z "$(jj diff --summary 2>/dev/null)" ] \
        || { echo "ERROR: working copy に未確定変更があります。describe してから push してください" >&2; exit 1; }

# plugin.json と marketplace.json の version 一致チェック
check-versions:
    @test "$(jq -r '.version' .claude-plugin/plugin.json)" = "$(jq -r '.metadata.version' .claude-plugin/marketplace.json)" \
        || { echo "ERROR: plugin.json と marketplace.json のバージョンが不一致です" >&2; exit 1; }

# 翻訳ペア (*-ja.md / *.md) の整合性チェック (~/.claude/rules/docs-structure.md テンプレ)
check-translations: ensure-clean
    #!/usr/bin/env bash
    set -euo pipefail
    die() { echo "$*" >&2; exit 1; }
    file_ts() {
        local f="$1"
        if [ -d .jj ]; then
            jj log --no-graph -T 'committer.timestamp().format("%s")' \
                -r "latest(::@ & files('$f'))" 2>/dev/null || echo 0
        else
            git log -1 --format=%ct -- "$f" 2>/dev/null || echo 0
        fi
    }
    while IFS= read -r ja; do
        en="${ja/-ja/}"
        [ -f "$en" ] || die "ERROR: $ja exists but $en is missing"
        head -5 "$ja" | grep -qF "> [English](./${en##*/}) | 日本語" \
            || die "ERROR: $ja: missing '> [English](./${en##*/}) | 日本語' link near the top"
        head -5 "$en" | grep -qF "> English | [日本語](./${ja##*/})" \
            || die "ERROR: $en: missing '> English | [日本語](./${ja##*/})' link near the top"
        ja_ts=$(file_ts "$ja")
        en_ts=$(file_ts "$en")
        [ "$ja_ts" -le "$en_ts" ] \
            || die "ERROR: $ja was updated after $en. Update the English translation before pushing."
    done < <(find . -name '*-ja.md' -not -path './.git/*' -not -path './.jj/*')

# version bump (kawaz/* 横断ルール、bump-semver multi-file + path-aware で 1 行)
bump-semver level="patch": ensure-clean ci
    bump-semver "{{level}}" .claude-plugin/plugin.json .claude-plugin/marketplace.json --write
    @echo "Version: -> $(bump-semver get .claude-plugin/plugin.json .claude-plugin/marketplace.json)"
    jj split -m "chore: bump version" .claude-plugin/plugin.json .claude-plugin/marketplace.json

# push (lint + validate + version 一致 + 翻訳整合性チェック後に @- を push)
push: ensure-clean ci
    jj bookmark set main -r @-
    jj git push --bookmark main

# version bump 不要な変更 (docs のみ等)
push-without-bump: ensure-clean ci
    jj bookmark set main -r @-
    jj git push --bookmark main
