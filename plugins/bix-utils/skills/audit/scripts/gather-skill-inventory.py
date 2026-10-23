#!/usr/bin/env python3
"""Inventory a skill directory for audit.

Walks the skill directory, extracts SKILL.md frontmatter, lists all files
with metadata, and flags executable files, scripts, binaries, URLs, and
environment variable references.

Usage: python3 gather-skill-inventory.py <skill-path>
"""

import sys
import os
import json
import re


BINARY_EXTENSIONS = {".exe", ".dmg", ".bin", ".dll", ".so", ".dylib", ".zip", ".tar", ".gz", ".rar", ".7z"}
SCRIPT_EXTENSIONS = {".sh", ".bash", ".zsh", ".py", ".rb", ".pl", ".js", ".ts"}


def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        print('{"error": "No skill path provided. Usage: gather-skill-inventory.py <skill-path>"}')
        sys.exit(1)

    skill_path = os.path.abspath(sys.argv[1])

    if not os.path.isdir(skill_path):
        print(json.dumps({"error": f"Not a directory: {skill_path}"}))
        sys.exit(1)

    skill_md_path = os.path.join(skill_path, "SKILL.md")
    if not os.path.isfile(skill_md_path):
        print(json.dumps({"error": f"No SKILL.md found in {skill_path}"}))
        sys.exit(1)

    files, executable_files, script_files, binary_suspects, total_size = _inventory_files(skill_path)
    frontmatter, allowed_tools, urls_found, env_refs, skill_md_lines = _parse_skill_md(skill_md_path)

    result = {
        "path": skill_path,
        "skill_name": frontmatter.get("name", os.path.basename(skill_path)),
        "frontmatter": frontmatter,
        "allowed_tools": allowed_tools,
        "file_count": len(files),
        "total_size_bytes": total_size,
        "files": files,
        "executable_files": executable_files,
        "script_files": script_files,
        "binary_suspects": binary_suspects,
        "urls_found": urls_found,
        "env_references": env_refs,
        "skill_md_lines": skill_md_lines,
        "has_scripts_dir": os.path.isdir(os.path.join(skill_path, "scripts")),
        "has_templates_dir": os.path.isdir(os.path.join(skill_path, "templates")),
    }

    print(json.dumps(result, indent=2))


def _inventory_files(skill_path):
    """Walk skill directory and categorize all files."""
    files = []
    executable_files = []
    script_files = []
    binary_suspects = []
    total_size = 0

    for root, dirs, filenames in os.walk(skill_path):
        dirs[:] = [d for d in dirs if not d.startswith(".") and d != "node_modules"]
        for fname in filenames:
            fpath = os.path.join(root, fname)
            rel_path = os.path.relpath(fpath, skill_path)
            try:
                size = os.stat(fpath).st_size
                total_size += size
                is_exec = os.access(fpath, os.X_OK)
                ext = os.path.splitext(fname)[1].lower()

                files.append({"path": rel_path, "size": size, "executable": is_exec, "extension": ext})

                if is_exec and ext not in {".md", ".txt", ".json", ".yaml", ".yml"}:
                    executable_files.append(rel_path)
                if ext in SCRIPT_EXTENSIONS:
                    script_files.append(rel_path)
                if ext in BINARY_EXTENSIONS:
                    binary_suspects.append(rel_path)
            except (OSError, IOError):
                continue

    return files, executable_files, script_files, binary_suspects, total_size


def _parse_skill_md(skill_md_path):
    """Extract frontmatter, allowed tools, URLs, and env refs from SKILL.md."""
    with open(skill_md_path, "r", errors="replace") as f:
        content = f.read()

    # Parse YAML frontmatter
    frontmatter = {}
    fm_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    if fm_match:
        for line in fm_match.group(1).split("\n"):
            if ":" in line:
                key, _, val = line.partition(":")
                key, val = key.strip(), val.strip().strip("\"'")
                if key and val:
                    frontmatter[key] = val

    allowed_tools_match = re.search(r"allowed-tools:\s*(.*?)$", content, re.MULTILINE)
    allowed_tools = allowed_tools_match.group(1).strip() if allowed_tools_match else None

    urls_found = list(set(re.findall(r"https?://[^\s\"'<>)]+", content)))

    env_pattern = re.compile(
        r"(?:process\.env|os\.environ|\$\{?\w*(?:KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)\w*\}?)",
        re.IGNORECASE,
    )
    env_refs = list(set(env_pattern.findall(content)))

    return frontmatter, allowed_tools, urls_found, env_refs, content.count("\n") + 1


if __name__ == "__main__":
    main()
