---
name: cleanup
description: Scan and clean up Claude Code's internal data (~/.claude/) to reclaim disk space. Use when the user wants to free up space, check Claude Code disk usage, or clean stale sessions/caches.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
disable-model-invocation: true
argument-hint: "[-all]"
---

# Claude Code Cleanup

Scan `~/.claude/` for deletable data and help the user reclaim disk space.

**Design note:** All classification, sizing, active-session detection, safe deletion, and before/after reporting are handled deterministically by the bundled scripts. You (the model) should not compute sizes, build tables, or decide what is safe — just run the scripts and echo their pre-rendered output verbatim.

## Step 1 — Scan

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"
```

The script emits a single JSON object. The fields you care about:

- `markdown_table` — a fully rendered markdown table (Directory / Size / Contents / Safe to delete), sorted by size descending. **Print this verbatim to the user.**
- `active_sessions_note` — single-line note about protected active sessions. Print it below the table if the count is non-zero.
- `total_human` — total size of `~/.claude/`. Print as "Total: \<value\>" below the note.
- `safe_dirs` — array of directory names classified safe-to-delete. Used for `-all` mode and to build the selection prompt.
- `directories[]` — per-directory records (`name`, `human`, `safe_to_delete`) for constructing the AskUserQuestion options.

Do not recompute or reformat the table. Just `echo` it.

## Step 2 — Select what to delete

### Mode: `/cleanup -all`

If `$ARGUMENTS` contains `-all`, skip the checklist and ask a single confirmation:

> "This will delete all safe directories listed above. Proceed? (yes/no)"

Use `AskUserQuestion`. On "yes", run `delete.sh --all` in Step 3.

### Mode: `/cleanup` (no arguments)

Use `AskUserQuestion` to present a checklist. Build the options list from `directories[]` where `safe_to_delete == "yes"`, in the same order they appear in the scan output (already sorted by size). Each option label should be `<name>/ (<human size>)`.

Record the user's selected directory names — these are the arguments for Step 3.

## Step 3 — Delete (deterministic)

Pass the selected names to `delete.sh`. It handles:

- Hard blocklist (`scripts`, `skills`, `memory`, `ide`, `settings*.json`, `credentials.json`, `CLAUDE.md`) — never touched even if passed as args.
- Active-session protection — reads `sessions/*.json`, checks each `pid`, preserves any UUID transcript/dir whose session is still running.
- `projects/` special-case — preserves `memory/`, `CLAUDE.md`, `settings*.json`, and active session UUIDs; only deletes stale UUID `.jsonl` files and UUID dirs.
- Before/after sizing and the final report table.

```bash
# checklist mode — pass selected names as args
bash "${CLAUDE_SKILL_DIR}/scripts/delete.sh" projects debug telemetry

# -all mode
bash "${CLAUDE_SKILL_DIR}/scripts/delete.sh" --all
```

## Step 4 — Report

`delete.sh` emits JSON. The only field you need to show the user is `markdown_report` — a fully rendered before/after table with a **Total Memory Saved** footer and the new `~/.claude/` size. **Print it verbatim.** Do not rebuild it.

If `skipped` is non-empty, print a one-line note: `Skipped: <contents of skipped field>`.

That's the entire flow: `scan.sh` → AskUserQuestion → `delete.sh` → echo `markdown_report`. No LLM-side computation, no table construction, no size math.
