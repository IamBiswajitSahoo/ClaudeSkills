# cleanup: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is a stylized broom sweeping a small pile of stacked folder shapes off a disk-shaped platter, with a few amber sparkles where the floor is now clear.

## 2. Skill name

**Claude Code Disk Cleanup**

Slug: `cleanup`

## 3. Skill summary

Scan ~/.claude/, see what is safe to delete, and reclaim disk space with a before/after report.

## 4. Full description

**What it does**
- Scans `~/.claude/` and prints a size table sorted largest first, with each directory marked Yes, No (keep) or Unknown for deletion.
- Shows a Reclaimable total and a `~/.claude/` total in the table footer.
- Lets you pick which safe directories to clean, or use `-all` for one confirmation.
- Deletes only what you approve, then prints a before/after table with Total Memory Saved.

**Problems it solves**
- `~/.claude/` grows with transcripts, debug logs, file history, caches and snapshots, and it is hard to tell what is safe to remove.
- Deleting by hand risks wiping skills, agents, settings or memory.
- Removing a running session's files can break that session.

**How it works**
1. Scan: `scan.sh` measures every directory, classifies it, detects running sessions by checking each PID, and renders the table.
2. Select: the agent asks you which safe directories to delete (checklist), or asks one yes/no question with `-all`.
3. Delete: `delete.sh` removes the contents of the chosen directories. A hard blocklist and the classifier refuse anything user-owned.
4. Report: the script's own before/after table is shown as is.

All sizes, classification and deletion are done by bundled shell scripts, not by the model, so the numbers are deterministic.

**Why install it**
- Free and open source (Apache-2.0).
- Nothing is deleted without your confirmation.
- Protects skills, agents, commands, rules, memory, plugins, settings, credentials and IDE state.
- No jq or Python needed. Works on macOS, Linux, WSL and Git Bash.

**Requirements**
- Claude Code and bash.
- A `~/.claude/` directory.

## 5. The request

```
/cleanup
```
```
Check how much disk space Claude Code is using and clean up the stale stuff.
```

Note: this skill only runs when you type the slash command. To clean everything safe in one step, use `/cleanup -all`.

## 6. The result

Claude Code scanned `~/.claude/` and found 5.94 GB in total, of which 5.50 GB is in directories marked safe to delete. One session is currently running, so its transcript is protected. You selected `projects`, `debug` and `file-history`. The cleanup removed 5.37 GB. Your skills, agents, plugins, settings and memory were not touched.

Scan output:

| Directory | Size | What it contains | Safe to delete? |
|-----------|-----:|------------------|:---------------:|
| `projects/` | 3.12 GB | Per-project session transcripts (memory/, CLAUDE.md, active sessions preserved) | Yes |
| `file-history/` | 1.46 GB | File edit history snapshots from past sessions | Yes |
| `debug/` | 788.6 MB | Debug log files | Yes |
| `plugins/` | 412.3 MB | Installed plugins and marketplace data (deletion uninstalls them) | No (keep) |
| `telemetry/` | 96.4 MB | Usage telemetry cache | Yes |
| `shell-snapshots/` | 31.2 MB | Shell environment snapshots | Yes |
| `skills/` | 2.1 MB | Global user-defined skills | No (keep) |
| `my-notes/` | 180.0 KB | Unknown, investigate before deleting | Unknown |
| **Reclaimable total** | **5.50 GB** | sum of all rows marked *Yes* | n/a |
| **~/.claude/ total** | **5.94 GB** | all directories above | n/a |

1 active session(s) detected (14.8 MB) and will be preserved.

Selection (checklist): `projects/ (3.12 GB)`, `file-history/ (1.46 GB)`, `debug/ (788.6 MB)`.

Report:

| Directory | Before | After | Saved |
|-----------|--------|-------|-------|
| `projects/` | 3.12 GB | 38.5 MB | 3.08 GB |
| `file-history/` | 1.46 GB | 0 B | 1.46 GB |
| `debug/` | 788.6 MB | 0 B | 788.6 MB |

**Total Memory Saved: 5.31 GB**

`~/.claude/` is now 580.7 MB.

**Next steps**
- Run `/cleanup -all` next time to clear every safe directory after one confirmation.
- Check `my-notes/`, which is not recognized, and decide yourself whether to remove it. The skill never offers to delete unknown directories.
- Close other Claude Code sessions first if you want their transcripts cleaned too.

## 7. Compatibility note

Built for and tested on Claude Code only. It depends on the `${CLAUDE_SKILL_DIR}` variable, slash-command invocation (`/cleanup`), the AskUserQuestion tool for confirmation, and Claude Code's `~/.claude/` data layout. Other agents that read SKILL.md may run the shell scripts, but the skill is not tested there and the directories it targets are specific to Claude Code.

## 8. Categories, tags, use cases

- Categories: Productivity, Workflow Automation, Business & Operations
- Tags: cleanup, disk-space, claude-code, housekeeping, cache, session-transcripts, maintenance, storage
- Use cases:
  - Reclaiming disk space on a laptop
  - Checking what is using space in ~/.claude
  - Clearing stale session transcripts
  - Removing old debug logs and caches
  - Monthly Claude Code housekeeping

## 9. Permissions

- Tools used:
  - Terminal / Shell: yes. Runs `scan.sh` and `delete.sh` with bash.
  - Read Files: yes. Reads directory sizes and `~/.claude/sessions/*.json` (pid and sessionId) to find running sessions.
  - Write Files: yes. Deletes files and directories under `~/.claude/` that you selected. Creates nothing.
  - Browser: no.
  - Network Access: no. The scripts make no network calls.
  - Environment Variables: yes, minimal. Reads `HOME`, `OSTYPE`, `XDG_DATA_HOME`, `APPDATA`, `LOCALAPPDATA` to find paths.
- Needs access to: None.
- File scopes:
  - Read: `~/.claude/**` (sizes), `~/.claude/sessions/*.json`
  - Read (size only): Claude Desktop `vm_bundles` folder under the OS app data path
  - Delete: contents of selected safe directories in `~/.claude/*/` (for example `~/.claude/projects/*/<uuid>.jsonl`, `~/.claude/debug/**`)
- Notes: Deletion is the purpose of the skill, so it needs shell and file write access, but only inside `~/.claude/` and only for directories you pick. A hard blocklist protects `skills/`, `agents/`, `commands/`, `rules/`, `memory/`, `plugins/`, `ide/`, `scripts/`, `output-styles/`, and files such as `settings.json`, `credentials.json`, `CLAUDE.md`, `.claude.json` and `.mcp.json`. It does not read the contents of credential files.

## 10. Known limitations

- Claude Code only. It reads and deletes the `~/.claude/` layout.
- Deletion is permanent. There is no trash, undo or dry-run mode.
- The classifier is a fixed list. Directories it does not know are labeled Unknown and are never deleted.
- Safe directories are emptied entirely, including `plans/`, `todos/`, `tasks/`, `backups/` and `file-history/`. Review the table first if you want anything in them.
- Running-session detection checks the PID in `sessions/*.json`. It protects transcripts and session folders in `projects/`. If you select `sessions/`, its metadata files are removed along with the rest of that folder.
- Deletion only touches directories inside `~/.claude/`. The scan also reports the size of a Claude Desktop `vm_bundles` folder, but `delete.sh` does not remove it.
- Sizes use `du`, so figures can differ slightly between macOS, Linux and Git Bash. Output is rounded to one decimal.
- Requires bash. On Windows use Git Bash, MSYS2, Cygwin or WSL.
- It will not run on its own. Manual invocation only (`/cleanup`).

## 11. FAQ

**Q:** How do I install it?
A: Download the zip from Agensi and add the folder to your Claude Code skills directory. You can also install the whole set as a plugin from https://github.com/IamBiswajitSahoo/ClaudeSkills. Then type `/cleanup`.

**Q:** What does it need?
A: Claude Code, bash, and standard tools such as `du`, `grep`, `sed` and `awk`. No jq, Python or network access.

**Q:** Will it delete anything without asking?
A: No. `/cleanup` shows a checklist of safe directories and deletes only the ones you choose. `/cleanup -all` asks one yes/no confirmation first. The model cannot invoke the skill on its own.

**Q:** What will it never delete?
A: Skills, agents, commands, rules, memory, plugins, IDE state, scripts, output styles, settings, credentials, keybindings, `CLAUDE.md`, `MEMORY.md`, `.claude.json`, `.mcp.json` and `.worktreeinclude`. These are blocked in the script even if passed by name.

**Q:** What happens to the sessions I have open right now?
A: The scan finds running sessions by PID. In `projects/`, their transcripts and working folders are kept, and so are `memory/`, `CLAUDE.md` and `settings*.json`. Only stale session transcripts and folders are removed.

**Q:** Does it use many tokens?
A: No. The scripts do the sizing, classification, deletion and report rendering. The model only shows the output and asks the confirmation question.

**Q:** Can I preview what would be deleted?
A: Yes. The scan table is shown before any question, with sizes and Safe to delete labels. You can answer the checklist with no selection to stop. There is no separate dry-run mode.
