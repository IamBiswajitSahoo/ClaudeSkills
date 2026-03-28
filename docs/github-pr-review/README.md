# /bix:github-pr-review

Review GitHub pull requests — drafts findings across 5 categories with severity labels, supports parallel agents for large PRs, and posts as a batched pending review after per-comment approval.

## Installation

First, add the marketplace and install the `bix` plugin:

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix@Biswajit-Claude-Skills
```

## Usage

| Command | Behavior |
|---------|----------|
| `/bix:github-pr-review 42` | Reviews PR #42 in single-agent mode |
| `/bix:github-pr-review 42 -parallel` | Reviews PR #42 with 5+1 parallel agents |
| `/bix:github-pr-review` | Prompts for a PR number, then reviews |

## Features

- 5 evaluation categories: Code Correctness, Project Conventions, Performance, Security, Test Coverage
- Severity labels on every finding: Critical, Warning, Nit
- Pre-existing issue detection via git blame — tagged and shown separately
- CLAUDE.md / REVIEW.md integration for team-specific review rules
- Language-aware documentation review (10 languages supported)
- Per-comment approval: Post / Skip / Modify before anything is posted
- Parallel mode for large PRs (5 category agents + 1 doc review agent)
- Eligibility checks for draft, closed, merged, and already-reviewed PRs
- Batched pending reviews — one notification to the PR author

## Review Categories

| Category | Typical severity |
|----------|-----------------|
| Code Correctness | Critical / Warning |
| Project Conventions | Warning / Nit |
| Performance | Warning / Nit |
| Security | Critical / Warning |
| Test Coverage | Warning / Nit |

## Requirements

- `gh` CLI installed and authenticated
- `python3` available
- `git` available
- Must be run from within a git repo with a GitHub remote

## Workflow

1. **Gather** — validates input, fetches PR metadata + diff + project rules + eligibility
2. **Eligibility** — checks PR status, asks user whether to proceed if not ideal
3. **Analyze** — evaluates diff across 5 categories (single or parallel), detects pre-existing issues
4. **Doc review** — language-aware check for missing/stale documentation
5. **Approve** — per-comment approval with severity labels, pre-existing shown last
6. **Post** — batched pending review with appropriate event type (REQUEST_CHANGES / COMMENT / APPROVE)
