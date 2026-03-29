#!/usr/bin/env python3
"""List recent Claude Code sessions across projects.

Outputs JSON with sessions sorted by last modified, paginated.
Displays custom title if named, else first user message as fallback.

Usage: python3 list-sessions.py [--project <path>] [--page <n>] [--per-page <n>]
"""

import sys
import os
import json
import re
import argparse


def list_sessions(claude_dir, page=1, per_page=5, project_filter=""):
    projects_dir = os.path.join(claude_dir, "projects")
    uuid_pattern = re.compile(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    )

    if not os.path.isdir(projects_dir):
        return {"error": "~/.claude/projects/ directory not found", "sessions": []}

    sessions = []

    for proj_name in os.listdir(projects_dir):
        proj_path_full = os.path.join(projects_dir, proj_name)
        if not os.path.isdir(proj_path_full):
            continue

        # Decode project path
        proj_path = "/" + proj_name.lstrip("-").replace("-", "/")

        # Apply project filter
        if project_filter and project_filter.lower() not in proj_name.lower():
            continue

        for fname in os.listdir(proj_path_full):
            if not fname.endswith(".jsonl"):
                continue
            uuid = fname[:-6]
            if not uuid_pattern.match(uuid):
                continue

            jsonl_file = os.path.join(proj_path_full, fname)
            file_size = os.path.getsize(jsonl_file)

            custom_title = ""
            first_user_msg = ""
            started_at = ""
            git_branch = ""
            user_msg_count = 0
            last_timestamp = ""

            try:
                with open(jsonl_file) as f:
                    for line in f:
                        try:
                            data = json.loads(line)
                        except json.JSONDecodeError:
                            continue

                        msg_type = data.get("type", "")
                        ts = data.get("timestamp", "")
                        if ts:
                            last_timestamp = ts
                        if not started_at and ts:
                            started_at = ts
                        if not git_branch:
                            git_branch = data.get("gitBranch", "")

                        if msg_type == "custom-title":
                            custom_title = data.get("customTitle", "")

                        elif msg_type == "user":
                            msg = data.get("message", {})
                            if isinstance(msg, dict):
                                content = msg.get("content", "")
                                if isinstance(content, str) and content.strip():
                                    user_msg_count += 1
                                    if not first_user_msg:
                                        first_user_msg = content.strip()[:80]
                                elif isinstance(content, list):
                                    user_msg_count += 1
                                    if not first_user_msg:
                                        for c in content:
                                            if (
                                                isinstance(c, dict)
                                                and c.get("type") == "text"
                                            ):
                                                first_user_msg = (
                                                    c["text"].strip()[:80]
                                                )
                                                break
            except Exception:
                continue

            display_name = custom_title or first_user_msg or "unnamed session"
            last_modified = os.path.getmtime(jsonl_file)

            # File size human readable
            if file_size < 1024:
                size_human = f"{file_size} B"
            elif file_size < 1048576:
                size_human = f"{file_size / 1024:.1f} KB"
            else:
                size_human = f"{file_size / 1048576:.1f} MB"

            sessions.append(
                {
                    "uuid": uuid,
                    "display_name": display_name,
                    "is_named": bool(custom_title),
                    "project": proj_path,
                    "project_dir": proj_name,
                    "file_size_bytes": file_size,
                    "file_size_human": size_human,
                    "message_count": user_msg_count,
                    "started_at": started_at,
                    "git_branch": git_branch,
                    "last_modified": last_modified,
                }
            )

    # Sort by last_modified descending
    sessions.sort(key=lambda s: s.get("last_modified", 0), reverse=True)

    total = len(sessions)
    start = (page - 1) * per_page
    end = start + per_page
    page_sessions = sessions[start:end]
    projects = sorted(set(s["project"] for s in sessions))

    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "total_pages": (total + per_page - 1) // per_page if total > 0 else 1,
        "projects": projects,
        "sessions": page_sessions,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="List Claude Code sessions")
    parser.add_argument("--project", default="", help="Filter by project path")
    parser.add_argument("--page", type=int, default=1, help="Page number")
    parser.add_argument("--per-page", type=int, default=5, help="Sessions per page")
    args = parser.parse_args()

    claude_dir = os.path.join(os.path.expanduser("~"), ".claude")
    result = list_sessions(claude_dir, args.page, args.per_page, args.project)
    print(json.dumps(result, indent=2))
