#!/usr/bin/env bash
# classify.sh — Shared directory classification for cleanup skill.
# Sourced by scan.sh and delete.sh. Single source of truth for
# "what is this directory" and "is it safe to delete".

# classify_dir <dirname>
# Sets globals: CLASSIFY_DESC, CLASSIFY_SAFE ("yes"|"no"|"unknown")
classify_dir() {
  local name="$1"
  case "$name" in
    projects)
      CLASSIFY_DESC="Session conversation transcripts per project (memory/ preserved)"
      CLASSIFY_SAFE="yes" ;;
    debug)
      CLASSIFY_DESC="Debug log files"
      CLASSIFY_SAFE="yes" ;;
    file-history)
      CLASSIFY_DESC="File edit history/backups from sessions"
      CLASSIFY_SAFE="yes" ;;
    plugins)
      CLASSIFY_DESC="MCP plugin cached data (re-downloads as needed)"
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
      CLASSIFY_DESC="Analytics/feature flag cache"
      CLASSIFY_SAFE="yes" ;;
    sessions)
      CLASSIFY_DESC="Session metadata"
      CLASSIFY_SAFE="yes" ;;
    todos)
      CLASSIFY_DESC="Task files from conversations"
      CLASSIFY_SAFE="yes" ;;
    plans)
      CLASSIFY_DESC="Plan files from conversations"
      CLASSIFY_SAFE="yes" ;;
    tasks)
      CLASSIFY_DESC="Task tracking files"
      CLASSIFY_SAFE="yes" ;;
    backups)
      CLASSIFY_DESC="File backups (safety net — warn user)"
      CLASSIFY_SAFE="yes" ;;
    shell-snapshots)
      CLASSIFY_DESC="Shell environment snapshots"
      CLASSIFY_SAFE="yes" ;;
    session-env)
      CLASSIFY_DESC="Session environment data"
      CLASSIFY_SAFE="yes" ;;
    downloads)
      CLASSIFY_DESC="Downloaded files"
      CLASSIFY_SAFE="yes" ;;
    vm_bundles)
      CLASSIFY_DESC="Claude Desktop sandbox VM (safe if CLI-only user)"
      CLASSIFY_SAFE="yes" ;;
    scripts)
      CLASSIFY_DESC="User-created scripts"
      CLASSIFY_SAFE="no" ;;
    skills)
      CLASSIFY_DESC="User-defined skills"
      CLASSIFY_SAFE="no" ;;
    memory)
      CLASSIFY_DESC="Auto-memory persisted across conversations"
      CLASSIFY_SAFE="no" ;;
    ide)
      CLASSIFY_DESC="IDE integration state"
      CLASSIFY_SAFE="no" ;;
    *)
      CLASSIFY_DESC="Unknown — investigate before deleting"
      CLASSIFY_SAFE="unknown" ;;
  esac
}

# Hard blocklist — never delete regardless of input.
is_never_delete() {
  case "$1" in
    scripts|skills|memory|ide|settings.json|settings.local.json|credentials.json|CLAUDE.md)
      return 0 ;;
    *) return 1 ;;
  esac
}
