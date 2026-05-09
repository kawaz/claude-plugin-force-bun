# force-bun

> [English](./README.md) | 日本語

Bash tool 経由で `npm` / `npx` を打とうとしたとき、PreToolUse hook で介入して `bun` / `bunx` の使用を提案する Claude Code プラグイン。

## 解決する課題

Claude Code は `npm` / `npx` をデフォルトで使いがち。Bun の起動速度・モダンな機能を優先したい開発者向けに、これらを intercept して Bun に誘導する。

## 仕組み

`PreToolUse(Bash)` hook で Bash コマンドを覗き、`npm` / `npx` を含む場合は `permissionDecision: deny` + 推奨置換を返す:

- `npx` / `npm x` / `npm exec` → `bunx`
- `npm install` / `npm run` ... → `bun install` / `bun run` ...

例外: `npm version` と `npm publish` は許可 (Bun に対応コマンドが無いため)。

## インストール

```bash
/plugin marketplace add kawaz/claude-plugin-force-bun
/plugin install force-bun@force-bun
```

## 設定

設定不要。

## ライセンス

MIT
