# force-bun

> [English](./README.md) | 日本語

Bash tool 経由で `npm` / `npx` を打とうとしたとき、PreToolUse hook で介入して `bun` / `bunx` の使用を提案する Claude Code プラグイン。

## 解決する課題

Claude Code は `npm` / `npx` をデフォルトで使いがち。Bun の起動速度・モダンな機能を優先したい開発者向けに、これらを intercept して Bun に誘導する。

## 仕組み

`PreToolUse(Bash)` hook で Bash コマンドを覗き、`npm` / `npx` を検出したら exit 2 でブロックし、stderr に Bun 等価コマンドへの誘導メッセージを返す:

- `npx` / `npm x` / `npm exec` → `bunx`
- `npm install` / `npm run` ... → `bun install` / `bun run` ...

例外: `npm version` と `npm publish` は許可 (Bun に対応コマンドが無いため)。

### マッチ方式と既知の誤検知

`npm` / `npx` がコマンド位置 (行頭、または `&&` / `;` / `||` / `|` / `(` / `{` 直後) に現れたときのみマッチする。これにより `git commit -m fix && npm ci` のような連結コマンドを拾える (引用符以降を切り捨てる旧実装では見落としていた)。一方で `echo "run npm install first"` のような通常の引用文字列は誤検知しない。

残る誤検知は、引用文字列の **中にセパレータを含む** ケース (例: `echo "x && npm install"`)。これは意図的に許容する: 稀な引用内セパレータより、実際の連結コマンドの検出漏れ回避を優先する。万一正当なコマンドがブロックされたら、文字列を言い換えるか目的の Bun コマンドを直接実行すればよい。

hook 自体が失敗した場合 (`jq` 不在 / JSON 不正等) は fail-open (exit 0) で通過し、ユーザの作業を妨げない。

## インストール

```bash
/plugin marketplace add kawaz/claude-plugin-force-bun
/plugin install force-bun@force-bun
```

## 設定

設定不要。

## ライセンス

MIT
