# bix — Claude Skills Marketplace

![bix](assets/Bix-Marketplace-Thumbnail-Edited.png)

[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-D97757)](https://docs.claude.com/en/docs/claude-code/overview)
[![Version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FIamBiswajitSahoo%2FClaudeSkills%2Fmain%2F.claude-plugin%2Fmarketplace.json&query=%24.metadata.version&label=version&color=blue)](https://github.com/IamBiswajitSahoo/ClaudeSkills/blob/main/VERSION)
[![macOS](https://img.shields.io/badge/macOS-supported-brightgreen?logo=apple&logoColor=white)](#os-support)
[![Linux](https://img.shields.io/badge/Linux-supported-brightgreen?logo=linux&logoColor=white)](#os-support)
[![WSL](https://img.shields.io/badge/WSL-supported-brightgreen?logo=windows&logoColor=white)](#os-support)
[![Windows](https://img.shields.io/badge/Windows-Git%20Bash%20%2F%20MSYS2-yellow?logo=windows&logoColor=white)](#os-support)
[![Stars](https://img.shields.io/github/stars/IamBiswajitSahoo/ClaudeSkills?style=social)](https://github.com/IamBiswajitSahoo/ClaudeSkills/stargazers)

A collection of useful Claude Code skills, distributed as a plugin marketplace.

## Installation

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-github@Biswajit-Claude-Skills
/plugin install bix-session@Biswajit-Claude-Skills
/plugin install bix-utils@Biswajit-Claude-Skills
```

Install only the plugins you need. Once installed, skills can be invoked by name (e.g. `/audit`, `/github-pr-review`, `/load-session`, `/rewrite`) or by full prefix (e.g. `/bix-utils:audit`, `/bix-github:github-pr-review`, `/bix-session:load-session`).

## Available Skills

### bix-github

| Skill | Command | Description | Docs |
| ----- | ------- | ----------- | ---- |
| github-pr-review | `/github-pr-review` | Review a PR with severity-labeled findings, parallel agent support, and per-comment approval | [Docs →](docs/github-pr-review/README.md) |
| github-pr-describe | `/github-pr-describe` | Generate a well-structured PR description by analyzing the diff, then push it to GitHub | [Docs →](docs/github-pr-describe/README.md) |
| github-pr-resolve | `/github-pr-resolve` | Evaluate and triage review comments on a PR, then implement agreed fixes | [Docs →](docs/github-pr-resolve/README.md) |

### bix-session

| Skill | Command | Description | Docs |
| ----- | ------- | ----------- | ---- |
| load-session | `/load-session` | Load context from a previous session into the current one — browse, summarize, or load full transcript | [Docs →](docs/load-session/README.md) |

### bix-utils

| Skill | Command | Description | Docs |
| ----- | ------- | ----------- | ---- |
| audit | `/audit` | Security audit for skills, MCP servers, hooks, and CLAUDE.md — fast pattern scan with parallel deep-analysis agents | [Docs →](docs/audit/README.md) |
| cleanup | `/cleanup` | Scan and clean up Claude Code's internal data (`~/.claude/`) to reclaim disk space | [Docs →](docs/cleanup/README.md) |
| rewrite | `/rewrite` | Rewrite prompts using 12 curated prompt engineering frameworks (RISEN, TIDD-EC, CO-STAR, etc.) via a fast haiku sub-agent | [Docs →](docs/rewrite/README.md) |

## OS Support

All skills run on **macOS**, **Linux**, and **WSL**. On **Windows native**, support depends on the script runtime:

| Plugin | Script runtime | macOS | Linux | WSL | Windows native |
| ------ | -------------- | :---: | :---: | :-: | :------------: |
| bix-github | bash + `gh` CLI | ✅ | ✅ | ✅ | Git Bash / MSYS2 |
| bix-session | Python (stdlib) + bash cleanup hook | ✅ | ✅ | ✅ | Git Bash / MSYS2 |
| bix-utils → audit | Python (stdlib) | ✅ | ✅ | ✅ | ✅ |
| bix-utils → rewrite | Pure prompt (no scripts) | ✅ | ✅ | ✅ | ✅ |
| bix-utils → cleanup | bash (cross-platform `OSTYPE` branches) | ✅ | ✅ | ✅ | Git Bash / MSYS2 / Cygwin |

Claude Code on Windows already ships a POSIX shell environment, so the bash-based skills work out of the box there.

## License

Apache 2.0 — see [LICENSE](LICENSE)
