# /github-pr-resolve

> Also available as `/github-pr-resolve`

Evaluate and triage existing review comments on a GitHub pull request, then implement agreed fixes.

## Installation

First, add the marketplace and install the `bix-github` plugin:

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-github@Biswajit-Claude-Skills
```

## Usage

| Command | Behavior |
|---------|----------|
| `/github-pr-resolve 42` | Fetches review comments for PR #42, triages with you, implements agreed fixes |
| `/github-pr-resolve` | Prompts for a PR number, then runs the same workflow |

## Features

- Fetches both inline code comments and top-level review summaries
- Groups reply chains into threads for full conversation context
- User-driven triage: **Fix**, **Explore**, or **Skip** each thread
- Batches up to 4 related threads per question to reduce back-and-forth
- For "Explore" items: investigates codebase first, proposes approach, gets approval
- Tracks progress using Claude Code's built-in task system
- Never commits automatically — leaves changes for you to review

## Requirements

- `gh` CLI installed and authenticated
- `python3` available
- Must be run from within a git repo with a GitHub remote

## Scripts

Scripts the skill executes on your machine. Provided for transparency so you can verify nothing unexpected runs.

| Script | Purpose | Tools / Calls | Network | Writes |
|---|---|---|---|---|
| `scripts/gather-pr-comments.sh` | Fetch inline + review comments and group reply chains into threads | `gh`, `jq` | Only via `gh` (GitHub API) | stdout only |

## Workflow

1. **Gather** — validates input, fetches all review feedback (inline comments + review bodies + threading)
2. **Display** — shows review summaries first, then inline threads grouped by file
3. **Triage** — asks how to handle each thread (Fix / Explore / Skip)
4. **Explore** — for items needing investigation, reads codebase and proposes approach
5. **Implement** — applies fixes with task tracking, one at a time
6. **Summary** — shows what was resolved and what was skipped
