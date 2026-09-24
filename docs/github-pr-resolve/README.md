# /bix-github:github-pr-resolve

Evaluate and triage review comments on a GitHub pull request, implement agreed fixes, and reply on every handled thread.

## Installation

First, add the marketplace and install the `bix-github` plugin:

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-github@Biswajit-Claude-Skills
```

## Usage

| Command | Behavior |
|---------|----------|
| `/bix-github:github-pr-resolve 42` | Fetches review threads on PR #42 that await your reply, triages with you, implements agreed fixes |
| `/bix-github:github-pr-resolve 42 -all` | Same, but also includes resolved threads and threads you already answered |
| `/bix-github:github-pr-resolve` | Prompts for a PR number, then runs the same workflow |

## Features

- Fetches both inline code comments and top-level review summaries
- Groups reply chains into threads for full conversation context
- Shows only unresolved threads awaiting your reply by default (`-all` shows everything)
- Loads project rules (`CLAUDE.md`, `REVIEW.md`, `.claude/rules/*.md`) from the repo root and every folder above a commented file — nested projects included
- Reads the current code and categorises each thread: Agree-Fix, Agree-NoFix, Clarify, Disagree, or Outdated (uses GitHub's outdated flag)
- User-driven triage: **Fix**, **Explore**, **Reply only**, or **Skip** each thread — with a recommended option and drafted reply
- Batches up to 4 related threads per question to reduce back-and-forth
- For "Explore" items: investigates codebase first, proposes approach, gets approval
- Tracks progress using Claude Code's built-in task system
- Never commits automatically — leaves changes for you to review
- After you commit and push: replies on fixed threads with the commit hash, posts approved Disagree/Clarify/Outdated replies, and offers to resolve closed threads

## Requirements

- `gh` CLI installed and authenticated
- `python3` available
- Must be run from within a git repo with a GitHub remote

## Scripts

Scripts the skill executes on your machine. Provided for transparency so you can verify nothing unexpected runs.

| Script | Purpose | Tools / Calls | Network | Writes |
|---|---|---|---|---|
| `scripts/gather-pr-comments.sh` | Fetch inline + review comments, thread state (resolved/outdated), and project rules; group reply chains into threads | `gh`, `git`, `python3` | Only via `gh` (GitHub REST + GraphQL) | stdout only |

## Workflow

1. **Gather** — validates input, fetches review feedback, thread state and project rules; filters to threads awaiting your reply
2. **Evaluate & display** — reads the current code, categorises each thread, shows review summaries then threads grouped by file
3. **Triage** — asks how to handle each thread (Fix / Explore / Reply only / Skip)
4. **Explore** — for items needing investigation, reads codebase and proposes approach
5. **Implement** — applies fixes with task tracking, one at a time
6. **Summary** — shows what was fixed, replied to, and skipped
7. **Commit, push, reply & resolve** — commits on request, pushes after confirmation, posts replies, offers to resolve closed threads
