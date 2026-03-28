---
name: github-pr-describe
description: Generate a well-structured PR description by analyzing the diff between the PR branch and its base branch, then push it to GitHub. Use when the user wants to describe a PR, generate a PR body, or write a PR summary.
argument-hint: "<pr-number>"
---

# PR Description Generator

Generate a well-structured PR description by analyzing the diff, then push it to GitHub.

**Arguments:** `$ARGUMENTS` — the pull request number to describe.

---

## Phase 1: Validate and Gather

### Step 1 — Validate arguments

If `$ARGUMENTS` is empty or not a valid number, use `AskUserQuestion` to ask:
> "Which PR number would you like me to describe?"

### Step 2 — Run the gather script

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/gather-pr-info.sh" $ARGUMENTS
```

The script outputs JSON with:
- `repo` — owner/name
- `metadata` — title, body, branches, state, isDraft, stats, labels, url
- `diff.content` — the full diff
- `diff.lines` / `diff.bytes` — diff size info

If the script returns an `error` field, display it to the user and stop.

### Step 3 — Check for edge cases

- **Draft PR with no diff:** If `diff.lines` is 0, inform the user: "This PR has no commits/changes yet. Nothing to describe." and stop.
- **Very large diff** (>5000 lines): Use the `Agent` tool to analyze the diff in a subagent to avoid context bloat. Pass the diff content to the agent and ask it to return a structured summary of changes per file.
- **Existing body with ticket links:** If `metadata.body` contains URLs matching issue/ticket patterns (e.g., `#123`, `JIRA-456`, URLs to issue trackers), extract and preserve them for the final description.

---

## Phase 2: Analyze the Diff

Read the entire diff carefully. For every meaningful change (skip trivial whitespace/formatting-only changes), extract:

- **File(s) changed**
- **What changed** (added / modified / removed)
- **Why** — what problem it fixes or what improvement it makes
- **Notable implementation details** (if any)

Group related changes together by area (e.g., UI, API, tests, config).

---

## Phase 3: Draft the Description

Load the template from `${CLAUDE_SKILL_DIR}/templates/description.md` and use it to structure the PR description.

Follow all section rules and formatting rules defined in the template. Key points:

- Only include sections that have relevant changes — omit empty sections entirely
- TL;DR table + bullets always come first
- Preserve any ticket/issue links from the existing PR body under a `**Tickets:**` line at the top
- Be concise but precise — a reviewer should understand the *what* and *why* without reading the code
- Never fabricate changes — only describe what is actually in the diff

---

## Phase 4: User Review

**IMPORTANT:** Output the full drafted markdown description as plain text in the chat so the user can read it.

After displaying the description, use `AskUserQuestion` to ask:
> "Ready to push this description to PR #`{PR_NUMBER}`?"

Options:
- **Post** — "Push this description to GitHub as-is"
- **Edit** — "I want to suggest changes first"

If the user selects **Edit**, they will provide feedback. Revise the description and present it again. Repeat until the user selects **Post**.

---

## Phase 5: Push to GitHub

Once approved, update the PR description:

```bash
gh pr edit {PR_NUMBER} --body "$(cat <<'EOF'
{FINAL_DESCRIPTION}
EOF
)"
```

After pushing, output the PR URL from `metadata.url` to confirm success.
