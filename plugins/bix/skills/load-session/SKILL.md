---
name: load-session
description: Load context from a previous Claude Code session into the current one — browse sessions, choose compact summary or full transcript, with smart template auto-selection.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: "[session-name]"
---

# Load Session

Load a previous Claude Code session into the current conversation as either a compact summary (default) or the full transcript.

**Arguments:** `$ARGUMENTS` — optional session name to skip the browse step.

**Token-efficiency design:** the transcript itself never flows through this main context. The parser writes it to a temp file, the `session-summarizer` sub-agent reads the file directly, and the file is deleted afterward. Cost is roughly constant regardless of session size.

---

## Phase 1: Prereqs & Browse

Check Python is available: `python3 --version 2>/dev/null || python --version 2>/dev/null`. If neither works, stop and tell the user to install Python 3. Store the working command as `{PY}`.

If `$ARGUMENTS` is non-empty, treat it as a session name and skip to Phase 2. Otherwise, list sessions:

```bash
{PY} "${CLAUDE_SKILL_DIR}/scripts/list-sessions.py" --page 1 --compact
```

Returns `{page, total_pages, total, sessions: [{i, uuid, jsonl_path, name, project, branch, msgs, size, last}]}`.

Render as a table via `AskUserQuestion`:

> **Select a session** (page {page}/{total_pages}, {total} total)
>
> | # | Session | Project | Branch | Msgs | Size | Last |
> |---|---------|---------|--------|------|------|------|
> | 1 | {name} | {project} | {branch} | {msgs} | {size} | {last} |
>
> Enter a number, **N/P** for next/prev page, or **C** to cancel.

On selection, extract that row's `uuid` and `jsonl_path` directly — no second resolve call needed. On `N`/`P`, re-run with updated `--page`. On `C`, stop.

---

## Phase 2: Estimate & Choose Mode

If we arrived here from `$ARGUMENTS` (no `jsonl_path` in hand), resolve it:

```bash
{PY} "${CLAUDE_SKILL_DIR}/scripts/resolve-session.py" "<name-or-uuid>"
```

Stop on `error`. Refuse to load the current session: if the resolved `uuid` matches `${CLAUDE_SESSION_ID}`, stop with "Cannot load the current session into itself."

Estimate context cost:

```bash
{PY} "${CLAUDE_SKILL_DIR}/scripts/estimate-context.py" "<jsonl_path>"
```

Returns `{file_size_human, user_messages, assistant_messages, estimated_tokens_text, context_pct_full, duration_minutes, budget_warning}`.

Present the metrics and mode choice via `AskUserQuestion`:

> **Session:** {name}
> **Messages:** {user_messages} user + {assistant_messages} assistant | **Duration:** {duration_minutes} min | **Size:** {file_size_human}
>
> 1. **Compact summary** (recommended) — ~500–1000 tokens
> 2. **Full transcript** — ~{estimated_tokens_text} tokens{warning}
> 3. **Cancel**

If `budget_warning` is true, append `⚠ uses {context_pct_full}% of context window` to option 2.

`1` → Phase 3a. `2` → Phase 3b. `3` → stop.

---

## Phase 3a: Compact Mode

### Detect template

```bash
{PY} "${CLAUDE_SKILL_DIR}/scripts/detect-template.py" "<jsonl_path>"
```

Returns `{recommended_template, confidence, reason}`.

### Pick template (via `AskUserQuestion`)

Present 8 options. Mark `recommended_template` with "← recommended ({reason})":

1. **Quick** — fast single-pass gist
2. **Default** — Chain-of-Density entity-dense summary
3. **Decisions** — architectural choices and trade-offs
4. **Actions** — files changed, what was done, why
5. **Discussion** — questions, findings, open threads
6. **Timeline** — chronological phases
7. **Handoff** — goals/actions/assessment/next steps
8. **Custom** — provide your own prompt

For options 1–7, read `${CLAUDE_SKILL_DIR}/templates/summary-{template_name}.md` and store the contents as `{template_text}`.

For option 8: ask via `AskUserQuestion` for a path (`.md`/`.txt`) or inline text. If it looks like a file path that exists, read the file; otherwise use the response verbatim.

### Write transcript to a temp file

```bash
{PY} "${CLAUDE_SKILL_DIR}/scripts/parse-session.py" "<jsonl_path>" --out-file auto
```

Returns `{transcript_path, char_count, estimated_tokens, entries}`. **Do not print the transcript.** Capture `transcript_path`.

### Delegate to the `session-summarizer` sub-agent

> **CRITICAL:** Invoke the sub-agent via the **Agent** tool with `subagent_type: "bix:load-session:session-summarizer"`. Do NOT summarize the transcript inline. Do NOT use `claude --resume`. The fully-qualified `bix:load-session:` prefix is required, otherwise the call silently falls back to `general-purpose` on the parent model.

Pass this prompt to the sub-agent (template text inline, transcript only by reference):

```
transcript_path: {transcript_path}

Read the transcript file and summarize it using the template below. After summarizing, delete the transcript file with `rm -f`.

---
TEMPLATE:

{template_text}
```

Set `description` to `"Summarize session: {name}"`.

The sub-agent returns the summary text directly. If it returns an error or empty text, run `rm -f "<transcript_path>"` yourself and tell the user to try a different template or full mode.

### Inject the summary

> ---
> **Loaded session:** {name} (compact — {template_name})
>
> {summary_text}
>
> ---

Proceed to Phase 4.

---

## Phase 3b: Full Mode

The full transcript must reach main context for this mode (that's the point), but still write through a temp file so cleanup is uniform:

```bash
{PY} "${CLAUDE_SKILL_DIR}/scripts/parse-session.py" "<jsonl_path>" --out-file auto
```

Then read the file with the **Read** tool, output its contents to the user, and delete the file:

```bash
rm -f "<transcript_path>"
```

Proceed to Phase 4.

---

## Phase 4: Summary

> **Session loaded:** {name}
> **Mode:** compact ({template_name}) | full
> **Estimated tokens added:** ~{N}

---

## Rules

- **Never load the current session into itself** — compare resolved UUID against `${CLAUDE_SESSION_ID}`.
- **Never print the transcript via Bash** — always use `--out-file` and let the sub-agent (compact) or Read tool (full) consume it.
- **Always delegate compact summarization** to `bix:load-session:session-summarizer`. Never inline. Never via `claude --resume`.
- **Always clean up the temp file** — the sub-agent does it in compact mode; the skill does it in full mode. The SessionStart hook is a safety net for crashes.
- **Always show token estimates** before loading full mode and require confirmation.
- Scripts return JSON with an `error` field on failure — check and surface it.
