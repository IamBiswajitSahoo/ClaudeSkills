# github-pr-describe: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is a document page with a folded corner, showing three short bullet lines and a small table grid at the top, with an amber upward arrow leaving the page to suggest the text being published.

## 2. Skill name

PR Description Generator

Slug: `github-pr-describe`

## 3. Skill summary

Reads a pull request diff, drafts a structured description, and pushes it to GitHub after you approve.

## 4. Full description

**What it does**
- Fetches a PR's metadata and full diff with the `gh` CLI.
- Groups changes by area and drafts a description from a fixed template.
- Starts with a TL;DR table and 3 to 5 bullets, then adds only the sections that apply (Features, Bug Fixes, Improvements, Refactoring, Documentation, Tests, Dependencies, CI/CD).
- Keeps ticket and issue links from the existing PR body under a `**Tickets:**` line.
- Shows the full draft and waits for you to choose Post or Edit before touching GitHub.

**Problems it solves**
- Blank or one-line PR bodies that leave reviewers guessing.
- Long, jargon-heavy descriptions that take two reads to follow.
- Losing ticket links when a PR body is rewritten.
- Large diffs that are slow to summarize by hand.

**How it works**
1. Validate the PR number (asks if missing) and gather metadata and diff as JSON. Stops if the diff is empty.
2. Analyze the diff, skipping whitespace-only changes, and group changes by area. Diffs over 5,000 lines go to a sub-agent for a per-file summary.
3. Draft the description from the template, with plain, short writing rules and no invented changes.
4. Show the draft and ask: Post or Edit. Repeat edits until you approve.
5. Run `gh pr edit` with exactly the approved text and print the PR URL.

**Why install it**
- Free and open source (Apache-2.0).
- Consistent PR descriptions across a team.
- Nothing is pushed without your approval.
- Adds no AI attribution or footer to the description.

**Requirements**
- Claude Code, `gh` CLI (authenticated), `python3`, and a git repo with a GitHub remote.

## 5. The request

```
/github-pr-describe 214
Describe PR 214 and push the description when I approve it.
```

## 6. The result

I analyzed PR #214 (`feature/saved-filters` into `main`, 9 files, 412 lines of diff) and drafted a description. The existing body had one ticket link, which I kept at the top. Nothing has been pushed yet.

```markdown
**Tickets:** SHOP-1187

## TL;DR

| Area | Files | What Changed |
|------|-------|--------------|
| Order list UI | `OrderFilters.tsx`, `SavedFilterMenu.tsx` | Save and reuse filter sets |
| API | `filters.controller.ts`, `filters.service.ts` | New saved filter endpoints |
| Database | `20241003_add_saved_filters.sql` | New `saved_filters` table |
| Tests | `filters.service.test.ts` | Coverage for saved filters |

- Users can save the current order filters under a name and reapply them later.
- The API has new endpoints to list, create and delete saved filters.
- Fixed the date range filter dropping the last day.

---

## Features

- **Saved filters on the order list** - A new menu lets users save the current filters under a name and pick them again. This saves support staff from rebuilding the same filters each day.
- **Saved filter endpoints** - Added `GET`, `POST` and `DELETE /api/filters`. Each user only sees their own filters.

## Bug Fixes

- **Date range ignored the last day** - The end date was treated as midnight, so orders placed on that day were left out. It now includes the whole day.

## Improvements

### Order list UI
- **Filter bar stays on screen** - The filter bar no longer scrolls away on long lists, so filters can be changed without scrolling back up.

## Tests

- **Saved filter service tests** - Added tests for creating, listing and deleting filters, and for blocking access to another user's filters.
```

**Next steps**
- Reply **Post** to run `gh pr edit 214` with this text, or **Edit** with changes (for example "shorten the Features section").
- After posting, the skill prints the PR URL so you can check the result.

## 7. Compatibility note

Built for and tested on Claude Code. It uses AskUserQuestion for the approval step, `${CLAUDE_SKILL_DIR}` to find its script and template, the Agent tool for very large diffs, and slash-command invocation. Other agents that read SKILL.md files may run parts of it, but they are not tested.

## 8. Categories, tags, use cases

- Categories: Code Quality & Review, Technical Documentation, Workflow Automation
- Tags: github, pull-request, pr-description, code-review, gh-cli, changelog, documentation, git
- Use cases:
  - Writing a PR body before requesting review
  - Replacing an empty or one-line PR description
  - Summarizing large diffs for reviewers
  - Keeping PR descriptions consistent across a team
  - Preserving ticket links while rewriting a PR body

## 9. Permissions

- Tools used:
  - Terminal / Shell: yes. Runs `gather-pr-info.sh` and `gh pr edit`.
  - Read Files: yes. Reads its own template and the script output.
  - Write Files: no. The script writes its diff to a temp file and deletes it on exit. The skill creates no project files.
  - Browser: no.
  - Network Access: yes, only through `gh` to the GitHub API.
  - Environment Variables: no. It uses `gh`'s existing login and reads no variables directly.
- Needs access to: GitHub via the authenticated `gh` CLI (read PR, edit PR body).
- File scopes: `<skill folder>/scripts/gather-pr-info.sh`, `<skill folder>/templates/description.md`, a system temp file (removed after use).
- Notes: The skill needs `gh` to read the PR and, after your approval, to update its body. It does not change code, branches, commits, labels or reviews. It does not read credentials or secret files.

## 10. Known limitations

- Needs `gh` installed and authenticated, and must run inside a repo with a GitHub remote.
- Needs `python3` (the script uses it to escape the diff as JSON).
- Takes a PR number only. It does not accept URLs or branch names.
- Stops if the PR has no diff.
- Diffs over 5,000 lines are summarized by a sub-agent first, so fine detail may be lost.
- It replaces the whole PR body. Only ticket links found in the old body are carried over.
- The script was written for a Bash environment (macOS or Linux). Windows is not documented.
- The description is only as accurate as the diff. It does not run code or tests.

## 11. FAQ

**Q:** How do I install it?
A: Install the full set as a Claude Code plugin from https://github.com/IamBiswajitSahoo/ClaudeSkills, or unzip the Agensi download into your skills folder.

**Q:** What do I need before running it?
A: The `gh` CLI logged in with `gh auth login`, `python3`, and a terminal opened inside the repo that holds the PR.

**Q:** Will it overwrite my PR description without asking?
A: No. It shows the full draft and asks Post or Edit. It only runs `gh pr edit` after you choose Post, and pushes exactly the approved text.

**Q:** Does it add a "Generated with" footer or co-author line?
A: No. The skill forbids any AI attribution in the description.

**Q:** Does it use a lot of tokens?
A: It reads the whole diff once. For diffs over 5,000 lines it hands the reading to a sub-agent and works from a per-file summary, which keeps the main session smaller.

**Q:** What if my PR already links a ticket?
A: Links such as `#123`, `JIRA-456` or issue-tracker URLs in the current body are placed under `**Tickets:**` at the top of the new description.
