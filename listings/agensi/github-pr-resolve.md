# github-pr-resolve: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is a white speech bubble with a large amber check mark inside it, and a smaller second bubble overlapping behind it to suggest a reply on a conversation thread.

## 2. Skill name

PR Review Resolver

Slug: `github-pr-resolve`

## 3. Skill summary

Triage GitHub PR review comments, apply the fixes you approve, and reply to every thread.

## 4. Full description

**What it does**
- Fetches inline review threads and review summaries for a pull request through the `gh` CLI.
- Reads the current code for each thread and labels it: Agree-Fix, Agree-NoFix, Clarify, Disagree or Outdated.
- Lets you choose Fix, Explore, Reply only or Skip for every thread.
- Implements the fixes you approve and tracks each one as a task.
- After you commit and push, posts replies (with the commit hash) and offers to resolve closed threads.

**Problems it solves**
- Long review threads are hard to sort by what actually needs a code change.
- Replying to every comment by hand is slow and replies get inconsistent.
- Agreeing with a wrong suggestion just to avoid friction.
- Reviewer rules in CLAUDE.md or REVIEW.md get missed when fixing.

**How it works**
1. Gather: validate the PR number, fetch threads, thread state and project rules.
2. Evaluate and display: read the code at each location, categorise, show summaries then threads by file.
3. Triage: you pick an action per thread, up to 4 threads per question.
4. Explore: investigate chosen threads and propose an approach for your approval.
5. Implement: apply approved fixes one at a time with task tracking.
6. Summary: list what was fixed, replied to and skipped. Nothing is committed yet.
7. Commit, push, reply and resolve: each step waits for your confirmation.

**Why install it**
- Free and open source (Apache-2.0).
- You decide every comment. Nothing is posted, pushed or resolved without approval.
- Replies follow plain, short writing rules and carry no AI attribution.

**Requirements**
- Claude Code, `gh` CLI (authenticated), `python3`.
- Run inside a git repo with a GitHub remote.

## 5. The request

```
/github-pr-resolve 128
```

```
Go through the review comments on PR 128 and help me fix or answer them.
```

## 6. The result

Summary: PR #128 ("Add retry to invoice export") has 3 threads awaiting your reply and 1 review summary. The skill read the current code for each, found one project rule that applies (`CLAUDE.md`: no magic numbers), and asked you to triage. You chose Fix for thread 1, Reply only for thread 2 and Fix for thread 3. Changes are in your working tree and are not committed.

Review summary:

```
### Review by @mira-dev: CHANGES_REQUESTED
> A few small things in the export retry. Details inline.
```

Threads:

```
### Thread 1: src/export/retry.ts:42 (by @mira-dev) - [Agree-Fix]
> The delay of 500 should be a named constant.

Code context:
   const attempt = 0;
   while (attempt < 3) {
     await sleep(500);

Assessment: Reviewer is right. The value is repeated in two places and CLAUDE.md asks for named constants.

### Thread 2: src/export/retry.ts:77 (by @mira-dev) - [Disagree]
> Why not retry on every error?
  ↳ @tomas-r: Only network errors are safe to retry.

Code context:
   if (!isNetworkError(err)) throw err;

Assessment: Retrying a validation error would send the same bad invoice again. Current code is correct.

### Thread 3: src/export/csv.ts:19 (by @mira-dev) - [Agree-Fix]
> This header list is out of order compared to the docs.

Code context:
   const headers = ["id", "total", "date"];

Assessment: The docs list date before total. Fix.
```

Final summary:

```
### Fixed
- ✓ Thread 1 (src/export/retry.ts:42) - moved 500 to RETRY_DELAY_MS
- ✓ Thread 3 (src/export/csv.ts:19) - reordered headers to id, date, total

### Reply only
- Thread 2 (src/export/retry.ts:77) - [Disagree] Only network errors are retried, because other errors would fail the same way again.

### Skipped
- None
```

Next steps:
- Review the diff, then ask the skill to commit.
- Confirm the push when asked.
- Approve the drafted replies, for example: "Fixed in `a1b2c3d`. The retry delay is now a named constant."
- Answer "Mark these 2 threads as resolved?" for threads 1 and 3. Thread 2 stays open for the reviewer.

## 7. Compatibility note

Built for and tested on Claude Code. It depends on AskUserQuestion for triage, TaskCreate and TaskUpdate for progress tracking, and `${CLAUDE_SKILL_DIR}` to locate its bundled script. Other SKILL.md agents may run parts of it, but they are not tested.

## 8. Categories, tags, use cases

- Categories: Code Quality & Review, Workflow Automation, Productivity
- Tags: github, pull-request, code-review, review-comments, gh-cli, triage, claude-code, pr-feedback
- Use cases:
  - Addressing reviewer feedback on your PR
  - Triaging a long list of review threads
  - Writing short, clear replies to reviewers
  - Pushing back politely on incorrect suggestions
  - Closing out threads after a fix is pushed

## 9. Permissions

- Tools used:
  - Terminal / Shell: yes. Runs the bundled bash script, `gh`, `git` and `python3`.
  - Read Files: yes. Reads source files at commented lines and CLAUDE.md, REVIEW.md and `.claude/rules/*.md`.
  - Write Files: yes. Edits source files for fixes you approve.
  - Browser: no.
  - Network Access: yes. Only through `gh` to GitHub REST and GraphQL.
  - Environment Variables: no. Uses `gh` auth as already configured.
- Needs access to: GitHub through the authenticated `gh` CLI (read PR comments, post replies, resolve threads).
- File scopes: `<repo>/**` (read and edit for approved fixes), `<repo>/CLAUDE.md`, `<repo>/REVIEW.md`, `<repo>/**/.claude/rules/*.md` (read only).
- Notes: The gather script only writes to stdout and a temporary folder it deletes on exit. Replies, pushes and thread resolution happen only after you approve them. It does not read secret files or manage credentials itself.

## 10. Known limitations

- Requires `gh` installed and logged in, and `python3`.
- Must run inside a git repo with a GitHub remote.
- Triage is interactive, so it is not suited to unattended runs.
- By default only unresolved threads whose last comment is not yours are shown. Use `-all` to include the rest.
- With more than 30 threads it shows a per-file table first and works file by file.
- Fixes are not committed automatically. Commit, push, replies and resolving each need your confirmation.
- It never resolves Clarify or Disagree threads, since the reviewer answers those.
- Does not expand scope. Extra issues found during a fix are noted and you are asked first.

## 11. FAQ

**Q:** How do I install it?
A: Download the zip from Agensi and add it to your Claude Code skills folder. It is also installable as a plugin from https://github.com/IamBiswajitSahoo/ClaudeSkills.

**Q:** What do I need before running it?
A: Claude Code, the `gh` CLI signed in to GitHub, `python3`, and a git repo with a GitHub remote.

**Q:** Will it change my code or post to GitHub without asking?
A: No. You choose an action for every thread. It does not commit on its own, does not push without confirmation, and posts only replies you approved.

**Q:** What if the reviewer is wrong?
A: It labels the thread Disagree and drafts a short reply with the reason. It does not agree just to avoid friction.

**Q:** Does it follow my project's conventions?
A: Yes. It loads CLAUDE.md, REVIEW.md and `.claude/rules/*.md` from the repo root and from folders above commented files, and checks fixes against them.

**Q:** Does it add AI attribution to commits or replies?
A: No. Its rules forbid Co-Authored-By lines and any generated-by footer in commits and replies.

**Q:** Can I see threads I already answered or that are resolved?
A: Yes. Add `-all`, for example `/github-pr-resolve 128 -all`.
