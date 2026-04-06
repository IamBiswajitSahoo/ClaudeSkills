#!/usr/bin/env bash
# gather-pr-context.sh — Fetch PR metadata, diff, project rules, and eligibility for review
# Outputs structured JSON with all context needed to review a PR
# Requires: gh CLI (authenticated), python3, git
#
# Usage: bash gather-pr-context.sh <PR_NUMBER> [-parallel]

set -euo pipefail

PR_NUMBER=""
PARALLEL_REQUESTED="false"

# --- Parse arguments ---

for arg in "$@"; do
  if [[ "$arg" == "-parallel" ]]; then
    PARALLEL_REQUESTED="true"
  elif [[ -z "$PR_NUMBER" ]] && [[ "$arg" =~ ^[0-9]+$ ]]; then
    PR_NUMBER="$arg"
  fi
done

# --- Validate input ---

if [ -z "$PR_NUMBER" ]; then
  echo '{"error": "No PR number provided. Usage: gather-pr-context.sh <PR_NUMBER> [-parallel]"}'
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

# --- Check git is available ---

if ! command -v git &>/dev/null; then
  echo '{"error": "git is not installed"}'
  exit 1
fi

# --- Detect repository ---

repo=$(gh repo view --json owner,name -q '.owner.login + "/" + .name' 2>/dev/null) || {
  echo '{"error": "Could not detect repository. Are you in a git repo with a GitHub remote?"}'
  exit 1
}

owner=$(echo "$repo" | cut -d/ -f1)
name=$(echo "$repo" | cut -d/ -f2)

# --- Fetch PR metadata ---

pr_json=$(gh pr view "$PR_NUMBER" --json title,body,headRefName,baseRefName,state,isDraft,additions,deletions,changedFiles,labels,url 2>/dev/null) || {
  echo "{\"error\": \"PR #${PR_NUMBER} not found in ${repo}\"}"
  exit 1
}

# --- Fetch latest commit SHA ---

commit_sha=$(gh pr view "$PR_NUMBER" --json commits --jq '.commits[-1].oid' 2>/dev/null) || {
  echo '{"error": "Failed to fetch commit SHA for the PR"}'
  exit 1
}

# --- Fetch diff into temp file ---

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

if ! gh pr diff "$PR_NUMBER" > "$tmpdir/diff.txt" 2>/dev/null; then
  echo '{"error": "Failed to fetch PR diff. The PR may have no commits yet."}'
  exit 1
fi

diff_lines=$(wc -l < "$tmpdir/diff.txt" | tr -d ' ')
diff_size=$(wc -c < "$tmpdir/diff.txt" | tr -d ' ')

# --- Check for CLAUDE.md and REVIEW.md in repo root ---

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

claude_md="null"
review_md="null"

if [ -n "$repo_root" ]; then
  if [ -f "$repo_root/CLAUDE.md" ]; then
    claude_md=$(python3 -c "
import json, sys
with open(sys.argv[1], 'r', errors='replace') as f:
    print(json.dumps(f.read()))
" "$repo_root/CLAUDE.md")
  fi
  if [ -f "$repo_root/REVIEW.md" ]; then
    review_md=$(python3 -c "
import json, sys
with open(sys.argv[1], 'r', errors='replace') as f:
    print(json.dumps(f.read()))
" "$repo_root/REVIEW.md")
  fi
fi

# --- Check PR eligibility ---

pr_state=$(echo "$pr_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('state','UNKNOWN'))")
is_draft=$(echo "$pr_json" | python3 -c "import json,sys; print(str(json.load(sys.stdin).get('isDraft', False)).lower())")

# Check if current user has already reviewed this PR
current_user=$(gh api user --jq '.login' 2>/dev/null || echo "")
already_reviewed="false"

if [ -n "$current_user" ]; then
  review_states=$(gh api "repos/${owner}/${name}/pulls/${PR_NUMBER}/reviews" --jq "[.[] | select(.user.login == \"${current_user}\") | .state] | join(\",\")" 2>/dev/null || echo "")
  if echo "$review_states" | grep -qE "APPROVED|CHANGES_REQUESTED"; then
    already_reviewed="true"
  fi
fi

# --- Check current branch vs PR head branch ---

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
head_ref=$(echo "$pr_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('headRefName',''))")
branch_matches="false"
if [ "$current_branch" = "$head_ref" ]; then
  branch_matches="true"
fi

# --- Detect primary language from diff ---

primary_language=$(python3 - "$tmpdir/diff.txt" <<'PYEOF'
import sys
import os
from collections import Counter

ext_to_lang = {
    '.js': 'javascript', '.jsx': 'javascript', '.mjs': 'javascript', '.cjs': 'javascript',
    '.ts': 'typescript', '.tsx': 'typescript', '.mts': 'typescript',
    '.py': 'python', '.pyi': 'python',
    '.go': 'go',
    '.cs': 'csharp',
    '.rs': 'rust',
    '.java': 'java',
    '.rb': 'ruby',
    '.php': 'php',
    '.swift': 'swift',
    '.kt': 'kotlin', '.kts': 'kotlin',
    '.c': 'c', '.h': 'c',
    '.cpp': 'cpp', '.cc': 'cpp', '.cxx': 'cpp', '.hpp': 'cpp',
    '.scala': 'scala',
    '.ex': 'elixir', '.exs': 'elixir',
    '.dart': 'dart',
    '.lua': 'lua',
    '.sh': 'bash', '.bash': 'bash', '.zsh': 'bash',
}

counts = Counter()
with open(sys.argv[1], 'r', errors='replace') as f:
    for line in f:
        if line.startswith('diff --git'):
            # Extract file path from "diff --git a/path b/path"
            parts = line.strip().split(' b/')
            if len(parts) >= 2:
                path = parts[-1]
                _, ext = os.path.splitext(path)
                ext = ext.lower()
                if ext in ext_to_lang:
                    counts[ext_to_lang[ext]] += 1

if counts:
    print(counts.most_common(1)[0][0])
else:
    print("null")
PYEOF
)

# Wrap null without quotes, language with quotes
if [ "$primary_language" = "null" ]; then
  primary_language_json="null"
else
  primary_language_json="\"$primary_language\""
fi

# --- Escape diff content for JSON ---

diff_escaped=$(python3 -c "
import json, sys
with open(sys.argv[1], 'r', errors='replace') as f:
    print(json.dumps(f.read()))
" "$tmpdir/diff.txt")

# --- Build output JSON ---

cat <<ENDJSON
{
  "repo": "$repo",
  "pr_number": $PR_NUMBER,
  "metadata": $pr_json,
  "commit_sha": "$commit_sha",
  "diff": {
    "lines": $diff_lines,
    "bytes": $diff_size,
    "content": $diff_escaped
  },
  "project_rules": {
    "claude_md": $claude_md,
    "review_md": $review_md
  },
  "eligibility": {
    "state": "$pr_state",
    "is_draft": $is_draft,
    "already_reviewed": $already_reviewed,
    "branch_matches": $branch_matches,
    "current_branch": "$current_branch",
    "head_ref": "$head_ref"
  },
  "primary_language": $primary_language_json,
  "parallel_requested": $PARALLEL_REQUESTED
}
ENDJSON
