#!/usr/bin/env python3
"""Estimate token count and context budget for a session JSONL file.

Outputs JSON with message count, estimated tokens, file size, and budget impact.

Usage: python3 estimate-context.py <jsonl-path>
"""

import sys
import os
import json
from datetime import datetime


def estimate_context(jsonl_path):
    if not os.path.isfile(jsonl_path):
        return {"error": f"JSONL file not found: {jsonl_path}"}

    file_size = os.path.getsize(jsonl_path)

    user_msgs = 0
    assistant_msgs = 0
    tool_use_count = 0
    tool_result_count = 0
    subagent_results = 0
    timestamps = []
    line_count = 0

    with open(jsonl_path) as f:
        for line in f:
            line_count += 1
            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type", "")
            ts = data.get("timestamp", "")
            if ts:
                timestamps.append(ts)

            if msg_type == "user":
                msg = data.get("message", {})
                if isinstance(msg, dict):
                    content = msg.get("content", "")
                    if isinstance(content, str) and content.strip():
                        user_msgs += 1
                    elif isinstance(content, list):
                        has_tool_result = any(
                            isinstance(c, dict) and c.get("type") == "tool_result"
                            for c in content
                        )
                        if has_tool_result:
                            tool_result_count += 1
                        else:
                            user_msgs += 1

                if data.get("toolUseResult"):
                    subagent_results += 1

            elif msg_type == "assistant":
                assistant_msgs += 1
                msg = data.get("message", {})
                if isinstance(msg, dict):
                    content = msg.get("content", [])
                    if isinstance(content, list):
                        for c in content:
                            if isinstance(c, dict) and c.get("type") == "tool_use":
                                tool_use_count += 1

    # Token estimates
    estimated_tokens_full = file_size // 4
    estimated_tokens_text = file_size * 35 // 400  # ~35% of file is text content

    # Duration
    duration_minutes = 0
    started = ""
    ended = ""
    if len(timestamps) >= 2:
        try:
            start = datetime.fromisoformat(timestamps[0].replace("Z", "+00:00"))
            end = datetime.fromisoformat(timestamps[-1].replace("Z", "+00:00"))
            duration_minutes = int((end - start).total_seconds() / 60)
            started = timestamps[0]
            ended = timestamps[-1]
        except (ValueError, IndexError):
            pass

    # Context budget (assume 1M token window)
    context_window = 1000000
    full_pct = round(estimated_tokens_full / context_window * 100, 1)
    text_pct = round(estimated_tokens_text / context_window * 100, 1)

    # File size human readable
    if file_size < 1024:
        size_human = f"{file_size} B"
    elif file_size < 1048576:
        size_human = f"{file_size / 1024:.1f} KB"
    else:
        size_human = f"{file_size / 1048576:.1f} MB"

    return {
        "file_size_bytes": file_size,
        "file_size_human": size_human,
        "line_count": line_count,
        "user_messages": user_msgs,
        "assistant_messages": assistant_msgs,
        "tool_use_count": tool_use_count,
        "tool_result_count": tool_result_count,
        "subagent_results": subagent_results,
        "estimated_tokens_full": estimated_tokens_full,
        "estimated_tokens_text": estimated_tokens_text,
        "context_pct_full": full_pct,
        "context_pct_text": text_pct,
        "duration_minutes": duration_minutes,
        "started_at": started,
        "ended_at": ended,
        "budget_warning": full_pct > 40,
    }


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: estimate-context.py <jsonl-path>"}))
        sys.exit(1)

    result = estimate_context(sys.argv[1])
    print(json.dumps(result, indent=2))
