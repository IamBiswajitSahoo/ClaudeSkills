#!/usr/bin/env python3
"""Analyze session JSONL and recommend a summarization template.

Checks tool use ratios, keyword presence, message counts, and session duration.
Outputs recommended template name, confidence, and reasoning.

Usage: python3 detect-template.py <jsonl-path>
"""

import sys
import os
import json
import re
from collections import Counter
from datetime import datetime


def detect_template(jsonl_path):
    if not os.path.isfile(jsonl_path):
        return {"error": f"JSONL file not found: {jsonl_path}"}

    tool_names = Counter()
    user_messages = []
    user_msg_count = 0
    assistant_msg_count = 0
    tool_use_lines = 0
    timestamps = []

    with open(jsonl_path) as f:
        for line in f:
            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type", "")
            ts = data.get("timestamp", "")
            if ts:
                timestamps.append(ts)

            if msg_type == "assistant":
                assistant_msg_count += 1
                msg = data.get("message", {})
                if isinstance(msg, dict):
                    content = msg.get("content", [])
                    if isinstance(content, list):
                        for c in content:
                            if isinstance(c, dict) and c.get("type") == "tool_use":
                                tool_use_lines += 1
                                tool_names[c.get("name", "unknown")] += 1

            elif msg_type == "user":
                msg = data.get("message", {})
                if isinstance(msg, dict):
                    content = msg.get("content", "")
                    if isinstance(content, str) and content.strip():
                        user_msg_count += 1
                        user_messages.append(content.lower())

    # Calculate signals
    total_messages = user_msg_count + assistant_msg_count
    edit_write_bash = (
        tool_names.get("Edit", 0)
        + tool_names.get("Write", 0)
        + tool_names.get("Bash", 0)
    )
    total_tool_uses = sum(tool_names.values())
    tool_ratio = edit_write_bash / max(total_tool_uses, 1)
    tool_pct_of_msgs = total_tool_uses / max(total_messages, 1)

    # Keyword scanning
    all_user_text = " ".join(user_messages)
    decision_keywords = len(
        re.findall(
            r"\b(decide|decision|architect|design|plan|trade.?off|approach|strategy|should we|which option)\b",
            all_user_text,
        )
    )
    research_keywords = len(
        re.findall(
            r"\b(research|investigate|find out|look into|explore|what is|how does|can you check|search)\b",
            all_user_text,
        )
    )

    # Average user message length
    avg_user_len = (
        sum(len(m) for m in user_messages) / max(len(user_messages), 1)
    )

    # Session duration in minutes
    duration_minutes = 0
    if len(timestamps) >= 2:
        try:
            start = datetime.fromisoformat(timestamps[0].replace("Z", "+00:00"))
            end = datetime.fromisoformat(timestamps[-1].replace("Z", "+00:00"))
            duration_minutes = int((end - start).total_seconds() / 60)
        except (ValueError, IndexError):
            pass

    # Apply rules (ordered by specificity)
    template = "default"
    confidence = "medium"
    reason = "Mixed content, no dominant pattern"

    if total_messages < 30:
        template = "quick"
        confidence = "high"
        reason = f"Small session ({total_messages} messages) — quick summary sufficient"

    elif tool_ratio > 0.6 and total_tool_uses > 10:
        template = "actions"
        confidence = "high"
        reason = (
            f"High code-change ratio: {edit_write_bash} Edit/Write/Bash "
            f"out of {total_tool_uses} tool uses ({tool_ratio:.0%})"
        )

    elif decision_keywords > 5:
        template = "decisions"
        confidence = "high" if decision_keywords > 10 else "medium"
        reason = f"Decision-heavy: {decision_keywords} decision/architecture keywords found"

    elif tool_pct_of_msgs < 0.2 and avg_user_len > 200:
        template = "discussion"
        confidence = "medium"
        reason = (
            f"Discussion-heavy: low tool use ({tool_pct_of_msgs:.0%}), "
            f"long user messages (avg {avg_user_len:.0f} chars)"
        )

    elif total_messages > 100 or duration_minutes > 180:
        template = "timeline"
        confidence = "high" if total_messages > 200 else "medium"
        reason = f"Long session: {total_messages} messages over {duration_minutes} minutes"

    elif research_keywords > 5:
        template = "discussion"
        confidence = "medium"
        reason = f"Research-heavy: {research_keywords} research/investigation keywords found"

    return {
        "recommended_template": template,
        "confidence": confidence,
        "reason": reason,
        "signals": {
            "total_messages": total_messages,
            "user_messages": user_msg_count,
            "assistant_messages": assistant_msg_count,
            "total_tool_uses": total_tool_uses,
            "edit_write_bash": edit_write_bash,
            "tool_ratio": round(tool_ratio, 2),
            "tool_pct_of_msgs": round(tool_pct_of_msgs, 2),
            "decision_keywords": decision_keywords,
            "research_keywords": research_keywords,
            "avg_user_msg_length": round(avg_user_len),
            "duration_minutes": duration_minutes,
            "top_tools": dict(tool_names.most_common(5)),
        },
    }


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: detect-template.py <jsonl-path>"}))
        sys.exit(1)

    result = detect_template(sys.argv[1])
    print(json.dumps(result, indent=2))
