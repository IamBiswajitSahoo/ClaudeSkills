#!/usr/bin/env bash
# gather-pr-comments.sh — Fetch PR review comments, review bodies, and threading info
# Outputs structured JSON with all review feedback grouped by thread
# Requires: gh CLI (authenticated)
#
# Usage: bash gather-pr-comments.sh <PR_NUMBER>

set -euo pipefail

PR_NUMBER="${1:-}"

# --- Validate input ---

if [ -z "$PR_NUMBER" ]; then
  echo '{"error": "No PR number provided. Usage: gather-pr-comments.sh <PR_NUMBER>"}'
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

owner=$(echo "$repo" | cut -d/ -f1)
name=$(echo "$repo" | cut -d/ -f2)

# --- Fetch PR metadata (verify PR exists) ---

pr_json=$(gh pr view "$PR_NUMBER" --json title,headRefName,baseRefName,state,url 2>/dev/null) || {
  echo "{\"error\": \"PR #${PR_NUMBER} not found in ${repo}\"}"
  exit 1
}

# --- Fetch all data into temp files ---

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Inline review comments (code-level)
gh api "repos/${owner}/${name}/pulls/${PR_NUMBER}/comments" --paginate > "$tmpdir/inline.json" 2>/dev/null || {
  echo '{"error": "Failed to fetch inline review comments"}'
  exit 1
}

# Review bodies (top-level reviews: approve, request changes, comment)
gh api "repos/${owner}/${name}/pulls/${PR_NUMBER}/reviews" --paginate > "$tmpdir/reviews.json" 2>/dev/null || {
  echo '{"error": "Failed to fetch review summaries"}'
  exit 1
}

# --- Process with python3 for reliable JSON handling ---

python3 - "$tmpdir/inline.json" "$tmpdir/reviews.json" "$PR_NUMBER" "$repo" "$pr_json" <<'PYEOF'
import json
import sys

inline_path = sys.argv[1]
reviews_path = sys.argv[2]
pr_number = int(sys.argv[3])
repo = sys.argv[4]
pr_meta = json.loads(sys.argv[5])

# Load inline comments
with open(inline_path) as f:
    content = f.read().strip()
    # gh --paginate may concatenate multiple JSON arrays
    if content.startswith("["):
        # Handle concatenated arrays: ][  ->  ,
        content = content.replace("][", ",")
    inline_raw = json.loads(content) if content else []

# Load reviews
with open(reviews_path) as f:
    content = f.read().strip()
    if content.startswith("["):
        content = content.replace("][", ",")
    reviews_raw = json.loads(content) if content else []

# --- Build inline comments with thread grouping ---

comments_by_id = {}
threads = []  # list of thread roots
reply_map = {}  # in_reply_to_id -> list of replies

for c in inline_raw:
    comment = {
        "id": c["id"],
        "author": c.get("user", {}).get("login", "unknown"),
        "path": c.get("path", ""),
        "line": c.get("line") or c.get("original_line"),
        "body": c.get("body", ""),
        "diff_hunk": c.get("diff_hunk", ""),
        "created_at": c.get("created_at", ""),
        "in_reply_to_id": c.get("in_reply_to_id"),
        # GitHub doesn't have a direct "resolved" field on comments,
        # but we can check via the pull_request_review_id association
    }
    comments_by_id[c["id"]] = comment

    if c.get("in_reply_to_id"):
        parent_id = c["in_reply_to_id"]
        reply_map.setdefault(parent_id, []).append(comment)
    else:
        threads.append(comment)

# Build threaded structure
inline_threads = []
for root in threads:
    thread = {
        "root": root,
        "replies": reply_map.get(root["id"], []),
        "path": root["path"],
        "line": root["line"],
    }
    inline_threads.append(thread)

# --- Build review summaries (top-level review bodies) ---
# Filter out reviews with empty bodies (e.g., approvals with no comment)

review_summaries = []
for r in reviews_raw:
    body = (r.get("body") or "").strip()
    if not body:
        continue
    review_summaries.append({
        "id": r["id"],
        "author": r.get("user", {}).get("login", "unknown"),
        "state": r.get("state", ""),  # APPROVED, CHANGES_REQUESTED, COMMENTED
        "body": body,
        "submitted_at": r.get("submitted_at", ""),
    })

# --- Output ---

output = {
    "repo": repo,
    "pr_number": pr_number,
    "pr": pr_meta,
    "inline_threads": inline_threads,
    "review_summaries": review_summaries,
    "stats": {
        "total_inline_comments": len(inline_raw),
        "total_threads": len(inline_threads),
        "total_replies": sum(len(reply_map.get(t["id"], [])) for t in threads),
        "total_review_summaries": len(review_summaries),
    }
}

print(json.dumps(output, indent=2))
PYEOF
