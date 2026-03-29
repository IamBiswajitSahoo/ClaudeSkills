#!/usr/bin/env python3
"""Resolve a session name or UUID to its JSONL file path.

Scans JSONL files for "custom-title" entries matching the given name.
Supports exact UUID lookup and case-insensitive partial name matching.

Usage: python3 resolve-session.py <name-or-uuid>
"""

import sys
import os
import json
import re


def resolve_session(claude_dir, query):
    projects_dir = os.path.join(claude_dir, "projects")
    uuid_pattern = re.compile(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    )

    if not query:
        return {"error": "No session name or UUID provided"}

    if not os.path.isdir(projects_dir):
        return {"error": "~/.claude/projects/ directory not found"}

    def decode_project_path(proj_name):
        return "/" + proj_name.lstrip("-").replace("-", "/")

    # If query is a UUID, find the JSONL file directly
    if uuid_pattern.match(query):
        for proj_name in os.listdir(projects_dir):
            proj_path = os.path.join(projects_dir, proj_name)
            if not os.path.isdir(proj_path):
                continue
            jsonl_file = os.path.join(proj_path, f"{query}.jsonl")
            if os.path.isfile(jsonl_file):
                return {
                    "uuid": query,
                    "jsonl_path": jsonl_file,
                    "project": decode_project_path(proj_name),
                    "project_dir": proj_name,
                }
        return {"error": f"No session found with UUID: {query}"}

    # Search by custom title (case-insensitive partial match)
    matches = []
    query_lower = query.lower()

    for proj_name in os.listdir(projects_dir):
        proj_path = os.path.join(projects_dir, proj_name)
        if not os.path.isdir(proj_path):
            continue

        for fname in os.listdir(proj_path):
            if not fname.endswith(".jsonl"):
                continue
            uuid = fname[:-6]
            if not uuid_pattern.match(uuid):
                continue

            jsonl_file = os.path.join(proj_path, fname)
            try:
                with open(jsonl_file) as f:
                    for line in f:
                        try:
                            data = json.loads(line)
                        except json.JSONDecodeError:
                            continue

                        if data.get("type") == "custom-title":
                            title = data.get("customTitle", "")
                            if (
                                title.lower() == query_lower
                                or query_lower in title.lower()
                            ):
                                matches.append(
                                    {
                                        "uuid": uuid,
                                        "jsonl_path": jsonl_file,
                                        "project": decode_project_path(proj_name),
                                        "project_dir": proj_name,
                                        "display_name": title,
                                    }
                                )
                            break  # Only one custom-title per file
            except Exception:
                continue

    if len(matches) == 1:
        return matches[0]
    elif len(matches) > 1:
        names = [m["display_name"] for m in matches]
        return {
            "error": f"Multiple sessions match '{query}': {', '.join(names)}. Use a more specific name or UUID."
        }

    return {"error": f"No session found matching: {query}"}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: resolve-session.py <name-or-uuid>"}))
        sys.exit(1)

    claude_dir = os.path.join(os.path.expanduser("~"), ".claude")
    result = resolve_session(claude_dir, sys.argv[1])
    print(json.dumps(result, indent=2))
