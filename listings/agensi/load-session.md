# load-session: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is an open archive box or folder in white, with a single amber page sliding up and out of it toward a speech bubble, suggesting an old conversation being pulled back into a new one.

## 2. Skill name

Load Session

Slug: `load-session`

## 3. Skill summary

Bring an earlier Claude Code session into the current one as a short summary or the full transcript.

## 4. Full description

**What it does**
- Lists your recent Claude Code sessions across all projects, with name, project, branch, message count, size and age.
- Loads a session by picking it from the list or by name or UUID.
- Shows a size and token estimate before loading, and warns if a full transcript would fill much of the context window.
- Offers two modes: a compact summary (about 500 to 1000 tokens) or the full transcript.
- Recommends one of 7 summary templates based on the session, and also accepts your own prompt or template file.

**Problems it solves**
- Resuming work without re-explaining what happened last time.
- Finding the right old session when you never named it.
- Avoiding a huge transcript landing in your context by accident.
- Handing a session off to a colleague or a fresh session.

**How it works**
1. Checks for Python, then lists sessions (paginated) or resolves the name you gave.
2. Estimates messages, duration and tokens, then asks for compact or full mode. It refuses to load the current session into itself.
3. Compact mode: detects a recommended template (Quick, Default, Decisions, Actions, Discussion, Timeline, Handoff or Custom), you choose one, the transcript is written to a temp file, and a summarizer sub-agent reads it and returns only the summary.
4. Full mode: writes the transcript to a temp file, reads it into the conversation, and deletes the file.
5. Prints a short report: session, mode and estimated tokens added.

**Why install it**
- Free and open source (Apache-2.0).
- In compact mode the transcript never passes through your main context, so cost stays roughly flat for big sessions.
- Temp files are always cleaned up.

**Requirements**
- Claude Code with access to `~/.claude/projects`.
- Python 3.

## 5. The request

```
/load-session payments-refactor
```

Or in plain language: "Load my payments-refactor session from yesterday as a handoff summary."

## 6. The result

The skill resolved `payments-refactor`, confirmed it is not the current session, and showed the estimate. The session had 64 user and 71 assistant messages over 148 minutes, 2.3 MB on disk. Full mode would cost about 61,000 tokens, so you chose compact. The detector recommended Handoff because the session ended mid-task. A sub-agent summarized the transcript and deleted the temp file.

```
Session: payments-refactor
Messages: 64 user + 71 assistant | Duration: 148 min | Size: 2.3 MB

1. Compact summary (recommended): ~500-1000 tokens
2. Full transcript: ~61,000 tokens (warning: uses 31% of context window)
3. Cancel
```

---
**Loaded session:** payments-refactor (compact: Handoff)

**Subjective: What the user wanted**
- Replace the hand-rolled retry loop in `src/billing/charge.ts` with the shared `withRetry` helper.
- Keep the public `chargeCustomer()` signature unchanged because the mobile app depends on it.
- Familiar with the codebase; wanted minimal diffs.

**Objective: What actually happened**
- Edited `src/billing/charge.ts` and `src/lib/retry.ts`; added `tests/billing/charge.retry.test.ts`.
- Ran `npm test`: 212 passed, 2 failed in `charge.retry.test.ts` (timeout at 5000 ms).
- Hit error `ERR_IDEMPOTENCY_KEY_REUSED` when the retry reused the same key.

**Assessment: Analysis and conclusions**
- The retry helper must generate a fresh idempotency key per attempt only for network errors, not for card declines.
- Decision: keep exponential backoff but cap at 3 attempts.
- Risk: webhook handler `src/billing/webhooks.ts` still assumes one attempt per charge.

**Plan: What comes next**
- Fix the 2 failing tests by faking timers in `charge.retry.test.ts`.
- Add the idempotency key rule to `withRetry` options.
- Review `webhooks.ts` for duplicate-event handling.
- Open question: should the attempt cap be configurable per merchant?

---
**Session loaded:** payments-refactor
**Mode:** compact (Handoff)
**Estimated tokens added:** ~650

Next steps
- Ask Claude to continue with the two failing tests in `charge.retry.test.ts`.
- If you need exact wording from a message, run the skill again and choose full mode.
- Try the Decisions template if you only need the reasoning behind the retry cap.

## 7. Compatibility note

Built for and tested on Claude Code only. It reads session transcripts that Claude Code stores under `~/.claude/projects`, so it will not work in other agents or tools that do not keep sessions there. It depends on the Agent tool (a sub-agent for summaries), AskUserQuestion for the menus, `${CLAUDE_SKILL_DIR}`, and slash-command invocation. Other SKILL.md agents are not tested.

## 8. Categories, tags, use cases

- Categories: Productivity, Workflow Automation, Agents & Orchestration
- Tags: claude-code, session, context, summary, transcript, handoff, resume, history, sub-agent
- Use cases:
  - Resuming yesterday's work in a fresh session
  - Handing a session off to a teammate
  - Recalling decisions from a past design discussion
  - Getting a changelog-style recap of files changed
  - Finding an old session you never named

## 9. Permissions

- Tools used:
  - Terminal / Shell: yes. Runs the bundled Python scripts and `rm -f` on the temp transcript.
  - Read Files: yes. Reads session files in `~/.claude/projects` and the temp transcript.
  - Write Files: yes. Writes one temp transcript file (`bix-load-session-*.md`) and deletes it.
  - Browser: no.
  - Network Access: no. The scripts make no network calls.
  - Environment Variables: yes, minimal. Reads `TMPDIR` for temp location cleanup.
- Needs access to: None (no external accounts or services).
- File scopes:
  - Read: `~/.claude/projects/**/*.jsonl`, `${CLAUDE_SKILL_DIR}/templates/*.md`
  - Write and delete: `${TMPDIR:-/tmp}/bix-load-session-*.md`
- Notes: The skill needs to read your past session files to list and load them. It writes only a temporary transcript, then deletes it. It does not modify, move or delete your session files. It does not read other parts of `~/.claude`.

## 10. Known limitations

- Claude Code only. It depends on the `~/.claude/projects` session layout.
- Requires Python 3 (`python3` or `python`). It stops if neither is found.
- It cannot load the current session into itself.
- Only user text, assistant text and completed sub-agent results are kept. Tool calls and tool results are dropped from the transcript.
- Sub-agent results in a transcript are cut at 2,000 characters each.
- Full mode puts the whole transcript in context. Large sessions can use a big share of the window, so check the estimate.
- Token counts are estimates (about 4 characters per token).
- Compact mode needs a sub-agent. On a standalone install it runs as a general-purpose Sonnet sub-agent using the bundled summarizer instructions, and temp-file cleanup is done by the skill instead of a hook.

## 11. FAQ

**Q:** How do I install it?
A: On Agensi, download the zip and place it in your Claude Code skills folder. Or install the plugin from GitHub: `/plugin marketplace add IamBiswajitSahoo/ClaudeSkills` then `/plugin install bix-session@Biswajit-Claude-Skills`.

**Q:** What do I need?
A: Claude Code and Python 3. Sessions must exist under `~/.claude/projects`.

**Q:** Does it change my sessions or project files?
A: No. It reads session files and writes one temp transcript, which it deletes afterward. It asks you to pick the session and mode before loading anything.

**Q:** What if a run crashes and leaves a temp file?
A: The plugin has a SessionStart hook that removes `bix-load-session-*.md` files older than 60 minutes. On a standalone install the skill runs the same cleanup at the start.

**Q:** How many tokens does it use?
A: Compact mode adds roughly 500 to 1000 tokens to your context. A Sonnet sub-agent reads the transcript, so that work is billed separately from your main context. Full mode adds the whole transcript, and the skill shows the estimate first.

**Q:** Can I name sessions so they are easier to find?
A: Yes. Use `/rename my-name` in Claude Code, or start with `claude -n "my-name"`. Then run `/load-session my-name`. Unnamed sessions show their first message instead.

**Q:** Can I use my own summary format?
A: Yes. Choose Custom and give inline text or a path to a `.md` or `.txt` file.
