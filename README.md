# bix — Claude Skills Marketplace

A collection of useful Claude Code skills, distributed as a plugin marketplace.

## Installation

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix@Biswajit-Claude-Skills
```

Once installed, all skills are available under the `/bix:` prefix.

## Available Skills

### /bix:cleanup

Scan and clean up Claude Code's internal data (`~/.claude/`) to reclaim disk space.

> [Full documentation, installation steps, and demo screenshot](docs/cleanup/README.md)

| Command | Behavior |
|---------|----------|
| `/bix:cleanup` | Scans `~/.claude/`, shows size table, lets you pick directories to clean |
| `/bix:cleanup -all` | Auto-selects all safe-to-delete directories, asks for confirmation |

## Repository Structure

```
ClaudeSkills/
├── .claude-plugin/
│   └── marketplace.json           # Marketplace catalog
├── plugins/
│   └── bix/                       # The bix plugin (installed by users)
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── cleanup/
│               ├── SKILL.md
│               └── scripts/
│                   └── scan.sh
├── docs/                          # Documentation only (not installed)
│   └── cleanup/
│       ├── README.md
│       └── assets/
└── README.md
```

## Adding Skills

To add a new skill to the `bix` plugin:

1. Create a new directory under `plugins/bix/skills/<skill-name>/`
2. Add a `SKILL.md` with frontmatter and instructions
3. Add documentation under `docs/<skill-name>/`
4. Update this README

## License

MIT

---

> *What does **bix** stand for? **B**iswajit's **I**ntelligent e**X**tensions* :)
