---
name: github-pr-describe
description: Generate a well-structured PR description by analyzing the diff between the PR branch and its base branch, then push it to GitHub. Use when the user wants to describe a PR, generate a PR body, or write a PR summary.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: "<pr-number>"
---

# PR Description Generator

Generate a structured PR description from the diff, then push it to GitHub.

## Phase 1 — Validate & gather

If `$ARGUMENTS` is empty or not a number, ask via `AskUserQuestion`: *"Which PR number would you like me to describe?"*

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/gather-pr-info.sh" $ARGUMENTS
```

Returns `{repo, metadata, diff: {content, lines, bytes}}`. On `error`, stop.

**Edge cases:**
- `diff.lines == 0`: "This PR has no commits/changes yet. Nothing to describe." → stop.
- `diff.lines > 5000`: delegate diff analysis to an `Agent` sub-call to avoid context bloat. Ask it to return a structured per-file summary of changes.
- If `metadata.body` contains ticket links (`#123`, `JIRA-456`, issue-tracker URLs), preserve them for the final description.

## Phase 2 — Analyze the diff

For every meaningful change (skip whitespace/format-only), extract: files changed, what (added/modified/removed), why, notable implementation details. Group related changes by area (UI, API, tests, config).

## Phase 3 — Draft

Load `${CLAUDE_SKILL_DIR}/templates/description.md` and follow its section and formatting rules. Key points:

- Only include sections that have relevant changes — omit empty sections.
- TL;DR table + bullets always come first.
- Preserve any ticket/issue links from the existing PR body under `**Tickets:**` at the top.
- Concise but precise — a reviewer should understand the *what* and *why* without reading the code.
- Never fabricate changes.

## Phase 4 — User review

Output the full drafted markdown description as plain text so the user can read it. Then ask via `AskUserQuestion`: *"Ready to push this description to PR #{PR_NUMBER}?"* — **Post** / **Edit**.

On **Edit**, apply the user's feedback, re-display, repeat until **Post**.

## Phase 5 — Push

```bash
gh pr edit {PR_NUMBER} --body "$(cat <<'EOF'
{FINAL_DESCRIPTION}
EOF
)"
```

Output the PR URL from `metadata.url` to confirm.
