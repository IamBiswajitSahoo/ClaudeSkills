#!/usr/bin/env python3
"""Gather Claude Code hooks configuration for audit.

Reads hooks from settings files and analyzes their security properties —
what commands they run, what events they trigger on, and whether they
access the network, modify files, or read environment variables.

Usage: python3 gather-hooks-config.py
"""

import sys
import os
import json


def main():
    home = os.path.expanduser("~")
    cwd = os.getcwd()

    settings_paths = [
        os.path.join(home, ".claude", "settings.json"),
        os.path.join(home, ".claude", "settings.local.json"),
        os.path.join(cwd, ".claude", "settings.json"),
        os.path.join(cwd, ".claude", "settings.local.json"),
    ]

    hooks_found = []
    settings_checked = []

    for settings_path in settings_paths:
        exists = os.path.isfile(settings_path)
        scope = "global" if home in settings_path and cwd not in settings_path else "project"
        settings_checked.append({"path": settings_path, "exists": exists, "scope": scope})

        if not exists:
            continue

        try:
            with open(settings_path, "r", errors="replace") as f:
                data = json.load(f)
        except (json.JSONDecodeError, IOError, PermissionError) as e:
            settings_checked[-1]["error"] = str(e)
            continue

        hooks = data.get("hooks", {})
        if not hooks:
            continue

        for event_type, hook_list in hooks.items():
            if not isinstance(hook_list, list):
                hook_list = [hook_list]

            for hook in hook_list:
                if not isinstance(hook, dict):
                    continue
                hooks_found.append(_analyze_hook(hook, event_type, settings_path, scope))

    result = {
        "settings_checked": settings_checked,
        "hooks_found": hooks_found,
        "hook_count": len(hooks_found),
        "events_with_hooks": list(set(h["event"] for h in hooks_found)),
    }

    print(json.dumps(result, indent=2))


def _analyze_hook(hook, event_type, source_file, scope):
    """Analyze a single hook for security-relevant properties."""
    command = hook.get("command", "")
    matcher = hook.get("matcher", "")

    return {
        "source_file": source_file,
        "scope": scope,
        "event": event_type,
        "command": command,
        "matcher": matcher,
        "analysis": {
            "runs_script": any(ext in command for ext in [".sh", ".py", ".js", ".rb", ".pl"]),
            "uses_network": any(kw in command for kw in ["curl", "wget", "nc ", "ncat", "ssh ", "scp "]),
            "modifies_files": any(kw in command for kw in ["rm ", "mv ", "cp ", "> ", ">> ", "tee "]),
            "reads_env": "$" in command or "env" in command.lower(),
            "uses_pipe": "|" in command,
            "uses_eval": "eval " in command or "exec " in command,
            "triggers_on_all": not matcher or matcher == "*",
            "command_length": len(command),
        },
    }


if __name__ == "__main__":
    main()
