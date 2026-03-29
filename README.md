# bix — Claude Skills Marketplace

![bix](assets/Bix-Marketplace-Thumbnail-Edited.png)

A collection of useful Claude Code skills, distributed as a plugin marketplace.

## Installation

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix@Biswajit-Claude-Skills
```

Once installed, all skills are available under the `/bix:` prefix.

## Available Skills

### GitHub

| Skill | Description | Docs |
| ----- | ----------- | ---- |
| `/bix:github-pr-review` | Review a PR with severity-labeled findings, parallel agent support, and per-comment approval | [Docs →](docs/github-pr-review/README.md) |
| `/bix:github-pr-describe` | Generate a well-structured PR description by analyzing the diff, then push it to GitHub | [Docs →](docs/github-pr-describe/README.md) |
| `/bix:github-pr-resolve` | Evaluate and triage review comments on a PR, then implement agreed fixes | [Docs →](docs/github-pr-resolve/README.md) |

### Security

| Skill | Description | Docs |
| ----- | ----------- | ---- |
| `/bix:audit` | Security audit for skills, MCP servers, hooks, and CLAUDE.md — fast pattern scan with parallel deep-analysis agents | [Docs →](docs/audit/README.md) |

### Utilities

| Skill | Description | Docs |
| ----- | ----------- | ---- |
| `/bix:cleanup` | Scan and clean up Claude Code's internal data (`~/.claude/`) to reclaim disk space | [Docs →](docs/cleanup/README.md) |

## License

Apache 2.0 — see [LICENSE](LICENSE)

---

> *What does **bix** stand for? **B**iswajit's **I**ntelligent e**X**tensions* :)
