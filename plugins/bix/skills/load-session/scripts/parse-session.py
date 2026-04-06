#!/usr/bin/env python3
"""Parse a Claude Code session JSONL file into a readable conversation transcript.

Extracts user text, assistant text, and subagent final results (from toolUseResult).
Skips tool_use/tool_result noise. Formats as clean markdown.

Usage: python3 parse-session.py <jsonl-path> [--max-lines <n>]
"""

import sys
import json
import os
from datetime import datetime


def format_timestamp(ts_str):
    """Convert ISO timestamp to readable format."""
    try:
        dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
        return dt.strftime("%Y-%m-%d %H:%M")
    except (ValueError, AttributeError):
        return ""


def extract_text_content(content):
    """Extract plain text from message content (string or list of blocks)."""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        texts = []
        for block in content:
            if isinstance(block, dict):
                if block.get("type") == "text":
                    text = block.get("text", "").strip()
                    if text:
                        texts.append(text)
        return "\n".join(texts)
    return ""


def extract_subagent_summary(tool_use_result):
    """Extract the final result text from a subagent toolUseResult."""
    if not isinstance(tool_use_result, dict):
        return None

    status = tool_use_result.get("status", "")
    if status != "completed":
        return None

    prompt = tool_use_result.get("prompt", "")
    agent_type = tool_use_result.get("agentType", "")
    content = tool_use_result.get("content", [])

    result_text = ""
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text":
            result_text += block.get("text", "")

    if not result_text:
        return None

    return {
        "agent_type": agent_type,
        "prompt": prompt[:200] if prompt else "",
        "result": result_text,
    }


def parse_session(jsonl_path, max_chars=None):
    """Parse JSONL into a structured conversation transcript."""
    if not os.path.exists(jsonl_path):
        return {"error": f"File not found: {jsonl_path}"}

    transcript = []
    session_meta = {}
    char_count = 0

    with open(jsonl_path) as f:
        for line in f:
            try:
                data = json.loads(line)
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type", "")
            timestamp = data.get("timestamp", "")
            time_str = format_timestamp(timestamp)

            # Capture session metadata from first entry
            if not session_meta:
                session_meta = {
                    "session_id": data.get("sessionId", ""),
                    "git_branch": data.get("gitBranch", ""),
                    "cwd": data.get("cwd", ""),
                    "version": data.get("version", ""),
                }

            # Custom title
            if msg_type == "custom-title":
                session_meta["title"] = data.get("customTitle", "")
                continue

            # User messages
            if msg_type == "user":
                message = data.get("message", {})
                if not isinstance(message, dict):
                    continue

                # Check for subagent results
                tool_result = data.get("toolUseResult")
                if tool_result:
                    summary = extract_subagent_summary(tool_result)
                    if summary:
                        entry = {
                            "role": "subagent",
                            "time": time_str,
                            "agent_type": summary["agent_type"],
                            "prompt": summary["prompt"],
                            "content": summary["result"],
                        }
                        char_count += len(summary["result"])
                        transcript.append(entry)
                    continue

                content = message.get("content", "")
                text = extract_text_content(content)
                if text:
                    entry = {"role": "user", "time": time_str, "content": text}
                    char_count += len(text)
                    transcript.append(entry)

            # Assistant messages — text only, skip tool_use
            elif msg_type == "assistant":
                message = data.get("message", {})
                if not isinstance(message, dict):
                    continue

                content = message.get("content", [])
                text = extract_text_content(content)
                if text:
                    entry = {"role": "assistant", "time": time_str, "content": text}
                    char_count += len(text)
                    transcript.append(entry)

            # Skip: system, file-history-snapshot, tool_use, tool_result

            if max_chars and char_count > max_chars:
                transcript.append(
                    {
                        "role": "system",
                        "content": f"[Transcript truncated at {max_chars} characters]",
                    }
                )
                break

    return {
        "meta": session_meta,
        "transcript": transcript,
        "stats": {
            "total_entries": len(transcript),
            "char_count": char_count,
            "estimated_tokens": char_count // 4,
        },
    }


def format_as_markdown(result):
    """Format parsed session as readable markdown transcript."""
    if "error" in result:
        return f"**Error:** {result['error']}"

    meta = result["meta"]
    stats = result["stats"]
    lines = []

    # Header
    title = meta.get("title", "Unnamed Session")
    lines.append(f"# Session: {title}")
    lines.append("")
    lines.append(
        f"**Branch:** {meta.get('git_branch', 'unknown')} | "
        f"**Messages:** {stats['total_entries']} | "
        f"**Est. tokens:** ~{stats['estimated_tokens']:,}"
    )
    lines.append("")
    lines.append("---")
    lines.append("")

    for entry in result["transcript"]:
        role = entry.get("role", "")
        time_str = entry.get("time", "")
        content = entry.get("content", "")

        if role == "user":
            lines.append(f"### User ({time_str})")
            lines.append("")
            lines.append(content)
            lines.append("")

        elif role == "assistant":
            lines.append(f"### Assistant ({time_str})")
            lines.append("")
            lines.append(content)
            lines.append("")

        elif role == "subagent":
            agent_type = entry.get("agent_type", "agent")
            prompt = entry.get("prompt", "")
            lines.append(f"### Subagent: {agent_type} ({time_str})")
            if prompt:
                lines.append(f"*Task: {prompt}*")
            lines.append("")
            # Truncate very long subagent results
            if len(content) > 2000:
                lines.append(content[:2000])
                lines.append(f"\n*[Truncated — full result was {len(content)} chars]*")
            else:
                lines.append(content)
            lines.append("")

        elif role == "system":
            lines.append(f"*{content}*")
            lines.append("")

    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: parse-session.py <jsonl-path> [--max-chars <n>] [--format json|markdown] [--out-file <path>]"}))
        sys.exit(1)

    jsonl_path = sys.argv[1]
    max_chars = None
    output_format = "markdown"
    out_file = None

    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--max-chars" and i + 1 < len(sys.argv):
            max_chars = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == "--format" and i + 1 < len(sys.argv):
            output_format = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--out-file" and i + 1 < len(sys.argv):
            out_file = sys.argv[i + 1]
            i += 2
        else:
            i += 1

    result = parse_session(jsonl_path, max_chars=max_chars)

    # --out-file: write transcript to disk, return only metadata to stdout.
    # Keeps the (potentially huge) transcript out of the caller's context.
    if out_file:
        if "error" in result:
            print(json.dumps(result))
            sys.exit(1)
        markdown = format_as_markdown(result)
        try:
            import tempfile
            if out_file == "auto":
                fd, out_file = tempfile.mkstemp(
                    prefix="bix-load-session-", suffix=".md"
                )
                os.close(fd)
            with open(out_file, "w") as f:
                f.write(markdown)
        except Exception as e:
            print(json.dumps({"error": f"Failed to write transcript: {e}"}))
            sys.exit(1)
        print(json.dumps({
            "transcript_path": out_file,
            "char_count": result["stats"]["char_count"],
            "estimated_tokens": result["stats"]["estimated_tokens"],
            "entries": result["stats"]["total_entries"],
        }))
        sys.exit(0)

    if output_format == "json":
        print(json.dumps(result, indent=2))
    else:
        print(format_as_markdown(result))
