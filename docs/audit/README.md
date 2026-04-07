# /audit

> Also available as `/bix-utils:audit`

Security audit for Claude Code extension surfaces — skills, MCP servers, hooks, and CLAUDE.md files. Runs a fast regex-based pattern scan first, then spawns parallel deep-analysis agents for semantic review.

## Installation

First, add the marketplace and install the `bix-utils` plugin:

```bash
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-utils@Biswajit-Claude-Skills
```

## Usage

| Command | Behavior |
| ------- | -------- |
| `/audit skill ./path/to/skill` | Audit a local skill directory |
| `/audit skill https://github.com/user/repo` | Download and audit a skill from GitHub |
| `/audit skill https://github.com/user/repo/tree/main/skills/foo` | Audit a specific subdirectory in a GitHub repo |
| `/audit mcp` | Audit all configured MCP servers |
| `/audit mcp my-server` | Audit a specific configured MCP server |
| `/audit mcp @scope/package` | Download and audit an npm MCP server package |
| `/audit mcp https://github.com/user/mcp-server` | Download and audit an MCP server from GitHub |
| `/audit hooks` | Audit hooks in settings.json |
| `/audit claudemd` | Audit CLAUDE.md files for prompt injection |
| `/audit all` | Run all audits on current environment |
| `/audit` | Interactive mode — prompts for what to audit |

### Target Formats

The `skill` and `mcp` modes accept multiple target formats so you can audit **before downloading or installing**:

| Format | Example | What Happens |
| ------ | ------- | ------------ |
| Local path | `./my-skill` or `/abs/path` | Audits files directly on disk |
| GitHub repo URL | `https://github.com/user/repo` | Shallow-clones the repo to a temp dir, audits, cleans up |
| GitHub subdirectory | `https://github.com/user/repo/tree/main/path` | Clones the repo, audits only the specified subdirectory |
| npm package (mcp only) | `@scope/mcp-server` | Downloads via `npm pack` (no scripts executed), audits, cleans up |

## Architecture

The skill uses a **progressive disclosure** design to minimize token usage and give the user control over depth:

```
┌─────────────────────────────────────────────────────────┐
│ Phase 1: Parse & Route                                  │
│   Parse mode (skill / mcp / hooks / claudemd / all)     │
│   Validate target path or config existence              │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 2: Quick Scan (fast, no LLM tokens)               │
│   Python scripts run regex patterns → instant results   │
│   Display risk score + top findings                     │
└──────────────────────────┬──────────────────────────────┘
                           ▼
                   ┌───────────────┐
                   │ User decides  │
                   │ Deep scan?    │
                   │ Show details? │
                   │ Done?         │
                   └───────┬───────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 3: Deep Analysis (parallel sub-agents)            │
│                                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐   │
│  │  Skill   │ │   MCP    │ │  Hooks   │ │ CLAUDE.md │   │
│  │  Agent   │ │  Agent   │ │  Agent   │ │   Agent   │   │
│  │ (sonnet) │ │ (sonnet) │ │ (sonnet) │ │  (sonnet) │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └─────┬─────┘   │
│       └─────────────┴───────────┴──────────────┘        │
│                         ▼                               │
│              Merge & deduplicate findings               │
└──────────────────────────┬──────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────┐
│ Phase 4: Report                                         │
│   Combined risk score, findings by severity,            │
│   clean items, prioritized recommendations              │
└─────────────────────────────────────────────────────────┘
```

## Token Efficiency

The skill is designed to be cost-effective even for large audit targets:

- **Quick scan uses zero LLM tokens** — Python scripts run regex pattern matching locally, giving instant results without invoking the model
- **Deep analysis is opt-in** — the user sees quick results first and decides whether to go deeper, avoiding unnecessary token spend on clean targets
- **Sub-agents use Sonnet** — deep analysis agents run on the `sonnet` model for faster, cheaper inference
- **Focused agent context** — each sub-agent receives only the data relevant to its surface (skill files, MCP configs, hooks, or CLAUDE.md), not the entire audit context
- **Parallel execution** — in `all` mode, up to 4 agents run simultaneously rather than sequentially, reducing wall-clock time
- **Early termination** — if the quick scan verdict is SAFE, the user can stop without spawning any agents

## Features

- **Two-phase architecture** — fast pattern scan (seconds) then optional deep analysis (parallel agents)
- **Progressive disclosure** — see quick results immediately, drill into deep analysis only if needed
- **4 audit surfaces** in one tool:

  - **Skills** — prompt injection, credential theft, malicious payloads, obfuscation, supply chain
  - **MCP servers** — server identity, command analysis, env var exposure, permission scope
  - **Hooks** — command safety, trigger scope, data flow, global vs. project scope
  - **CLAUDE.md** — instruction hijacking, hidden instructions, data exfiltration setup

- **Risk scoring** — 0-100 scale with verdicts: SAFE, CAUTION, SUSPICIOUS, DANGEROUS, MALICIOUS
- **Parallel sub-agents** — deep analysis runs as focused agents in parallel to save time and tokens
- **39 detection patterns** — covering prompt injection, credential theft, reverse shells, obfuscation, supply chain attacks, and more

## Audit Modes

### Skill Audit (`/bix-utils:audit skill <path>`)

Audits a skill directory before installation. Checks:

- SKILL.md for prompt injection and hidden instructions
- Script files for malicious payloads and obfuscated code
- File inventory for unexpected binaries or executables
- Frontmatter for overly permissive tool access
- URLs and env var references for data exfiltration

### MCP Server Audit (`/bix-utils:audit mcp`)

Audits configured MCP server definitions. Checks:

- Server identity and package trust (typosquatting, unknown publishers)
- Command and argument analysis (suspicious flags, inline scripts)
- Environment variables passed to servers (hardcoded secrets, unnecessary exposure)
- Permission scope (overly broad filesystem/API access)
- Tool description injection vectors

### Hooks Audit (`/bix-utils:audit hooks`)

Audits Claude Code hooks in settings.json. Checks:

- Command safety (network calls, file modifications, eval usage)
- Trigger scope (wildcard matchers, high-frequency events)
- Data flow (can the hook capture and exfiltrate tool I/O?)
- Scope risk (global hooks have higher blast radius than project hooks)

### CLAUDE.md Audit (`/bix-utils:audit claudemd`)

Audits CLAUDE.md files for prompt injection. Checks:

- Instruction hijacking (disabling confirmations, skipping security checks)
- Hidden instructions (HTML comments, Unicode tricks, formatting exploits)
- Data exfiltration setup (instructions to embed secrets in outputs)
- Tool behavior overrides (changing how Claude uses specific tools)

## Risk Score

| Score | Verdict    | Meaning                                                  |
| ----- | ---------- | -------------------------------------------------------- |
| 0-20  | SAFE       | No significant security concerns                         |
| 21-40 | CAUTION    | Minor concerns, proceed with awareness                   |
| 41-60 | SUSPICIOUS | Multiple red flags, manual review recommended            |
| 61-80 | DANGEROUS  | Serious concerns, do NOT use without expert review       |
| 81-100| MALICIOUS  | Strong indicators of malicious intent, AVOID             |

## Detection Categories

| Category          | Patterns | Examples                                                                       |
| ----------------- | -------- | ------------------------------------------------------------------------------ |
| Prompt Injection   | 8        | Instruction override, role reassignment, Unicode tricks, conditional triggers  |
| Credential Theft   | 8        | SSH keys, AWS creds, API keys, env var exfiltration, wallet access             |
| Malicious Payloads | 6        | Reverse shells, curl-pipe-to-shell, destructive ops, download-and-execute      |
| Obfuscation        | 4        | Base64 strings, hex payloads, dynamic eval, encoded execution                  |
| Supply Chain       | 3        | Postinstall scripts, registry overrides, git credential manipulation           |
| Network            | 4        | IP literal connections, exfiltration patterns, encoded URLs, external domains   |
| Structural         | 3        | Excessive tool permissions, unrestricted bash, file write access               |
| Informational      | 3        | Env var reads, path traversal, subprocess spawning                             |

## Scripts

Scripts the skill executes on your machine. Provided for transparency — since this is a security tool, you should be able to verify exactly what it does. All are pure Python 3 (standard library only) and read-only against your filesystem except `resolve-target.py`, which writes to a temp dir when fetching remote audit targets.

| Script | Purpose | Tools / Calls | Network | Writes |
|---|---|---|---|---|
| `scripts/pattern-scan.py` | Regex-scan a directory for known malicious patterns; emit JSON findings + risk score | `os.walk`, `open`, `re` (stdlib only) | None | stdout only |
| `scripts/gather-skill-inventory.py` | Walk a skill dir, parse SKILL.md frontmatter, list files, flag binaries/scripts/URLs | `os.walk`, `open`, `re` (stdlib only) | None | stdout only |
| `scripts/gather-mcp-config.py` | Read configured MCP servers from Claude Code settings files; emit JSON | `open` on `~/.claude/`, `~/.claude.json`, `.mcp.json` | None | stdout only |
| `scripts/gather-hooks-config.py` | Read hooks from Claude Code settings files; emit JSON with security metadata | `open` on `~/.claude/settings.json` and project settings | None | stdout only |
| `scripts/resolve-target.py` | Resolve a local path / GitHub URL / npm package to a local dir for auditing | `subprocess.run([...])` (arg list, no shell) calling `git clone --depth 1` or `npm pack` | Only via `git` / `npm` to user-supplied target | Temp dir under `tempfile.mkdtemp()` |

> **Note on `pattern-scan.py` self-flagging:** because it contains regex strings for every malicious pattern it detects (reverse shells, credential paths, etc.), running the audit on the audit tool itself produces many "Critical" matches against its own `PATTERNS` list. Those strings are detector signatures, not executable code — see the docstring at the top of the file for details.

### Operating Systems Compatibility

| OS      | Status | Notes                                                    |
| ------- | ------ | -------------------------------------------------------- |
| macOS   | Supported   | Fully tested                                              |
| Linux   | Supported   | All scripts use standard Python 3 — no OS-specific APIs   |
| WSL     | Supported   | Runs natively in the WSL Linux environment                |
| Windows | Supported   | Requires Python 3 on PATH; all scripts are native `.py` files with no bash/shell dependencies |


## Requirements

- **Python 3** available on PATH as `python3` or `python` (standard library only, no pip packages needed). The skill checks for Python availability before running and shows OS-specific install instructions if missing.
- **git** — required when auditing from GitHub URLs (shallow clone is used for speed)
- **npm** — required only when auditing MCP servers by npm package name
- For MCP/hooks audit: Claude Code settings files accessible at their standard locations (resolved via `os.path.expanduser("~")` — works as `~/.claude/` on macOS/Linux and `C:\Users\<you>\.claude\` on Windows)
- For skill audit: a local directory with `SKILL.md`, or a GitHub URL pointing to one
