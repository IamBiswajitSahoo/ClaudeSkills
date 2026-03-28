#!/usr/bin/env bash
# gather-pr-info.sh — Fetch PR metadata and diff from GitHub
# Outputs JSON with repo, PR details, and diff content
# Requires: gh CLI (authenticated)
#
# Usage: bash gather-pr-info.sh <PR_NUMBER>

set -euo pipefail

PR_NUMBER="${1:-}"

# --- Validate input ---

if [ -z "$PR_NUMBER" ]; then
  echo '{"error": "No PR number provided. Usage: gather-pr-info.sh <PR_NUMBER>"}'
  exit 1
fi

if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
  echo '{"error": "Invalid PR number: must be a positive integer"}'
  exit 1
fi

# --- Check gh CLI is available and authenticated ---

if ! command -v gh &>/dev/null; then
  echo '{"error": "gh CLI not found. Install it from https://cli.github.com"}'
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo '{"error": "gh CLI is not authenticated. Run: gh auth login"}'
  exit 1
fi

# --- Detect repository ---

repo=$(gh repo view --json owner,name -q '.owner.login + "/" + .name' 2>/dev/null) || {
  echo '{"error": "Could not detect repository. Are you in a git repo with a GitHub remote?"}'
  exit 1
}

# --- Fetch PR metadata ---

pr_json=$(gh pr view "$PR_NUMBER" --json title,body,headRefName,baseRefName,state,isDraft,additions,deletions,changedFiles,labels,url 2>/dev/null) || {
  echo "{\"error\": \"PR #${PR_NUMBER} not found in ${repo}\"}"
  exit 1
}

# --- Fetch diff ---
# Use a temp file to avoid issues with large diffs in variables

diff_file=$(mktemp)
trap 'rm -f "$diff_file"' EXIT

if ! gh pr diff "$PR_NUMBER" > "$diff_file" 2>/dev/null; then
  echo '{"error": "Failed to fetch PR diff. The PR may have no commits yet."}'
  exit 1
fi

diff_lines=$(wc -l < "$diff_file" | tr -d ' ')
diff_size=$(wc -c < "$diff_file" | tr -d ' ')

# --- Build output JSON ---
# Embed the diff as a properly escaped JSON string

diff_escaped=$(python3 -c "
import json, sys
with open(sys.argv[1], 'r', errors='replace') as f:
    print(json.dumps(f.read()))
" "$diff_file")

cat <<ENDJSON
{
  "repo": "$repo",
  "pr_number": $PR_NUMBER,
  "metadata": $pr_json,
  "diff": {
    "lines": $diff_lines,
    "bytes": $diff_size,
    "content": $diff_escaped
  }
}
ENDJSON
