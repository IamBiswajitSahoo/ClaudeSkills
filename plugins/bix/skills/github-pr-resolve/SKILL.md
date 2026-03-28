---
name: github-pr-resolve
description: Evaluate and triage existing review comments on a GitHub pull request, then implement agreed fixes. Use when the user wants to address PR feedback, resolve review comments, or fix reviewer requests.
argument-hint: "<pr-number>"
---

# PR Review Resolver

Evaluate review comments on a PR, triage them with the user, and implement the agreed fixes.

**Arguments:** `$ARGUMENTS` — the pull request number to resolve comments for.

---

## Phase 1: Validate and Gather

### Step 1 — Validate arguments

If `$ARGUMENTS` is empty or not a valid number, use `AskUserQuestion` to ask:
> "Which PR number would you like me to resolve review comments for?"

### Step 2 — Run the gather script

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/gather-pr-comments.sh" $ARGUMENTS
```

The script outputs JSON with:
- `pr` — title, branches, state, url
- `inline_threads` — code-level comments grouped by thread (root + replies)
- `review_summaries` — top-level review bodies (approve/request changes/comment)
- `stats` — counts for threads, replies, and review summaries

If the script returns an `error` field, display it to the user and stop.

### Step 3 — Check for edge cases

- **No comments at all:** If `stats.total_threads` is 0 and `stats.total_review_summaries` is 0, tell the user "No review comments found on PR #N" and stop.
- **Large comment count** (>30 threads): Group comments by file and show a summary table first, then proceed file-by-file rather than displaying all comments at once.

---

## Phase 2: Display Comments

### Review summaries (top-level)

If there are review summaries, display them first — these are the reviewer's high-level feedback:

```
### Review by @{author} — {state}
> {body}
```

Where `state` is one of: APPROVED, CHANGES_REQUESTED, COMMENTED.

### Inline threads (code-level)

Display threaded comments grouped by file. For each thread:

```
### Thread {n} — {path}:{line} (by @{author})
> {root comment body}

Code context:
{diff_hunk — last 5 lines only}
```

If the thread has replies, show them indented below the root:
```
  ↳ @{reply_author}: {reply body}
```

Replies often contain the resolution or agreement — they are important context for triaging.

---

## Phase 3: Triage

For each thread, use `AskUserQuestion` to ask the user how to handle it.

- Present a brief analysis of what the reviewer is suggesting (add your own interpretation if the comment is technical or unclear)
- Include reply context if it changes the meaning (e.g., "the author already agreed to this in a reply")
- Use these options:
  - **Fix** — "Implement this change"
  - **Explore** — "Needs codebase exploration before deciding on an approach"
  - **Skip** — "Do not address this comment"
- The user can also select "Other" (built-in) to provide custom instructions

You may batch up to 4 threads per `AskUserQuestion` call. Group threads that touch the same file together when possible.

For **review summaries** that contain actionable feedback (not just "LGTM"), triage them the same way.

Collect all responses before proceeding.

---

## Phase 4: Explore (for "Explore" items)

For each thread the user marked as "Explore":

1. Read the relevant file(s) and surrounding code
2. Search the codebase for related patterns, usages, or dependencies
3. Draft a concrete fix approach — what to change, where, and why
4. Present ALL exploration results to the user at once using `AskUserQuestion`, asking if each proposed approach is acceptable or needs modification

Iterate until the user approves all approaches. Items approved here join the "Fix" list.

---

## Phase 5: Implement

Create tasks for the agreed fixes using `TaskCreate`, one task per fix item. Include in each task description:
- The thread reference (number, file, line)
- What the reviewer said
- The agreed fix approach

Then implement each fix sequentially:
1. Mark the task as `in_progress` via `TaskUpdate`
2. Implement the change
3. Verify the change (check for syntax errors, review logic, run diagnostics if available)
4. Mark the task as `completed` via `TaskUpdate`

If a fix reveals additional issues, note them but do NOT expand scope without asking the user.

---

## Phase 6: Summary

After all fixes are implemented:

1. Display a summary of what was done:
   ```
   ### Resolved
   - ✓ Thread {n} ({path}:{line}) — {what was fixed}

   ### Skipped
   - Thread {n} ({path}:{line}) — {reason}
   ```

2. Remind the user that changes are **not committed** — they can review the diff and commit when ready.

---

## Important Rules

- Never skip the triage phase — always let the user decide on each comment
- For "Explore" items, always get explicit user approval on the approach before implementing
- If a fix reveals additional issues, note them but don't expand scope without asking
- Do NOT commit changes — leave that to the user
- Do NOT write temporary files for progress tracking — use `TaskCreate`/`TaskUpdate` instead
