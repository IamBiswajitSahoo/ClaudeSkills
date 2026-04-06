#!/usr/bin/env python3
"""Gather MCP server configurations for audit.

Reads MCP configs from Claude Code settings files and outputs structured JSON
with server details, commands, arguments, and security-relevant metadata.

Usage: python3 gather-mcp-config.py [server-name]
"""

import sys
import os
import json


def main():
    target_server = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else None

    home = os.path.expanduser("~")
    cwd = os.getcwd()

    config_locations = [
        os.path.join(home, ".claude", "settings.json"),
        os.path.join(home, ".claude", "settings.local.json"),
        os.path.join(cwd, ".claude", "settings.json"),
        os.path.join(cwd, ".claude", "settings.local.json"),
        os.path.join(cwd, "CLAUDE.md"),
        os.path.join(cwd, ".claude", "CLAUDE.md"),
        os.path.join(home, ".claude", "mcp_servers.json"),
    ]

    servers_found = []
    config_files_checked = []
    raw_configs = {}

    for config_path in config_locations:
        exists = os.path.isfile(config_path)
        config_files_checked.append({"path": config_path, "exists": exists})

        if not exists:
            continue

        try:
            with open(config_path, "r", errors="replace") as f:
                content = f.read()
        except (IOError, PermissionError) as e:
            config_files_checked[-1]["error"] = str(e)
            continue

        try:
            data = json.loads(content)
        except json.JSONDecodeError:
            raw_configs[config_path] = content[:2000]
            continue

        mcp_data = _extract_mcp_servers(data)
        if not mcp_data:
            continue

        for server_name, server_config in mcp_data.items():
            if target_server and server_name != target_server:
                continue
            servers_found.append(_analyze_server(server_name, server_config, config_path))

    result = {
        "target_server": target_server,
        "config_files_checked": config_files_checked,
        "servers_found": servers_found,
        "server_count": len(servers_found),
        "raw_configs": raw_configs or None,
    }

    print(json.dumps(result, indent=2))


def _extract_mcp_servers(data):
    """Find mcpServers in various nesting structures."""
    for key in ("mcpServers", "mcp_servers"):
        if key in data:
            return data[key]
    for proj_val in data.get("projects", {}).values():
        if isinstance(proj_val, dict) and "mcpServers" in proj_val:
            return proj_val["mcpServers"]
    return None


def _analyze_server(name, config, source_file):
    """Analyze a single MCP server config for security-relevant properties."""
    command = config.get("command", "")
    args = config.get("args", [])
    if not isinstance(args, list):
        args = [args]
    env = config.get("env", {})

    return {
        "name": name,
        "source_file": source_file,
        "config": config,
        "analysis": {
            "command": command,
            "args": args,
            "has_env_vars": bool(env),
            "env_var_names": list(env.keys()) if isinstance(env, dict) else [],
            "uses_npx": "npx" in str(command),
            "uses_node": "node" in str(command),
            "uses_python": "python" in str(command) or "uvx" in str(command),
            "uses_docker": "docker" in str(command),
            "package_name": args[0] if args else None,
            "has_url_args": any("http" in str(a) for a in args),
        },
    }


if __name__ == "__main__":
    main()
