# /bix:github-pr-describe

Generate a well-structured PR description by analyzing the diff between the PR branch and its base branch, then push it to GitHub.

## Installation

First, add the marketplace and install the `bix` plugin:

```
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix@Biswajit-Claude-Skills
```

## Usage

| Command | Behavior |
|---------|----------|
| `/bix:github-pr-describe 42` | Analyzes PR #42's diff, drafts a structured description, pushes after approval |
| `/bix:github-pr-describe` | Prompts for a PR number, then runs the same workflow |

## Features

- Fetches full PR diff and metadata via `gh` CLI
- Drafts descriptions with TL;DR table, Features, Bug Fixes, Improvements, Refactoring, Docs, Tests, Dependencies, and CI/CD sections
- Only includes sections with relevant changes — no empty boilerplate
- Preserves existing ticket/issue links from the original PR body
- Handles large diffs via subagent analysis
- Always asks for user approval before pushing to GitHub

## Requirements

- `gh` CLI installed and authenticated
- `python3` available
- Must be run from within a git repo with a GitHub remote

## Workflow

1. **Gather** — validates input, fetches PR metadata and diff as JSON
2. **Analyze** — reads the full diff, groups changes by area
3. **Draft** — structures the description using a template with only relevant sections
4. **Review** — displays the draft, lets you edit or approve
5. **Push** — updates the PR description on GitHub
