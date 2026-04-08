#!/usr/bin/env bash
# classify.sh — Shared directory classification for cleanup skill.
# Sourced by scan.sh and delete.sh. Single source of truth for
# "what is this directory" and "is it safe to delete".

# classify_dir <dirname>
# Sets globals: CLASSIFY_DESC, CLASSIFY_SAFE ("yes"|"no"|"unknown")
classify_dir() {
  local name="$1"
  case "$name" in
    # ── User-owned data (per code.claude.com/docs/en/claude-directory) ──
    skills)
      CLASSIFY_DESC="Global user-defined skills"
      CLASSIFY_SAFE="no" ;;
    agents)
      CLASSIFY_DESC="Global subagent definitions"
      CLASSIFY_SAFE="no" ;;
    commands)
      CLASSIFY_DESC="Global slash commands (legacy — superseded by skills/)"
      CLASSIFY_SAFE="no" ;;
    output-styles)
      CLASSIFY_DESC="Global output style definitions"
      CLASSIFY_SAFE="no" ;;
    rules)
      CLASSIFY_DESC="Global rule files auto-loaded into context"
      CLASSIFY_SAFE="no" ;;
    memory|agent-memory)
      CLASSIFY_DESC="Auto-memory persisted across conversations"
      CLASSIFY_SAFE="no" ;;
    scripts)
      CLASSIFY_DESC="User-created scripts"
      CLASSIFY_SAFE="no" ;;
    ide)
      CLASSIFY_DESC="IDE integration state"
      CLASSIFY_SAFE="no" ;;
    plugins)
      CLASSIFY_DESC="Installed plugins and marketplace data (deletion uninstalls them)"
      CLASSIFY_SAFE="no" ;;

    # ── Mixed: session transcripts (stale deleted, active + memory preserved) ──
    projects)
      CLASSIFY_DESC="Per-project session transcripts (memory/, CLAUDE.md, active sessions preserved)"
      CLASSIFY_SAFE="yes" ;;

    # ── Runtime caches / logs / ephemeral state (regenerated on demand) ──
    debug)
      CLASSIFY_DESC="Debug log files"
      CLASSIFY_SAFE="yes" ;;
    file-history)
      CLASSIFY_DESC="File edit history snapshots from past sessions"
      CLASSIFY_SAFE="yes" ;;
    telemetry)
      CLASSIFY_DESC="Usage telemetry cache"
      CLASSIFY_SAFE="yes" ;;
    paste-cache)
      CLASSIFY_DESC="Clipboard paste cache"
      CLASSIFY_SAFE="yes" ;;
    cache)
      CLASSIFY_DESC="General cache data"
      CLASSIFY_SAFE="yes" ;;
    statsig)
      CLASSIFY_DESC="Feature-flag / analytics cache"
      CLASSIFY_SAFE="yes" ;;
    sessions)
      CLASSIFY_DESC="Session metadata (active sessions auto-preserved)"
      CLASSIFY_SAFE="yes" ;;
    todos)
      CLASSIFY_DESC="Task lists from past conversations"
      CLASSIFY_SAFE="yes" ;;
    plans)
      CLASSIFY_DESC="Plan files from past conversations"
      CLASSIFY_SAFE="yes" ;;
    tasks)
      CLASSIFY_DESC="Task tracking files from past conversations"
      CLASSIFY_SAFE="yes" ;;
    backups)
      CLASSIFY_DESC="Automatic file backups (safety net)"
      CLASSIFY_SAFE="yes" ;;
    shell-snapshots)
      CLASSIFY_DESC="Shell environment snapshots"
      CLASSIFY_SAFE="yes" ;;
    session-env)
      CLASSIFY_DESC="Per-session environment data"
      CLASSIFY_SAFE="yes" ;;
    downloads)
      CLASSIFY_DESC="Files downloaded during sessions"
      CLASSIFY_SAFE="yes" ;;
    vm_bundles)
      CLASSIFY_DESC="Claude Desktop sandbox VM (safe for CLI-only users)"
      CLASSIFY_SAFE="yes" ;;
    *)
      CLASSIFY_DESC="Unknown — investigate before deleting"
      CLASSIFY_SAFE="unknown" ;;
  esac
}

# Hard blocklist — never delete regardless of input.
# Covers everything the official docs describe as user-owned configuration or data.
is_never_delete() {
  case "$1" in
    scripts|skills|agents|commands|output-styles|rules|memory|agent-memory|ide|plugins) return 0 ;;
    settings.json|settings.local.json|credentials.json|keybindings.json|CLAUDE.md|MEMORY.md|.claude.json|.mcp.json|.worktreeinclude) return 0 ;;
    *) return 1 ;;
  esac
}
