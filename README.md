# bix — Claude Skills Marketplace

![bix](assets/Bix-Marketplace-Thumbnail-Edited.png)

[![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-D97757)](https://docs.claude.com/en/docs/claude-code/overview)
[![Version](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FIamBiswajitSahoo%2FClaudeSkills%2Fmain%2F.claude-plugin%2Fmarketplace.json&query=%24.metadata.version&label=version&color=blue)](https://github.com/IamBiswajitSahoo/ClaudeSkills/blob/main/VERSION)
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

## License

Apache 2.0 — see [LICENSE](LICENSE)
