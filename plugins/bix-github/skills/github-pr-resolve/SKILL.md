---
name: github-pr-resolve
description: Evaluate and triage review comments on a GitHub pull request, implement agreed fixes, and reply to reviewers (including disagreements and clarifications). Use when the user wants to address PR feedback, resolve review comments, or fix reviewer requests.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: "<pr-number> [-all]"
---

# PR Review Resolver

Evaluate PR review comments, triage with the user, implement agreed fixes, and reply on every handled thread.

**Arguments:** `$ARGUMENTS` — PR number, optionally followed by `-all` to include resolved threads and threads you already answered (default: only threads awaiting your reply).

## Phase 1 — Validate & gather

If `$ARGUMENTS` has no PR number, ask via `AskUserQuestion`: *"Which PR number would you like me to resolve review comments for?"*

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/gather-pr-comments.sh" $ARGUMENTS
```

Returns `{pr, current_user, inline_threads, review_summaries, project_rules, stats}` where:
- `pr` — title, branches, state, url
- `inline_threads` — code-level threads (root + replies), each with `thread_node_id`, `is_resolved`, `is_outdated`, `awaiting_reply`. Without `-all`, only unresolved threads whose last comment is not yours.
- `review_summaries` — top-level review bodies (approve/request changes/comment)
- `project_rules` — `CLAUDE.md`, `REVIEW.md` and `.claude/rules/*.md` from the repo root and every folder above a commented file, keyed by repo-relative path
- `stats` — counts, including `total_threads_on_pr`, `resolved_threads`, `answered_threads`, `outdated_threads`

On `error`, stop. If `stats.total_threads == 0 && stats.total_review_summaries == 0`, say "No review comments awaiting a reply on PR #N" — mention `resolved_threads` / `answered_threads` and that `-all` includes them — and stop. If `stats.total_threads > 30`, show a per-file summary table first and proceed file-by-file.

## Phase 2 — Evaluate & display

**Project rules.** Treat `project_rules` as the codebase's conventions. They take precedence when judging whether a suggestion fits the codebase. A path-scoped rule (`paths:` frontmatter) applies only to files matching its globs.

**Evaluate every thread before showing it.** Read the current code at `path:line` first — never judge from the reviewer's description or the diff hunk alone. Assign one category:

| Category | When | Default action |
|---|---|---|
| **Agree-Fix** | Reviewer is right and the code should change | Fix |
| **Agree-NoFix** | Reviewer is right, but the change is out of scope or already tracked | Reply explaining why not now |
| **Clarify** | The comment is ambiguous or you need the reviewer's intent | Reply with a question |
| **Disagree** | The suggestion is wrong or conflicts with project rules | Reply with the reasoning — never capitulate to avoid friction |
| **Outdated** | `is_outdated` is true, or the flagged code no longer exists or already does what was asked | Reply noting the current state |

**Review summaries** (if any), first:

```
### Review by @{author} — {state}
> {body}
```

`state` ∈ {APPROVED, CHANGES_REQUESTED, COMMENTED}.

**Inline threads**, grouped by file:

```
### Thread {n} — {path}:{line} (by @{author}) — [{category}]{ · outdated}{ · resolved}
> {root body}

Code context:
{diff_hunk — last 5 lines only}

Assessment: {one or two sentences — why this category, citing current code or a project rule}
```

Show replies indented: `  ↳ @{reply_author}: {reply body}`. Replies often contain resolution or agreement — important for triage.

## Phase 3 — Triage

For each thread, ask via `AskUserQuestion`:
- Brief analysis of what the reviewer is suggesting (interpret if technical or unclear), plus your category and assessment.
- Include reply context if it changes the meaning (e.g., "author already agreed").
- Options, with the category's default action first and marked **(Recommended)**:
  - **Fix** — implement the change.
  - **Explore** — needs codebase exploration before deciding.
  - **Reply only** — post the drafted Agree-NoFix / Clarify / Disagree / Outdated reply; include the draft in the option's description.
  - **Skip** — do nothing.

Batch up to 4 threads per `AskUserQuestion` call. Group threads in the same file together. Triage actionable review summaries (not pure "LGTM") the same way. Collect all responses before proceeding. If the user edits a drafted reply via "Other", use their text.

## Phase 4 — Explore

For each "Explore" thread: read relevant files, search for related patterns/usages, draft a concrete fix approach (what/where/why). Present ALL exploration results at once via `AskUserQuestion`, asking if each proposed approach is acceptable or needs modification — or whether it should become a Reply only instead. Iterate until all approved. Approved items join the Fix list.

## Phase 5 — Implement

Create a `TaskCreate` task per fix with: thread reference (number, file, line), what the reviewer said, agreed approach.

For each: `TaskUpdate` → `in_progress` → implement → verify (syntax, logic, diagnostics, and the `project_rules` that apply to the file) → `TaskUpdate` → `completed`.

If a fix reveals additional issues, note them but **do not expand scope** without asking.

## Phase 6 — Summary

```
### Fixed
- ✓ Thread {n} ({path}:{line}) — {what was fixed}

### Reply only
- Thread {n} ({path}:{line}) — [{category}] {one-line gist of the reply}

### Skipped
- Thread {n} ({path}:{line}) — {reason}
```

Remind the user that changes are **not committed** — they can review the diff and commit when ready.

## Phase 7 — Commit, push, reply & resolve

After the user has reviewed the diff:

1. **Commit** the changes (user may ask explicitly, or confirm after reviewing the diff). Skip steps 1–2 when there are no fixes.
2. **Ask the user to confirm push** — do NOT push without confirmation.
3. Once the push is done, **post reply comments**:
   - **Fix** threads — with the commit hash so the reviewer can browse to the exact commit.
   - **Reply only** threads — the approved draft.
   Post sequentially, not in parallel — ordering matters for thread coherence.
4. **Offer to resolve threads.** For threads the reply closes (Fix, and Outdated), ask via `AskUserQuestion`: *"Mark these {K} threads as resolved?"* Never resolve without asking, and never resolve Clarify or Disagree threads — the reviewer answers those.

### Posting reply comments — correct GitHub API endpoint

To reply to an inline PR comment thread, create a new comment on the PR with the `in_reply_to` field set to the root comment ID:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -f body="Fixed in {commit_hash} — {brief description of fix}." \
  -F in_reply_to={root_comment_id}
```

**Do NOT** use `pulls/comments/{id}/replies` — that endpoint does not exist and returns a 404.

### Resolving a thread

```bash
gh api graphql -f query='
  mutation($id: ID!) {
    resolveReviewThread(input: {threadId: $id}) { thread { id isResolved } }
  }' -F id="{thread_node_id}"
```

## Rules

- Never skip triage — always let the user decide on each comment.
- Always read the current code before categorising a thread or drafting a reply about it.
- Never fabricate agreement — if the reviewer is wrong, recommend a polite Disagree reply with the reasoning.
- For Explore items, always get explicit approval on the approach before implementing.
- Never expand scope silently — note additional issues but ask before fixing them.
- Do NOT push changes without explicit user confirmation.
- Never post a reply the user has not approved, and never resolve a thread without asking.
- Use `TaskCreate`/`TaskUpdate`, not temp files, for progress tracking.
