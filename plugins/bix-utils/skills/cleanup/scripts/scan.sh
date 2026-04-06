#!/usr/bin/env bash
# scan.sh — Cross-platform scanner for ~/.claude/ disk usage
# Outputs JSON with directory sizes and metadata
# Supports: macOS, Linux, WSL, Windows (Git Bash / MSYS2 / Cygwin)

set -euo pipefail

# Determine ~/.claude/ path
CLAUDE_DIR="${HOME}/.claude"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo '{"error": "~/.claude/ directory not found"}'
  exit 1
fi

# Get size in bytes — works across macOS, Linux, and Git Bash/MSYS
get_size_bytes() {
  local target="$1"
  if [ ! -e "$target" ]; then
    echo "0"
    return
  fi
  # Try du -sb (GNU/Linux), fall back to du -sk * 1024 (macOS/BSD/Git Bash)
  if du -sb "$target" >/dev/null 2>&1; then
    du -sb "$target" 2>/dev/null | awk '{print $1}' || echo "0"
  else
    du -sk "$target" 2>/dev/null | awk '{print $1 * 1024}' || echo "0"
  fi
}

# Human-readable size using pure bash arithmetic (no bc dependency)
fmt_size() {
  local bytes=$1
  if [ "$bytes" -lt 1024 ]; then
    echo "${bytes} B"
  elif [ "$bytes" -lt 1048576 ]; then
    local whole=$((bytes / 1024))
    local frac=$(( (bytes % 1024) * 10 / 1024 ))
    echo "${whole}.${frac} KB"
  elif [ "$bytes" -lt 1073741824 ]; then
    local whole=$((bytes / 1048576))
    local frac=$(( (bytes % 1048576) * 10 / 1048576 ))
    echo "${whole}.${frac} MB"
  else
    local whole=$((bytes / 1073741824))
    local frac=$(( (bytes % 1073741824) * 100 / 1073741824 ))
    # Zero-pad fraction for GB (e.g., 7.05 not 7.5)
    if [ "$frac" -lt 10 ]; then
      echo "${whole}.0${frac} GB"
    else
      echo "${whole}.${frac} GB"
    fi
  fi
}

# Collect active session IDs from ~/.claude/sessions/*.json
# Each file contains a JSON object with "sessionId" and "pid" fields.
# A session is active if its pid is still running.
collect_active_session_ids() {
  local sessions_dir="$CLAUDE_DIR/sessions"
  ACTIVE_SESSION_IDS=""
  if [ ! -d "$sessions_dir" ]; then
    return
  fi
  for sfile in "$sessions_dir"/*.json; do
    [ -f "$sfile" ] || continue
    # Extract pid and sessionId using grep+sed (no jq dependency)
    local pid sid
    pid=$(grep -o '"pid":[0-9]*' "$sfile" 2>/dev/null | head -1 | grep -o '[0-9]*' || echo "")
    sid=$(grep -o '"sessionId":"[^"]*"' "$sfile" 2>/dev/null | head -1 | sed 's/"sessionId":"//;s/"//' || echo "")
    if [ -z "$pid" ] || [ -z "$sid" ]; then
      continue
    fi
    # Check if the process is still running
    if kill -0 "$pid" 2>/dev/null; then
      ACTIVE_SESSION_IDS="${ACTIVE_SESSION_IDS}${sid} "
    fi
  done
}

# Check if a UUID is an active session
is_active_session() {
  local uuid="$1"
  case " $ACTIVE_SESSION_IDS" in
    *" ${uuid} "*|*" ${uuid}") return 0 ;;
    *) return 1 ;;
  esac
}

# Count session files in projects — uses glob pattern compatible with all platforms
# Excludes active sessions from counts
count_project_sessions() {
  local projects_dir="$CLAUDE_DIR/projects"
  local count=0
  local size=0
  local active_count=0
  local active_size=0
  if [ -d "$projects_dir" ]; then
    # Scan each project directory
    for proj_dir in "$projects_dir"/*/; do
      [ -d "$proj_dir" ] || continue

      # UUID .jsonl files (session transcripts)
      for f in "$proj_dir"????????-????-????-????-????????????.jsonl; do
        [ -f "$f" ] || continue
        local uuid
        uuid=$(basename "$f" .jsonl)
        fsize=$(get_size_bytes "$f")
        if is_active_session "$uuid"; then
          active_count=$((active_count + 1))
          active_size=$((active_size + fsize))
        else
          count=$((count + 1))
          size=$((size + fsize))
        fi
      done

      # UUID directories (session working data)
      for d in "$proj_dir"????????-????-????-????-????????????; do
        [ -d "$d" ] || continue
        local base
        base=$(basename "$d")
        case "$base" in
          ????????-????-????-????-????????????) ;;
          *) continue ;;
        esac
        dsize=$(get_size_bytes "$d")
        if is_active_session "$base"; then
          active_count=$((active_count + 1))
          active_size=$((active_size + dsize))
        else
          count=$((count + 1))
          size=$((size + dsize))
        fi
      done
    done
  fi
  echo "${count}:${size}:${active_count}:${active_size}"
}

# Collect active sessions before scanning
collect_active_session_ids

# Start JSON output
echo "{"
echo "  \"claude_dir\": \"$CLAUDE_DIR\","
echo "  \"os\": \"${OSTYPE:-unknown}\","

# Total size
total=$(get_size_bytes "$CLAUDE_DIR")
echo "  \"total_bytes\": $total,"
echo "  \"total_human\": \"$(fmt_size "$total")\","

# Scan each directory
echo "  \"directories\": ["

first=true
for dir in "$CLAUDE_DIR"/*/; do
  [ -d "$dir" ] || continue
  dirname=$(basename "$dir")
  size=$(get_size_bytes "$dir")

  if [ "$first" = true ]; then
    first=false
  else
    echo "    ,"
  fi

  echo "    {"
  echo "      \"name\": \"$dirname\","
  echo "      \"path\": \"$dir\","
  echo "      \"bytes\": $size,"
  echo "      \"human\": \"$(fmt_size "$size")\""
  echo -n "    }"
done

echo ""
echo "  ],"

# Session data in projects (separate count, excludes active sessions)
session_info=$(count_project_sessions)
session_count=$(echo "$session_info" | cut -d: -f1)
session_bytes=$(echo "$session_info" | cut -d: -f2)
active_count=$(echo "$session_info" | cut -d: -f3)
active_bytes=$(echo "$session_info" | cut -d: -f4)
echo "  \"project_sessions\": {"
echo "    \"stale_count\": $session_count,"
echo "    \"stale_bytes\": $session_bytes,"
echo "    \"stale_human\": \"$(fmt_size "$session_bytes")\","
echo "    \"active_count\": $active_count,"
echo "    \"active_bytes\": $active_bytes,"
echo "    \"active_human\": \"$(fmt_size "$active_bytes")\""
echo "  },"

# Check for VM bundles — platform-specific paths
vm_path=""
vm_size=0
if [[ "${OSTYPE:-}" == "darwin"* ]]; then
  # macOS
  vm_path="$HOME/Library/Application Support/Claude/vm_bundles"
elif [[ "${OSTYPE:-}" == "linux"* ]]; then
  # Linux / WSL — check XDG data dir, then common fallback
  vm_path="${XDG_DATA_HOME:-$HOME/.local/share}/Claude/vm_bundles"
  if [ ! -d "$vm_path" ]; then
    vm_path="$HOME/.config/Claude/vm_bundles"
  fi
elif [[ "${OSTYPE:-}" == "msys"* ]] || [[ "${OSTYPE:-}" == "cygwin"* ]] || [[ "${OSTYPE:-}" == "win32"* ]]; then
  # Windows (Git Bash / MSYS2 / Cygwin)
  if [ -n "${APPDATA:-}" ]; then
    vm_path="$APPDATA/Claude/vm_bundles"
  elif [ -n "${LOCALAPPDATA:-}" ]; then
    vm_path="$LOCALAPPDATA/Claude/vm_bundles"
  fi
fi

if [ -n "$vm_path" ] && [ -d "$vm_path" ]; then
  vm_size=$(get_size_bytes "$vm_path")
fi

echo "  \"vm_bundles\": {"
echo "    \"path\": \"${vm_path}\","
echo "    \"bytes\": $vm_size,"
echo "    \"human\": \"$(fmt_size "$vm_size")\""
echo "  },"

# Top-level files
echo "  \"files\": ["
file_first=true
for f in "$CLAUDE_DIR"/*; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  fsize=$(get_size_bytes "$f")

  if [ "$file_first" = true ]; then
    file_first=false
  else
    echo "    ,"
  fi

  echo "    {"
  echo "      \"name\": \"$fname\","
  echo "      \"bytes\": $fsize,"
  echo "      \"human\": \"$(fmt_size "$fsize")\""
  echo -n "    }"
done
echo ""
echo "  ]"

echo "}"
