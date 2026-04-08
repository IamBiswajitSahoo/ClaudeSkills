# /bix-utils:cleanup

Scan and clean up Claude Code's internal data (`~/.claude/`) to reclaim disk space.

## Installation

First, add the marketplace and install the `bix-utils` plugin:

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-utils@Biswajit-Claude-Skills
```

## Usage

| Command | Behavior |
|---------|----------|
| `/bix-utils:cleanup` | Scans `~/.claude/`, shows size table, lets you pick which directories to clean |
| `/bix-utils:cleanup -all` | Auto-selects all safe-to-delete directories, asks for confirmation |

## Features

- Cross-platform support (macOS, Linux, WSL, Windows)
- Detects and preserves active sessions (by PID) while cleaning stale transcripts
- Classification reconciled with the official [`~/.claude/` docs](https://code.claude.com/docs/en/claude-directory) — protects all user-owned items: `skills/`, `agents/`, `commands/`, `output-styles/`, `rules/`, `memory/`, `scripts/`, `ide/`, `plugins/`, plus `settings*.json`, `credentials.json`, `keybindings.json`, `CLAUDE.md`, `MEMORY.md`, `.claude.json`, `.mcp.json`
- Size table includes **Reclaimable total** and **~/.claude/ total** footer rows for at-a-glance accounting
- Shows before/after comparison of disk usage after deletion

## Demo

![Cleanup command full usage](assets/Cleanup-Usage-1.png)
