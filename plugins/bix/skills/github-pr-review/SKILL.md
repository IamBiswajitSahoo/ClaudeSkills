---
name: github-pr-review
description: Review GitHub pull requests — drafts findings across 5 categories with severity labels, supports parallel agents for large PRs, and posts as a batched pending review after per-comment approval.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: "<pr-number> [-parallel]"
---

# GitHub PR Review

Review a pull request, draft findings with severity labels, and post as a batched pending review after per-comment approval.

**Arguments:** `$ARGUMENTS` — PR number, optionally followed by `-parallel` for parallel agent mode.

---

## Phase 1: Validate & Gather

### Step 1 — Parse arguments

Extract the PR number and `-parallel` flag from `$ARGUMENTS`. If no PR number is provided or it's not a valid number, use `AskUserQuestion` to ask:
> "Which PR number would you like me to review?"

### Step 2 — Run the gather script

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/gather-pr-context.sh" $ARGUMENTS
```

The script outputs JSON with: `repo`, `pr_number`, `metadata`, `commit_sha`, `diff`, `project_rules` (CLAUDE.md/REVIEW.md contents if present), `eligibility`, `primary_language`, and `parallel_requested`.

If the script returns an `error` field, display it to the user and stop.

### Step 3 — Check eligibility

If the PR is not in a reviewable state, use `AskUserQuestion`:

- **Draft PR** (`eligibility.is_draft` is true): "This PR is a draft. Review anyway?"
- **Closed/Merged** (`eligibility.state` is not OPEN): "This PR is [closed/merged]. Review anyway?"
- **Already reviewed** (`eligibility.already_reviewed` is true): "You've already reviewed this PR. Review again?"

Options: **Yes** / **Skip**. If Skip, stop.

If `eligibility.branch_matches` is false, warn: "You're on branch `{current_branch}` but the PR is on `{head_ref}`. Git blame results for pre-existing issue detection may be inaccurate."

### Step 4 — Select review mode

- If `-parallel` was passed, use **parallel mode**.
- Else if `diff.lines > 3000`, use `AskUserQuestion`:
  > "This PR has {N} lines of diff. How would you like to review?"
  - **Parallel** — "Faster: 5 agents review categories in parallel (uses more tokens)"
  - **Single** — "Slower: one sequential pass through all categories (uses fewer tokens)"
- Otherwise, default to **single mode**.

---

## Phase 2: Analyze

Load `${CLAUDE_SKILL_DIR}/templates/review-categories.md` for the 5 evaluation categories and severity rules.

If `project_rules.claude_md` or `project_rules.review_md` is not null, incorporate those project-specific rules as **additional review criteria** alongside the 5 built-in categories. Project rules take precedence when they conflict with general guidance.

### Single mode

Read the full diff. Evaluate all 5 categories sequentially. For each genuine issue found, draft a finding with: `path`, `line`, `body` (with optional suggestion block), and `severity` (Critical / Warning / Nit).

### Parallel mode

Launch 6 `Agent` calls in parallel using the dedicated review sub-agents. Each agent receives the diff content, PR metadata, and project rules (CLAUDE.md/REVIEW.md) if present as part of its prompt.

**You MUST invoke each agent via the Agent tool using its fully-qualified `subagent_type`** (the `bix:pr-review:` prefix is required — without it the call falls back to `general-purpose` on the parent model and ignores the agent's `model:` frontmatter).

The 5 category agents (launch all in parallel):
1. `subagent_type: "bix:pr-review:pr-review-correctness"` — logic errors, null safety, data integrity, edge cases, regression risk
2. `subagent_type: "bix:pr-review:pr-review-conventions"` — naming, code organization, error handling patterns, consistency
3. `subagent_type: "bix:pr-review:pr-review-performance"` — hot-path allocations, algorithmic complexity, redundant computation
4. `subagent_type: "bix:pr-review:pr-review-security"` — input validation, injection risks, data exposure, access control
5. `subagent_type: "bix:pr-review:pr-review-tests"` — missing tests, untested edge cases, stale tests, weak assertions

The 6th agent (launch in parallel with the above):
6. `subagent_type: "bix:pr-review:pr-review-docs"` — missing or stale documentation on public API surfaces. Also pass `primary_language` to this agent. If `primary_language` is null or unsupported, skip this agent entirely.

Each agent returns a JSON array of findings (`path`, `line`, `body`, `severity`). After all agents complete, parse and merge the arrays, then deduplicate: if multiple agents flag the same `path:line`, keep the finding with the higher severity.

### Pre-existing issue detection (both modes)

For each finding, check if the flagged code existed before the PR:

```bash
git blame -L <line>,<line> -- <path>
```

Compare the blamed commit against the PR's commit range. If the code predates the PR branch, tag the finding as `[Pre-existing]`.

### Sort findings

1. New findings first, pre-existing last
2. Within each group: Critical > Warning > Nit

---

## Phase 3: Documentation Review

**Skip this phase in parallel mode** — it is already handled by the `pr-review-docs` sub-agent in Phase 2.

If `primary_language` is null or not supported, skip with a note: "Skipping doc review — unsupported or undetected language."

Otherwise, load `${CLAUDE_SKILL_DIR}/templates/doc-review-guide.md` and apply the language-specific rules to the diff. Add doc findings to the list (Nit for missing, Warning for stale).

---

## Phase 4: Per-Comment Approval

Load `${CLAUDE_SKILL_DIR}/templates/review-comment-format.md` for line number rules and formatting reference.

Present each finding individually via `AskUserQuestion`:

```
[Severity] Comment N — `path/file` line L: brief summary

{Full comment text with explanation and optional suggestion block}
```

Options: **Post** / **Skip** / **Modify**

If the user selects **Modify**: ask what to change, apply the edit, re-present the same comment for approval.

After all comments are reviewed, show a summary:

```
Posted:  Comment 1 (src/auth.ts:20) [Critical], Comment 3 (src/utils.ts:45) [Nit]
Skipped: Comment 2 (src/config.ts:8) [Nit]
Event type: REQUEST_CHANGES
```

Then use `AskUserQuestion`: "Ready to submit the review with N comments?" — **Submit** / **Cancel**.

---

## Phase 5: Post Review

Build the JSON payload with all approved comments. Load the commit SHA from the gather output.

```bash
cat <<'JSONEOF' | gh api repos/:owner/:repo/pulls/{PR_NUMBER}/reviews -X POST --input -
{
  "commit_id": "{commit_sha}",
  "comments": [ ... ]
}
JSONEOF
```

Submit with the appropriate event type:
- Any `[Critical]` comment posted → `REQUEST_CHANGES`
- Only `[Warning]`/`[Nit]` posted → `COMMENT`
- Zero comments posted → let user choose between `APPROVE` and `COMMENT`

```bash
gh api repos/:owner/:repo/pulls/{PR_NUMBER}/reviews/{REVIEW_ID}/events \
  -X POST -f event="{EVENT}" -f body="{SUMMARY}"
```

---

## Phase 6: Summary

Display: posted count, skipped count, event type, and the PR URL from `metadata.url`.

---

## Important Rules

- **Always pending review** — even for a single comment. Batch all comments into one review.
- **Always per-comment approval** — never post without the user approving each comment individually.
- **Always verify line numbers** — count from diff hunk headers, verify against actual file content.
- **Always use JSON input** — never use `-f 'comments[][...]'` flag syntax (causes 422 errors).
- **Never fabricate findings** — only flag issues actually present in the diff.
- **Never auto-post** — the user must explicitly approve every comment and the final submission.
- **Never expand scope** — if you notice issues outside the diff, note them but don't include in the review.
