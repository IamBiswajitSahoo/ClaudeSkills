#!/usr/bin/env bash
# gather-pr-comments.sh — Fetch PR review comments, review bodies, threading info and project rules
# Outputs structured JSON with review feedback grouped by thread. By default keeps only
# unresolved threads whose last comment is not from the current user (awaiting a reply).
# Requires: gh CLI (authenticated), python3
#
# Usage: bash gather-pr-comments.sh <PR_NUMBER> [-all]

set -euo pipefail

PR_NUMBER=""
INCLUDE_ALL="false"
for arg in "$@"; do
  case "$arg" in
    -all|--all) INCLUDE_ALL="true" ;;
    *) [ -z "$PR_NUMBER" ] && PR_NUMBER="$arg" ;;
  esac
done

# --- Validate input ---

if [ -z "$PR_NUMBER" ]; then
  echo '{"error": "No PR number provided. Usage: gather-pr-comments.sh <PR_NUMBER> [-all]"}'
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

# Thread state (resolved / outdated / node ID), keyed by each thread's root comment
gh api graphql --paginate -F owner="$owner" -F name="$name" -F number="$PR_NUMBER" -f query='
  query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $number) {
        reviewThreads(first: 100, after: $endCursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            isResolved
            isOutdated
            comments(first: 1) { nodes { databaseId } }
          }
        }
      }
    }
  }' > "$tmpdir/threads.json" 2>/dev/null || {
  echo '{"error": "Failed to fetch review thread state"}'
  exit 1
}

current_user=$(gh api user --jq '.login' 2>/dev/null || echo "")
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

# --- Process with python3 for reliable JSON handling ---

python3 - "$tmpdir/inline.json" "$tmpdir/reviews.json" "$PR_NUMBER" "$repo" "$pr_json" \
  "$tmpdir/threads.json" "$current_user" "$repo_root" "$INCLUDE_ALL" <<'PYEOF'
import glob
import json
import os
import sys

inline_path = sys.argv[1]
reviews_path = sys.argv[2]
pr_number = int(sys.argv[3])
repo = sys.argv[4]
pr_meta = json.loads(sys.argv[5])
threads_path = sys.argv[6]
current_user = sys.argv[7]
repo_root = sys.argv[8]
include_all = sys.argv[9] == "true"

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

# Load thread state (gh --paginate emits one JSON document per page)
thread_state = {}
with open(threads_path) as f:
    decoder, text, position = json.JSONDecoder(), f.read().strip(), 0
    while position < len(text):
        page, position = decoder.raw_decode(text, position)
        while position < len(text) and text[position].isspace():
            position += 1
        nodes = page["data"]["repository"]["pullRequest"]["reviewThreads"]["nodes"]
        for node in nodes:
            root_comments = node["comments"]["nodes"]
            if root_comments:
                thread_state[root_comments[0]["databaseId"]] = node

# Build threaded structure
all_threads = []
for root in threads:
    replies = sorted(reply_map.get(root["id"], []), key=lambda c: c["created_at"])
    last_author = (replies[-1] if replies else root)["author"]
    state = thread_state.get(root["id"], {})
    all_threads.append({
        "thread_node_id": state.get("id"),
        "is_resolved": state.get("isResolved", False),
        "is_outdated": state.get("isOutdated", False),
        "awaiting_reply": last_author != current_user,
        "root": root,
        "replies": replies,
        "path": root["path"],
        "line": root["line"],
    })

inline_threads = [
    t for t in all_threads
    if include_all or (not t["is_resolved"] and t["awaiting_reply"])
]

# --- Project rules: CLAUDE.md, REVIEW.md and .claude/rules/*.md ---
# Checked at the repo root and in every directory above a commented file, so a
# project nested in a subfolder of the repo still contributes its rules.

project_rules = {}
if repo_root:
    rule_dirs = {""}
    for t in all_threads:
        parent = os.path.dirname(t["path"])
        while parent:
            rule_dirs.add(parent)
            parent = os.path.dirname(parent)
    seen = set()
    for rule_dir in sorted(rule_dirs):
        base = os.path.join(repo_root, rule_dir)
        candidates = [os.path.join(base, "CLAUDE.md"), os.path.join(base, "REVIEW.md")]
        candidates += sorted(glob.glob(os.path.join(base, ".[Cc]laude", "rules", "*.md")))
        for path in candidates:
            real = os.path.realpath(path).lower()
            if os.path.isfile(path) and real not in seen:
                seen.add(real)
                with open(path, "r", errors="replace") as f:
                    project_rules[os.path.relpath(path, repo_root)] = f.read()

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
    "current_user": current_user,
    "include_all": include_all,
    "inline_threads": inline_threads,
    "review_summaries": review_summaries,
    "project_rules": project_rules,
    "stats": {
        "total_inline_comments": len(inline_raw),
        "total_threads": len(inline_threads),
        "total_threads_on_pr": len(all_threads),
        "resolved_threads": sum(1 for t in all_threads if t["is_resolved"]),
        "answered_threads": sum(1 for t in all_threads if not t["is_resolved"] and not t["awaiting_reply"]),
        "outdated_threads": sum(1 for t in inline_threads if t["is_outdated"]),
        "total_replies": sum(len(t["replies"]) for t in inline_threads),
        "total_review_summaries": len(review_summaries),
    }
}

print(json.dumps(output, indent=2))
PYEOF
