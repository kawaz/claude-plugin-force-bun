# force-bun

> English | [日本語](./README-ja.md)

A Claude Code plugin that intercepts `npm` / `npx` invocations from the Bash tool via a PreToolUse hook and suggests using `bun` / `bunx` instead.

## Problem it solves

Claude Code often defaults to `npm` / `npx`. If you prefer Bun's startup speed and modern feature set, this plugin nudges Claude towards Bun-equivalent commands.

## How it works

The `PreToolUse(Bash)` hook inspects the command and blocks it (exit 2 + a stderr message suggesting the Bun-equivalent) when `npm` / `npx` is detected:

- `npx` / `npm x` / `npm exec` → `bunx`
- `npm install` / `npm run` ... → `bun install` / `bun run` ...

Exceptions: `npm version` and `npm publish` are allowed because Bun has no equivalent.

### Matching strategy and known false positives

The hook only matches `npm` / `npx` at a command position — line start or right after a separator (`&&`, `;`, `||`, `|`, `(`, `{`). This catches chained commands such as `git commit -m fix && npm ci` that an earlier quote-stripping approach missed, while keeping ordinary quoted text like `echo "run npm install first"` from triggering.

The remaining false positive is a separator **inside** a quoted string, e.g. `echo "x && npm install"`, which still trips the guard. This is accepted on purpose: avoiding missed detections of real chained commands is prioritized over these rare quoted-separator cases. If it ever blocks something legitimate, rephrase the string or run the intended Bun command directly.

If the hook itself fails (e.g. `jq` missing or malformed input), it fails open (exit 0) and never blocks your work.

## Installation

```bash
/plugin marketplace add kawaz/claude-plugin-force-bun
/plugin install force-bun@force-bun
```

## Configuration

No configuration required.

## License

MIT
