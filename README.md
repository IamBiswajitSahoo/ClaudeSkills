# bix — Claude Skills Marketplace

![bix](assets/Bix-Marketplace-Thumbnail-Edited.png)

A collection of useful Claude Code skills, distributed as a plugin marketplace.

## Installation

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix@Biswajit-Claude-Skills
```

Once installed, skills can be invoked in two ways:
- By skill name: `/audit`, `/cleanup`, `/github-pr-review` (shows as `(bix)` in autocomplete)
- By full prefix: `/bix:audit`, `/bix:cleanup`, `/bix:github-pr-review`

## Available Skills

### GitHub

| Skill | Command | Description | Docs |
| ----- | ------- | ----------- | ---- |
| github-pr-review | `/github-pr-review` | Review a PR with severity-labeled findings, parallel agent support, and per-comment approval | [Docs →](docs/github-pr-review/README.md) |
| github-pr-describe | `/github-pr-describe` | Generate a well-structured PR description by analyzing the diff, then push it to GitHub | [Docs →](docs/github-pr-describe/README.md) |
| github-pr-resolve | `/github-pr-resolve` | Evaluate and triage review comments on a PR, then implement agreed fixes | [Docs →](docs/github-pr-resolve/README.md) |

### Security

| Skill | Command | Description | Docs |
| ----- | ------- | ----------- | ---- |
| audit | `/audit` | Security audit for skills, MCP servers, hooks, and CLAUDE.md — fast pattern scan with parallel deep-analysis agents | [Docs →](docs/audit/README.md) |

### Session Management

| Skill | Command | Description | Docs |
| ----- | ------- | ----------- | ---- |
| load-session | `/load-session` | Load context from a previous session into the current one — browse, summarize, or load full transcript | [Docs →](docs/load-session/README.md) |

### Utilities

| Skill | Command | Description | Docs |
| ----- | ------- | ----------- | ---- |
| cleanup | `/cleanup` | Scan and clean up Claude Code's internal data (`~/.claude/`) to reclaim disk space | [Docs →](docs/cleanup/README.md) |

## License

Apache 2.0 — see [LICENSE](LICENSE)

---

> *What does **bix** stand for? **B**iswajit's **I**ntelligent e**X**tensions* :)
