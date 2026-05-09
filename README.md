# force-bun

> English | [日本語](./README-ja.md)

A Claude Code plugin that intercepts `npm` / `npx` invocations from the Bash tool via a PreToolUse hook and suggests using `bun` / `bunx` instead.

## Problem it solves

Claude Code often defaults to `npm` / `npx`. If you prefer Bun's startup speed and modern feature set, this plugin nudges Claude towards Bun-equivalent commands.

## How it works

The `PreToolUse(Bash)` hook inspects the command and returns `permissionDecision: deny` with a suggested replacement when `npm` / `npx` is detected:

- `npx` / `npm x` / `npm exec` → `bunx`
- `npm install` / `npm run` ... → `bun install` / `bun run` ...

Exceptions: `npm version` and `npm publish` are allowed because Bun has no equivalent.

## Installation

```bash
/plugin marketplace add kawaz/claude-plugin-force-bun
/plugin install force-bun@force-bun
```

## Configuration

No configuration required.

## License

MIT
