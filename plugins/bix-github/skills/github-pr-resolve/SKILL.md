---
name: github-pr-resolve
description: Evaluate and triage existing review comments on a GitHub pull request, then implement agreed fixes. Use when the user wants to address PR feedback, resolve review comments, or fix reviewer requests.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: "<pr-number>"
---

# PR Review Resolver

Evaluate PR review comments, triage with the user, implement agreed fixes.

## Phase 1 — Validate & gather

If `$ARGUMENTS` is empty or not a number, ask via `AskUserQuestion`: *"Which PR number would you like me to resolve review comments for?"*

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/gather-pr-comments.sh" $ARGUMENTS
```

Returns `{pr, inline_threads, review_summaries, stats}` where:
- `pr` — title, branches, state, url
- `inline_threads` — code-level comments grouped by thread (root + replies)
- `review_summaries` — top-level review bodies (approve/request changes/comment)
- `stats` — counts

On `error`, stop. If `stats.total_threads == 0 && stats.total_review_summaries == 0`, say "No review comments found on PR #N" and stop. If `stats.total_threads > 30`, show a per-file summary table first and proceed file-by-file.

## Phase 2 — Display comments

**Review summaries** (if any), first:

```
### Review by @{author} — {state}
> {body}
```

`state` ∈ {APPROVED, CHANGES_REQUESTED, COMMENTED}.

**Inline threads**, grouped by file:

```
### Thread {n} — {path}:{line} (by @{author})
> {root body}

Code context:
{diff_hunk — last 5 lines only}
```

Show replies indented: `  ↳ @{reply_author}: {reply body}`. Replies often contain resolution or agreement — important for triage.

## Phase 3 — Triage

For each thread, ask via `AskUserQuestion`:
- Brief analysis of what the reviewer is suggesting (interpret if technical or unclear).
- Include reply context if it changes the meaning (e.g., "author already agreed").
- Options: **Fix** / **Explore** (needs codebase exploration) / **Skip**.

Batch up to 4 threads per `AskUserQuestion` call. Group threads in the same file together. Triage actionable review summaries (not pure "LGTM") the same way. Collect all responses before proceeding.

## Phase 4 — Explore

For each "Explore" thread: read relevant files, search for related patterns/usages, draft a concrete fix approach (what/where/why). Present ALL exploration results at once via `AskUserQuestion`, asking if each proposed approach is acceptable or needs modification. Iterate until all approved. Approved items join the Fix list.

## Phase 5 — Implement

Create a `TaskCreate` task per fix with: thread reference (number, file, line), what the reviewer said, agreed approach.

For each: `TaskUpdate` → `in_progress` → implement → verify (syntax, logic, diagnostics) → `TaskUpdate` → `completed`.

If a fix reveals additional issues, note them but **do not expand scope** without asking.

## Phase 6 — Summary

```
### Resolved
- ✓ Thread {n} ({path}:{line}) — {what was fixed}

### Skipped
- Thread {n} ({path}:{line}) — {reason}
```

Remind the user that changes are **not committed** — they can review the diff and commit when ready.

## Phase 7 — Commit, push & reply

After the user has reviewed the diff:

1. **Commit** the changes (user may ask explicitly, or confirm after reviewing the diff).
2. **Ask the user to confirm push** — do NOT push without confirmation.
3. Once the user confirms the push is done, **post reply comments** on each resolved thread in the PR with the commit hash so the reviewer can browse to the exact commit.

### Posting reply comments — correct GitHub API endpoint

To reply to an inline PR comment thread, create a new comment on the PR with the `in_reply_to` field set to the root comment ID:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -f body="Fixed in {commit_hash} — {brief description of fix}." \
  -F in_reply_to={root_comment_id}
```

**Do NOT** use `pulls/comments/{id}/replies` — that endpoint does not exist and returns a 404.

## Rules

- Never skip triage — always let the user decide on each comment.
- For Explore items, always get explicit approval on the approach before implementing.
- Never expand scope silently — note additional issues but ask before fixing them.
- Do NOT push changes without explicit user confirmation.
- Use `TaskCreate`/`TaskUpdate`, not temp files, for progress tracking.
