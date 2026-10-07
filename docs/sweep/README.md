# /bix-utils:sweep

A maintainability sweep of a code change, in any language. It checks the change against the
project's own rules, cuts code the change made unnecessary, flags what can break at runtime, and
checks touched docs against the code. Reading is fanned out to Haiku and Sonnet lens agents; you
get one severity-ranked table, and nothing changes until you approve it.

## Installation

```bash
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-utils@Biswajit-Claude-Skills
```

## Usage

| Command | Scope |
| ------- | ----- |
| `/bix-utils:sweep` | Working tree against `HEAD` (the last commit if the tree is clean) |
| `/bix-utils:sweep src/payments` | Changes under a path |
| `/bix-utils:sweep main..HEAD` | A commit range |
| `/bix-utils:sweep --module src/payments` | Every file of a module, not only the diff |
| `/bix-utils:sweep --all` | The whole codebase |

## How It Works

```text
1. Scope and rules   pick the scope; collect CLAUDE.md, AGENTS.md, rule files, linter configs
2. Fan out           lens agents read in parallel, read-only
3. Verify & report   re-check every claim, merge duplicates, one severity-ranked table
4. Propose & apply   you approve; fixes land in dependency order
5. Finish            dangling-reference check, build and tests, manual checks
```

## Lenses

| Agent | Model | Looks for |
| ----- | ----- | --------- |
| `conventions` | Haiku | Project-rule breaks, abbreviated names, magic literals, dead code and imports, comments that narrate or cite instead of stating the rule, user-facing text leaking internals |
| `simplify` | Sonnet | Vestigial structure from a changed approach, redundancy, speculative checks, over-engineering, reinvented helpers, misplacement, fragmentation, duplicated UI. Runs over whole modules when a change adds or removes files |
| `risk` | Sonnet | Correctness, a name changed on one side of the wire, security, performance and query cost, missing or stale tests |
| `docs` | Sonnet | Touched Markdown: stale names and values, change-narration, verbosity, non-executable procedures |

## Severity

| Level | Meaning |
| ----- | ------- |
| 🔴 Critical | Correctness, security or contract risk; a doc that misleads |
| 🟠 High | Debt that will bite: misplacement, coupling, over-engineering, a broken project rule |
| 🟡 Medium | Redundant, vestigial or dead code; avoidable complexity |
| 🟢 Low | Naming and comment polish |

Defects in touched files that predate the change are reported and tagged `pre-existing`.

## Fix order

Placement → redundancy and constants → complexity → correctness → naming → comments and docs, so
cosmetic work is done once. The work is left uncommitted unless you ask.

## Project rules

The sweep has no built-in style guide. It enforces what the project writes down: `CLAUDE.md`,
`AGENTS.md`, `.claude/rules/`, `.cursor/rules/`, `CONTRIBUTING.md` and linter configs. A list of
shared helpers in those files lets the `simplify` lens catch re-implementations.

## Token Efficiency

- The main session plans and verifies; Haiku and Sonnet agents do the reading.
- Agents return table rows only, never prose.
- Large changes are split by module so no agent reads more than ~400 changed lines.

## Requirements

- A git repository. An LSP server for the language is used when present; otherwise grep with
  positive and negative controls.
