#!/usr/bin/env bash
# delete.sh — Deterministic, active-session-safe cleanup + before/after report.
#
# Usage:
#   delete.sh <dir1> [<dir2> ...]   # delete specific directory names under ~/.claude/
#   delete.sh --all                 # delete every directory classified "yes"
#
# Outputs a JSON object with per-directory before/after/saved bytes plus a
# pre-rendered markdown report table and a Total Memory Saved line. The LLM
# just echoes `markdown_report` verbatim — no math required.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=classify.sh
. "$SCRIPT_DIR/classify.sh"

CLAUDE_DIR="${HOME}/.claude"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo '{"error": "~/.claude/ directory not found"}'
  exit 1
fi

# ---------- size helpers (mirrors scan.sh, kept standalone) ----------
get_size_bytes() {
  local target="$1"
  [ -e "$target" ] || { echo "0"; return; }
  if du -sb "$target" >/dev/null 2>&1; then
    du -sb "$target" 2>/dev/null | awk '{print $1}' || echo "0"
  else
    du -sk "$target" 2>/dev/null | awk '{print $1 * 1024}' || echo "0"
  fi
}

fmt_size() {
  local bytes=$1
  if [ "$bytes" -lt 1024 ]; then echo "${bytes} B"
  elif [ "$bytes" -lt 1048576 ]; then
    echo "$((bytes / 1024)).$(( (bytes % 1024) * 10 / 1024 )) KB"
  elif [ "$bytes" -lt 1073741824 ]; then
    echo "$((bytes / 1048576)).$(( (bytes % 1048576) * 10 / 1048576 )) MB"
  else
    local w=$((bytes / 1073741824))
    local f=$(( (bytes % 1073741824) * 100 / 1073741824 ))
    [ "$f" -lt 10 ] && echo "${w}.0${f} GB" || echo "${w}.${f} GB"
  fi
}

# ---------- active session detection (same logic as scan.sh) ----------
ACTIVE_SESSION_IDS=""
collect_active_session_ids() {
  local sessions_dir="$CLAUDE_DIR/sessions"
  [ -d "$sessions_dir" ] || return
  for sfile in "$sessions_dir"/*.json; do
    [ -f "$sfile" ] || continue
    local pid sid
    pid=$(grep -o '"pid":[0-9]*' "$sfile" 2>/dev/null | head -1 | grep -o '[0-9]*' || echo "")
    sid=$(grep -o '"sessionId":"[^"]*"' "$sfile" 2>/dev/null | head -1 | sed 's/"sessionId":"//;s/"//' || echo "")
    [ -n "$pid" ] && [ -n "$sid" ] || continue
    if kill -0 "$pid" 2>/dev/null; then
      ACTIVE_SESSION_IDS="${ACTIVE_SESSION_IDS}${sid} "
    fi
  done
}
is_active_session() {
  case " $ACTIVE_SESSION_IDS" in
    *" $1 "*|*" $1") return 0 ;;
    *) return 1 ;;
  esac
}

# ---------- per-directory deletion strategy ----------

# Delete contents of ~/.claude/projects/ while preserving:
#  - memory/ dirs, CLAUDE.md, settings*.json
#  - active session UUID .jsonl files and UUID dirs
delete_projects_safe() {
  local projects_dir="$CLAUDE_DIR/projects"
  [ -d "$projects_dir" ] || return
  for proj_dir in "$projects_dir"/*/; do
    [ -d "$proj_dir" ] || continue
    # UUID transcript files
    for f in "$proj_dir"????????-????-????-????-????????????.jsonl; do
      [ -f "$f" ] || continue
      local uuid; uuid=$(basename "$f" .jsonl)
      is_active_session "$uuid" || rm -f "$f"
    done
    # UUID working directories
    for d in "$proj_dir"????????-????-????-????-????????????; do
      [ -d "$d" ] || continue
      local base; base=$(basename "$d")
      case "$base" in
        ????????-????-????-????-????????????) ;;
        *) continue ;;
      esac
      is_active_session "$base" || rm -rf "$d"
    done
    # Note: memory/, CLAUDE.md, settings*.json are NOT matched by the globs
    # above, so they are preserved automatically.
  done
}

# Delete contents of a generic directory (not the directory itself).
# Uses shell globs (portable across macOS/BSD, Linux/GNU, Git Bash/MSYS2,
# Cygwin) instead of `find -mindepth` which has varying support.
delete_generic() {
  local target="$CLAUDE_DIR/$1"
  [ -d "$target" ] || return
  # Enable dotglob so hidden files are included; nullglob so empty dirs
  # don't expand to literal '*'. Both are bash built-ins (3.2+).
  (
    shopt -s dotglob nullglob 2>/dev/null || true
    cd "$target" || exit 0
    for entry in *; do
      [ "$entry" = "." ] || [ "$entry" = ".." ] && continue
      rm -rf -- "$entry"
    done
  )
}

# ---------- main ----------

collect_active_session_ids

# Build the list of directories to process
REQUESTED=()
if [ "${1:-}" = "--all" ]; then
  for dir in "$CLAUDE_DIR"/*/; do
    [ -d "$dir" ] || continue
    local_name=$(basename "$dir")
    classify_dir "$local_name"
    [ "$CLASSIFY_SAFE" = "yes" ] && REQUESTED+=("$local_name")
  done
else
  REQUESTED=("$@")
fi

if [ "${#REQUESTED[@]}" -eq 0 ]; then
  echo '{"error": "no directories specified"}'
  exit 1
fi

# Process each directory: validate, measure before, delete, measure after
RESULTS_JSON=""
MD_ROWS=""
TOTAL_SAVED=0
SKIPPED=""

for name in "${REQUESTED[@]}"; do
  # Block hardcoded unsafe names
  if is_never_delete "$name"; then
    SKIPPED="${SKIPPED}${name}(blocked) "
    continue
  fi
  classify_dir "$name"
  if [ "$CLASSIFY_SAFE" != "yes" ]; then
    SKIPPED="${SKIPPED}${name}(not-safe) "
    continue
  fi
  target="$CLAUDE_DIR/$name"
  if [ ! -d "$target" ]; then
    SKIPPED="${SKIPPED}${name}(missing) "
    continue
  fi

  before=$(get_size_bytes "$target")

  case "$name" in
    projects) delete_projects_safe ;;
    *)        delete_generic "$name" ;;
  esac

  after=$(get_size_bytes "$target")
  saved=$((before - after))
  [ "$saved" -lt 0 ] && saved=0
  TOTAL_SAVED=$((TOTAL_SAVED + saved))

  before_h=$(fmt_size "$before")
  after_h=$(fmt_size "$after")
  saved_h=$(fmt_size "$saved")

  if [ -n "$RESULTS_JSON" ]; then RESULTS_JSON="${RESULTS_JSON},"; fi
  RESULTS_JSON="${RESULTS_JSON}{\"name\":\"$name\",\"before_bytes\":$before,\"after_bytes\":$after,\"saved_bytes\":$saved,\"before\":\"$before_h\",\"after\":\"$after_h\",\"saved\":\"$saved_h\"}"

  MD_ROWS="${MD_ROWS}| \`${name}/\` | ${before_h} | ${after_h} | ${saved_h} |"$'\n'
done

TOTAL_H=$(fmt_size "$TOTAL_SAVED")
CLAUDE_NOW=$(get_size_bytes "$CLAUDE_DIR")
CLAUDE_NOW_H=$(fmt_size "$CLAUDE_NOW")

# Build markdown report (LLM prints this verbatim)
MD_HEADER="| Directory | Before | After | Saved |\n|-----------|--------|-------|-------|\n"
MD_BODY=$(printf "%s" "$MD_ROWS" | awk '{printf "%s\\n", $0}')
MD_FOOTER="\n**Total Memory Saved: ${TOTAL_H}**\n\n\`~/.claude/\` is now ${CLAUDE_NOW_H}."
MARKDOWN_REPORT="${MD_HEADER}${MD_BODY}${MD_FOOTER}"

# JSON-escape results (names/sizes are already safe)
printf '{\n'
printf '  "results": [%s],\n' "$RESULTS_JSON"
printf '  "total_saved_bytes": %s,\n' "$TOTAL_SAVED"
printf '  "total_saved_human": "%s",\n' "$TOTAL_H"
printf '  "claude_dir_bytes": %s,\n' "$CLAUDE_NOW"
printf '  "claude_dir_human": "%s",\n' "$CLAUDE_NOW_H"
printf '  "skipped": "%s",\n' "$SKIPPED"
printf '  "markdown_report": "%s"\n' "$MARKDOWN_REPORT"
printf '}\n'
