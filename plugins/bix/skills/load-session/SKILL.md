---
name: load-session
description: Load context from a previous Claude Code session into the current one — browse sessions, choose compact summary or full transcript, with smart template auto-selection.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: "[session-name]"
---

# Load Session

Load context from a previous Claude Code session into the current conversation. Supports compact (summarized) and full (raw transcript) modes.

**Arguments:** `$ARGUMENTS` — optional session name to skip the browse step.

---

## Phase 1: Parse & Browse

### Step 1 — Check prerequisites

Verify Python 3 is available:

```bash
python3 --version 2>/dev/null || python --version 2>/dev/null
```

If neither command succeeds, stop and display:

> **Python 3 is required but was not found on your system.**
>
> Install Python 3 to use this skill:
> - **macOS:** `brew install python3`
> - **Linux:** `sudo apt install python3`
> - **Windows:** Download from https://www.python.org/downloads/

Store the working python command (`python3` or `python`) for use in later phases.

### Step 2 — Parse arguments

Extract the optional session name from `$ARGUMENTS`:
- If `$ARGUMENTS` is not empty, treat it as the session name → skip to Phase 2.
- If `$ARGUMENTS` is empty → proceed to Step 3 (browse sessions).

### Step 3 — Browse sessions

Run the list script to fetch recent sessions:

```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/list-sessions.py" --page 1
```

The script outputs JSON with:
- `total` — total session count
- `page`, `per_page`, `total_pages` — pagination info
- `projects` — list of unique project paths (for project tabs)
- `sessions` — array of session objects with `uuid`, `display_name`, `is_named`, `project`, `project_short`, `file_size_bytes`, `file_size_human`, `message_count`, `started_at`, `started_at_short`, `last_modified`, `last_modified_relative`, `git_branch`

Present the sessions to the user via `AskUserQuestion`. Format as a table-style list with aligned columns. Each row shows the key details at a glance:

> **Select a session to load** (page {page} of {total_pages}, {total} sessions)
>
> | # | Session | Project | Branch | Messages | Size | Last active |
> |---|---------|---------|--------|----------|------|-------------|
> | 1 | {display_name} | {project_short} | {git_branch} | {message_count} | {file_size_human} | {last_modified_relative} |
> | 2 | ... | ... | ... | ... | ... | ... |
>
> Enter a **number** to select, **N/P** for next/prev page, or **C** to cancel.

Formatting rules:
- Truncate `display_name` to 50 characters max, append "..." if truncated
- If `git_branch` is empty, show "—"
- If `last_modified_relative` is empty, show the `started_at_short` value instead
- Show the `project_short` (last path component) not the full path — keeps the table compact

If the user selects a session number, extract its `uuid` and `display_name`.
If the user types "N" or "P", re-run the list script with the updated `--page` value.
If the user types a project name, re-run with `--project <name>`.
If the user types "C", stop the skill.

---

## Phase 2: Analyze & Choose Mode

### Step 1 — Resolve session

If we have a session name (from arguments or browse selection), resolve it to a UUID and JSONL path:

```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/resolve-session.py" "<session-name-or-uuid>"
```

The script outputs JSON with:
- `uuid` — the session UUID
- `jsonl_path` — full path to the JSONL file
- `project` — decoded project path
- `display_name` — the session's custom title (if named)
- `error` — if resolution failed, display this to the user and stop

If the output contains `error`, display it and stop.

### Step 2 — Estimate context budget

Run the estimator on the resolved JSONL file:

```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/estimate-context.py" "<jsonl_path>"
```

The script outputs JSON with:
- `file_size_human` — human-readable file size
- `user_messages`, `assistant_messages` — message counts
- `estimated_tokens_full` — estimated tokens for the full transcript
- `estimated_tokens_text` — estimated tokens for text-only content
- `context_pct_full` — percentage of 1M context window
- `duration_minutes` — session duration
- `budget_warning` — true if >40% of context window

### Step 3 — Choose loading mode

Present the metrics and mode options via `AskUserQuestion`:

> **Session:** {display_name}
> **Messages:** {user_messages} user + {assistant_messages} assistant | **Duration:** {duration_minutes} min | **Size:** {file_size_human}
>
> **Choose loading mode:**
> 1. **Compact summary** (recommended) — ~{estimated_summary_tokens} tokens
> 2. **Full transcript** — ~{estimated_tokens_text} tokens {budget_warning_text}
> 3. **Cancel**

For the budget warning text, if `budget_warning` is true, append: "⚠ This would use {context_pct_full}% of your context window"

Estimate summary tokens as roughly 500-1000 tokens (summaries are concise regardless of input size).

If the user selects 1 → proceed to Phase 3a (Compact).
If the user selects 2 → proceed to Phase 3b (Full).
If the user selects 3 → stop the skill.

---

## Phase 3a: Compact Mode — Summarize

### Step 1 — Detect recommended template

Run the template detector:

```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/detect-template.py" "<jsonl_path>"
```

The script outputs JSON with:
- `recommended_template` — template name (quick, default, decisions, actions, discussion, timeline, handoff)
- `confidence` — high, medium, or low
- `reason` — why this template was recommended

### Step 2 — Choose template

Present the templates via `AskUserQuestion`, highlighting the recommended one:

> **Choose a summarization template** (recommended: **{recommended_template}** — {reason}):
>
> 1. **Quick** — fast single-pass gist (cheapest)
> 2. **Default** — balanced, entity-dense summary (Chain-of-Density)
> 3. **Decisions** — architectural choices and trade-offs only
> 4. **Actions** — files changed, what was done, and why
> 5. **Discussion** — questions, findings, open threads
> 6. **Timeline** — chronological phases
> 7. **Handoff** — structured goals/actions/assessment/next steps
> 8. **Custom** — provide your own summarization prompt

Mark the recommended template with "← recommended" in the list.

If the user selects 1-7, read the corresponding template file:
```bash
cat "${CLAUDE_SKILL_DIR}/templates/summary-{template_name}.md"
```

If the user selects 8 (Custom), use `AskUserQuestion`:
> "Provide your summarization prompt (text) or path to a template file (.md or .txt):"

If the response is a file path, read the file. Otherwise, use the text as the prompt directly.

### Step 3 — Extract transcript

Parse the session into a markdown transcript using the same parser as Full mode:

```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/parse-session.py" "<jsonl_path>" --format markdown
```

Store the full transcript output — this will be passed to the summarization agent.

### Step 4 — Summarize via the `session-summarizer` sub-agent

> **CRITICAL: You MUST delegate summarization to the `session-summarizer` sub-agent. Do NOT summarize the transcript yourself. Do NOT use `claude --resume`. Do NOT use Bash.**

This plugin provides a `session-summarizer` sub-agent (defined in `plugins/bix/agents/load-session/session-summarizer.md`). Invoke it using the **Agent** tool with `subagent_type: "bix:load-session:session-summarizer"`.

Pass the transcript and template as the task prompt:

```
Summarize the following session transcript using the template below.

---
TRANSCRIPT:

{transcript_text}

---
SUMMARIZATION TEMPLATE:

{template_prompt_text}
```

Set `description` to `"Summarize session: {display_name}"`.

The sub-agent's returned result is the summary text. Use it directly in Step 5.

If the sub-agent returns an error or empty result, inform the user and suggest trying a different template or switching to full mode.

### Step 5 — Inject summary

Output the summary to the user as a clearly-marked block:

> ---
> **Loaded session:** {display_name} (compact — {template_name} template)
>
> {summary_text}
>
> ---

Proceed to Phase 4.

---

## Phase 3b: Full Mode — Transcript

### Step 1 — Parse the session

Run the parser to extract the conversation transcript:

```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/parse-session.py" "<jsonl_path>" --format markdown
```

The script outputs a markdown-formatted transcript with:
- Session header (title, branch, message count, estimated tokens)
- User messages with timestamps
- Assistant messages with timestamps
- Subagent final results (prompt + conclusion, not internal tool calls)
- Truncation notice if the output exceeds limits

### Step 2 — Inject transcript

Output the full transcript to the user. The transcript is already formatted as markdown by the parser.

Proceed to Phase 4.

---

## Phase 4: Summary

Report what was loaded:

> **Session loaded:** {display_name}
> **Mode:** {compact|full} {template_name if compact}
> **Estimated tokens added:** ~{token_count}

---

## Rules

- NEVER load a full conversation without showing the token estimate and getting user confirmation first
- ALWAYS present the paginated session browser when no session name argument is given
- ALWAYS show template options for compact mode — auto-highlight the recommended template but let the user choose
- Support custom summarization prompts — inline text or file path to .md or .txt files
- **CRITICAL** — Compact mode summarization MUST delegate to the `session-summarizer` sub-agent via `subagent_type: "bix:load-session:session-summarizer"`. You MUST NOT: (1) run `claude --resume` via Bash, (2) summarize the transcript yourself inline, or (3) use any other approach. Delegating to the sub-agent is a hard requirement, not a suggestion.
- Scripts output JSON with an `error` field on failure — always check for it and display the error to the user
- Do not attempt to load the current active session — it would create a recursive loop
- If the resolved session UUID matches `${CLAUDE_SESSION_ID}`, stop and inform the user: "Cannot load the current session into itself."
