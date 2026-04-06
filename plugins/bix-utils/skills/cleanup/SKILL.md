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

## Step 1 — Scan

Run the bundled scan script to collect directory sizes:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/scan.sh"
```

The script outputs a JSON object with entries for each directory found. Parse the JSON output.

The script automatically detects **active sessions** by reading `~/.claude/sessions/*.json` and checking if the associated process (pid) is still running. The `project_sessions` object in the output separates stale vs active counts/sizes.

## Step 2 — Build the table

Using the scan results and the directory reference below, display a **markdown table** to the user:

| Directory | Size | What it contains | Safe to delete? |
|-----------|------|------------------|-----------------|

Populate each row from the scan results. For directories not listed in the reference, mark them as "Unknown — investigate before deleting".

Sort rows by size descending so the biggest space consumers are at the top.

After the table, show the **total size** of `~/.claude/`.

If there are active sessions, show a note below the table:
```
Note: X active session(s) detected (Y MB) — these will be preserved.
```

Also scan for `~/Library/Application Support/Claude/vm_bundles/` (macOS) and include it if found — it's the Claude Desktop sandbox VM and is safe to delete if the user only uses Claude Code CLI.

## Step 3 — Select what to delete

### Mode: `/cleanup -all`

If `$ARGUMENTS` contains `-all`:

1. Auto-select all directories marked **"Yes"** in the safe-to-delete column
2. Calculate total space to be reclaimed
3. Show the user which directories you selected and the total savings
4. Use the `AskUserQuestion` tool to ask: "Proceed with deleting the above directories? (yes/no)"
5. Only delete after explicit confirmation

### Mode: `/cleanup` (no arguments)

1. Show the table from Step 2
2. Use the `AskUserQuestion` tool to ask the user which directories they want to clean. Present each safe-to-delete directory as a numbered option. Example:
   ```
   Which directories would you like to clean up?
   1. projects/ session data (45 MB)
   2. debug/ (24 MB)
   3. telemetry/ (2.6 MB)
   4. paste-cache/ (608 KB)
   5. file-history/ (9.7 MB)

   Enter numbers separated by commas (e.g., 1,2,4), or "all" for all safe directories, or "none" to cancel:
   ```
3. Only delete the directories the user selects

## Step 4 — Delete

For each selected directory, delete only the **contents**, not the directory itself:

```bash
rm -rf <directory>/*
```

**NEVER delete these** regardless of user selection:
- `~/.claude/settings.json`
- `~/.claude/settings.local.json`
- `~/.claude/credentials.json`
- `~/.claude/CLAUDE.md`
- Any `memory/` directories or their contents
- Any `SKILL.md` files or skill directories

After deletion, re-run the scan script and show the updated table so the user can see the space reclaimed.

## Directory Reference

| Directory | Contents | Safe to delete? |
|-----------|----------|-----------------|
| `projects/*/` (UUID `.jsonl` files and UUID dirs) | Session conversation transcripts per project | **Yes** — old session logs, no impact on workflow |
| `projects/*/memory/` | Auto-memory files that persist across conversations | **No** — user's saved context |
| `debug/` | Debug log files | **Yes** |
| `file-history/` | File edit history/backups from sessions | **Yes** |
| `plugins/` | MCP plugin cached data | **Yes** — plugins re-download as needed |
| `telemetry/` | Usage telemetry cache | **Yes** |
| `paste-cache/` | Clipboard paste cache | **Yes** |
| `cache/` | General cache data | **Yes** |
| `statsig/` | Analytics/feature flag cache | **Yes** |
| `sessions/` | Session metadata | **Yes** |
| `todos/` | Task files from conversations | **Yes** |
| `plans/` | Plan files from conversations | **Yes** |
| `tasks/` | Task tracking files | **Yes** |
| `backups/` | File backups | **Yes** — but warn the user these are safety backups |
| `shell-snapshots/` | Shell environment snapshots | **Yes** |
| `session-env/` | Session environment data | **Yes** |
| `downloads/` | Downloaded files | **Yes** |
| `scripts/` | User scripts | **No** — may contain user-created scripts |
| `skills/` | User skills | **No** — user-defined skills including this one |
| `settings.json` | User settings and permissions | **No** |
| `settings.local.json` | Local settings overrides | **No** |
| `credentials.json` | Authentication tokens | **No** |
| `CLAUDE.md` | User's global instructions | **No** |
| `ide/` | IDE integration state | **No** |
| `vm_bundles/` (in Application Support) | Claude Desktop sandbox VM (~10 GB) | **Yes** if user only uses CLI |

### Special handling for `projects/` directories

The `projects/` directory contains both session data (deletable) and memory files (keep). When cleaning `projects/`:
- Delete UUID-named `.jsonl` files (session transcripts)
- Delete UUID-named directories (session working data)
- **Preserve** `memory/` directories and all their contents
- **Preserve** `CLAUDE.md` files
- **Preserve** `settings.json` and `settings.local.json` files

### Active session protection

The scan script detects active sessions by reading `~/.claude/sessions/*.json` files, which contain `sessionId` (UUID) and `pid` fields. If the pid is still running, that session is active.

**NEVER delete files belonging to active sessions.** The scan script reports active session counts separately in `project_sessions.active_count` and `project_sessions.active_bytes`. When deleting project session data, use this approach:

```bash
# Get active session IDs from sessions/*.json where pid is still running
# Then delete only UUID files/dirs that do NOT match active session IDs
```

The `project_sessions.stale_count` and `project_sessions.stale_bytes` fields show only the data that is safe to delete. Use these numbers when reporting reclaimable space to the user.
