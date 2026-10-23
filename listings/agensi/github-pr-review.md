# github-pr-review: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is a white speech bubble with a large check mark inside it, and a small amber flag pinned to its top corner, suggesting reviewed feedback on a change. Two short white code-line bars sit behind the bubble.

## 2. Skill name

**GitHub PR Review**

Slug: `github-pr-review`

## 3. Skill summary

Review a GitHub PR, rank findings by severity, and post a batched pending review after you approve each comment.

## 4. Full description

**What it does**
- Reviews a pull request across 5 categories: correctness, project conventions, performance, security and test coverage.
- Labels every finding Critical, Warning or Nit.
- Tags issues that were already in the code before the PR as [Pre-existing] and lists them last.
- Checks missing or stale doc comments on public APIs for 10 languages.
- Reads your repo's CLAUDE.md and REVIEW.md and treats them as extra review rules.
- Optional parallel mode with 6 sub-agents for large PRs.

**Problems it solves**
- Slow first-pass reviews on big diffs.
- Inconsistent feedback between reviewers.
- Comments posted on the wrong line, or rejected by the GitHub API.
- Noisy bot reviews that post everything without a human check.
- Long, hard-to-read review comments.

**How it works**
1. Validate the PR number, fetch the diff, metadata and project rules with `gh`, and check if the PR is a draft, closed or already reviewed.
2. Analyze the diff in single mode, or in parallel mode with 6 sub-agents (parallel is offered when the diff is over 3000 lines). Drop duplicates and tag pre-existing issues with git blame.
3. Review doc comments on public APIs (single mode).
4. Approve each comment: Post, Skip or Modify. Then confirm the final submit.
5. Create one pending review with all approved comments, then submit it as REQUEST_CHANGES, COMMENT or APPROVE.
6. Show posted and skipped counts and the PR link.

**Why install it**
- Free and open source (Apache-2.0).
- Nothing is posted without your explicit approval.
- Short, plain comments with one-click suggestion blocks.
- One batched review means one notification for the author.

**Requirements**
- Claude Code, the `gh` CLI (authenticated), `git` and `python3`.
- Run it inside a git repo with a GitHub remote.

## 5. The request

```
/github-pr-review 482
```

```
Review PR 482 and let me approve each comment before you post anything
```

## 6. The result

I reviewed PR #482 ("Add token refresh to the auth client") in the `acme-api` repo. The PR changes 6 files and has 410 diff lines, so I used single mode. I drafted 4 findings: 1 Critical, 1 Warning and 2 Nits. One of them is tagged Pre-existing. The PR is open and not a draft, and you have not reviewed it before. Project rules were read from CLAUDE.md.

Approval prompts, shown one at a time with the options Post / Skip / Modify:

```
[Critical] Comment 1 - `src/auth/refresh.ts` line 20: Missing null check on refresh token

`refreshToken` can be `undefined` when the user has signed out, so `token.trim()` throws. Return early when it is missing.

```suggestion
  if (!refreshToken) return null;
```
```

```
[Warning] Comment 2 - `src/auth/refresh.ts` line 55: Query runs inside a loop

`getUser` is called once per retry. Move it above the loop and reuse the result.
```

```
[Nit] Comment 3 - `src/config.ts` line 8: Unnamed number

`3600` is the token lifetime in seconds. Give it a name such as `TOKEN_TTL_SECONDS`, like the other settings in this file.
```

```
[Warning] [Pre-existing] Comment 4 - `src/db/users.ts` line 30: Unchecked input in SQL

The email is joined into the query string. This line was not changed in this PR. Use a parameterized query.
```

Summary after approval:

```
Posted:  Comment 1 (src/auth/refresh.ts:20) [Critical], Comment 3 (src/config.ts:8) [Nit]
Skipped: Comment 2 (src/auth/refresh.ts:55) [Warning], Comment 4 (src/db/users.ts:30) [Warning] [Pre-existing]
Event type: REQUEST_CHANGES
```

Ready to submit the review with 2 comments? Submit / Cancel. On Submit, the review was created as pending on the latest commit, then submitted as REQUEST_CHANGES because a Critical comment was posted. Final count: 2 posted, 2 skipped, with the PR link at the end.

**Next steps**
- Ask the author to fix the Critical comment, then run `/github-pr-review 482` again.
- Open a separate issue for the pre-existing SQL input problem.
- Use `-parallel` on very large PRs.

## 7. Compatibility note

Built for and tested on Claude Code. It uses the Agent tool (sub-agents with model choice), AskUserQuestion for every approval, `${CLAUDE_SKILL_DIR}` for its bundled script and templates, and slash-command invocation. Other agents that read SKILL.md may run parts of it, but they are not tested.

## 8. Categories, tags, use cases

- Categories: Code Quality & Review, Workflow Automation, Security
- Tags: github, pull-request, code-review, pr-review, gh-cli, severity, review-comments, parallel-agents
- Use cases:
  - Reviewing a teammate's PR before merge
  - First-pass review of large diffs
  - Security and test-gap checks on a PR
  - Finding missing or stale API doc comments
  - Posting one batched review with human approval

## 9. Permissions

- Terminal / Shell: Yes. Runs `gather-pr-context.sh`, `gh`, `git blame` and `python3`.
- Read Files: Yes. Reads the repo's CLAUDE.md and REVIEW.md and source files for context.
- Write Files: No. It does not write files in your project. The script only uses a temp directory that it removes on exit.
- Browser: No.
- Network Access: Yes, only through `gh` to the GitHub API (fetch the PR, post the review).
- Environment Variables: No. It uses the existing `gh` login and does not read tokens itself.

Needs access to: GitHub through an authenticated `gh` CLI.

File scopes:
- `<repo>/CLAUDE.md` (read)
- `<repo>/REVIEW.md` (read)
- `<repo>/**` (read, for context and git blame)
- No writes

Notes: The skill needs the shell to call `gh` and `git`, and network access to read the PR and create the review. It reads CLAUDE.md and REVIEW.md to follow your team rules. It never edits your code, never pushes commits, and never posts a comment or submits a review without your approval.

## 10. Known limitations

- Needs the `gh` CLI installed and logged in (`gh auth login`), plus `git` and `python3`.
- Must run inside a git repo with a GitHub remote. It works on GitHub only.
- Doc review covers 10 languages: JavaScript, TypeScript, Python, Go, C#, Rust, Java, Ruby, Kotlin, PHP and Swift. It is skipped when the main language is not detected or not supported.
- The main language is picked by counting changed files by extension, so mixed-language PRs get one language for doc review.
- Pre-existing issue detection can be inaccurate when your checked-out branch is not the PR branch. The skill warns you in that case.
- Parallel mode starts 6 sub-agents and uses more tokens. The doc agent is skipped when the language is unsupported.
- It only comments on lines visible in the diff. Issues outside the diff are noted but not included in the review.
- Findings come from the model reading the diff. They are not a replacement for a human review.

## 11. FAQ

**Q:** How do I install it?
A: Download the zip from Agensi and add it to your Claude Code skills folder. You can also install the whole set as a Claude Code plugin from https://github.com/IamBiswajitSahoo/ClaudeSkills.

**Q:** What do I need before running it?
A: The `gh` CLI logged in to GitHub, `git`, `python3`, and a local clone of the repo you are reviewing. Run it from inside that clone.

**Q:** Will it post comments without asking?
A: No. Each comment needs Post, Skip or Modify from you. Then you confirm the final submit. All approved comments go into one pending review.

**Q:** What does it change in my repo?
A: Nothing locally. It only reads files. On GitHub it creates one review on the PR after you approve it.

**Q:** Does it cost many tokens?
A: Single mode is the cheaper option. Parallel mode (`/github-pr-review 482 -parallel`) is faster on large diffs but uses more tokens. If the diff is over 3000 lines, the skill asks you to choose.

**Q:** Which review event does it send?
A: REQUEST_CHANGES if any Critical comment was posted, COMMENT if only Warnings or Nits were posted. With zero comments you choose APPROVE or COMMENT.

**Q:** Can it follow my team's rules?
A: Yes. If CLAUDE.md or REVIEW.md exists in the repo root, its rules are added to the review criteria and win on conflict.
