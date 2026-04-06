#!/usr/bin/env python3
"""Resolve an audit target to a local directory.

Accepts a local path, GitHub URL, or npm package name. For remote targets,
downloads to a temporary directory. Outputs JSON with the resolved local path
and metadata about the source.

Usage:
  python3 resolve-target.py <target> --type skill|mcp
  python3 resolve-target.py ./local/path --type skill
  python3 resolve-target.py https://github.com/user/repo --type skill
  python3 resolve-target.py https://github.com/user/repo/tree/main/skills/my-skill --type skill
  python3 resolve-target.py @scope/package --type mcp
"""

import sys
import os
import json
import re
import subprocess
import tempfile


def main():
    target, target_type = _parse_args()
    source_kind = _classify_target(target)

    if source_kind == "local":
        _handle_local(target, target_type)
    elif source_kind == "github_url":
        _handle_github_url(target, target_type)
    elif source_kind == "npm_package":
        _handle_npm_package(target, target_type)
    else:
        print(json.dumps({"error": f"Cannot resolve target: {target}. Provide a local path, GitHub URL, or npm package name."}))
        sys.exit(1)


def _parse_args():
    target = ""
    target_type = "skill"
    expect_type = False

    for arg in sys.argv[1:]:
        if arg == "--type":
            expect_type = True
        elif expect_type:
            target_type = arg
            expect_type = False
        elif not target:
            target = arg

    if not target:
        print('{"error": "No target provided. Usage: resolve-target.py <path|url|package> --type skill|mcp"}')
        sys.exit(1)

    return target, target_type


def _classify_target(target):
    """Determine if target is a local path, GitHub URL, or npm package."""
    if os.path.exists(target):
        return "local"
    if re.match(r"https?://github\.com/", target):
        return "github_url"
    if re.match(r"https?://", target):
        return "github_url"  # Treat other URLs as fetchable too
    if target.startswith("@") or re.match(r"^[a-z][a-z0-9-]*(/|$)", target):
        return "npm_package"
    # Could be a local path that doesn't exist yet
    return "unknown"


def _handle_local(target, target_type):
    """Handle a local path target."""
    abs_path = os.path.abspath(target)

    result = {
        "source": "local",
        "original_target": target,
        "resolved_path": abs_path,
        "is_temporary": False,
        "target_type": target_type,
    }

    if target_type == "skill":
        skill_md = os.path.join(abs_path, "SKILL.md")
        result["has_skill_md"] = os.path.isfile(skill_md)
        if not os.path.isdir(abs_path):
            result["error"] = f"Not a directory: {abs_path}"
        elif not result["has_skill_md"]:
            result["error"] = f"No SKILL.md found in {abs_path}"

    print(json.dumps(result, indent=2))


def _handle_github_url(target, target_type):
    """Download a GitHub repo/subdirectory to a temp directory."""
    # Check if git is available
    if not _command_exists("git"):
        print(json.dumps({"error": "git is not installed. Required to download GitHub repositories."}))
        sys.exit(1)

    # Parse GitHub URL
    parsed = _parse_github_url(target)
    if not parsed:
        print(json.dumps({"error": f"Could not parse GitHub URL: {target}"}))
        sys.exit(1)

    owner, repo, branch, subpath = parsed

    # Create temp directory
    tmp_dir = tempfile.mkdtemp(prefix="audit-")

    # Use archive download (safer than git clone — avoids CVE-2024-32002)
    clone_url = f"https://github.com/{owner}/{repo}.git"
    clone_dir = os.path.join(tmp_dir, repo)

    try:
        # Shallow clone with depth 1 for speed
        clone_args = ["git", "clone", "--depth", "1"]
        if branch:
            clone_args.extend(["--branch", branch])
        clone_args.extend([clone_url, clone_dir])

        proc = subprocess.run(clone_args, capture_output=True, text=True, timeout=60)
        if proc.returncode != 0:
            print(json.dumps({
                "error": f"Failed to clone {clone_url}: {proc.stderr.strip()}",
                "source": "github",
                "original_target": target,
            }))
            sys.exit(1)

    except subprocess.TimeoutExpired:
        print(json.dumps({"error": f"Timeout cloning {clone_url} (60s limit)"}))
        sys.exit(1)

    # Resolve subpath if provided
    resolved_path = clone_dir
    if subpath:
        resolved_path = os.path.join(clone_dir, subpath)
        if not os.path.exists(resolved_path):
            print(json.dumps({
                "error": f"Subpath '{subpath}' not found in {owner}/{repo}",
                "source": "github",
                "original_target": target,
                "resolved_path": clone_dir,
                "is_temporary": True,
            }))
            sys.exit(1)

    result = {
        "source": "github",
        "original_target": target,
        "owner": owner,
        "repo": repo,
        "branch": branch,
        "subpath": subpath,
        "resolved_path": resolved_path,
        "is_temporary": True,
        "temp_root": tmp_dir,
        "target_type": target_type,
    }

    if target_type == "skill":
        skill_md = os.path.join(resolved_path, "SKILL.md")
        result["has_skill_md"] = os.path.isfile(skill_md)

    print(json.dumps(result, indent=2))


def _handle_npm_package(target, target_type):
    """Download an npm package to a temp directory for inspection."""
    if not _command_exists("npm"):
        print(json.dumps({"error": "npm is not installed. Required to download npm packages."}))
        sys.exit(1)

    tmp_dir = tempfile.mkdtemp(prefix="audit-")

    try:
        # Use npm pack to download without executing any scripts
        proc = subprocess.run(
            ["npm", "pack", target, "--pack-destination", tmp_dir],
            capture_output=True, text=True, timeout=30, cwd=tmp_dir
        )
        if proc.returncode != 0:
            print(json.dumps({
                "error": f"Failed to download npm package '{target}': {proc.stderr.strip()}",
                "source": "npm",
                "original_target": target,
            }))
            sys.exit(1)

        # Find the downloaded tarball
        tarballs = [f for f in os.listdir(tmp_dir) if f.endswith(".tgz")]
        if not tarballs:
            print(json.dumps({"error": f"npm pack succeeded but no tarball found for '{target}'"}))
            sys.exit(1)

        # Extract the tarball
        tarball_path = os.path.join(tmp_dir, tarballs[0])
        extract_dir = os.path.join(tmp_dir, "package")
        subprocess.run(
            ["tar", "xzf", tarball_path, "-C", tmp_dir],
            capture_output=True, text=True, timeout=15
        )

        if not os.path.isdir(extract_dir):
            # Some packages extract to a different name
            dirs = [d for d in os.listdir(tmp_dir) if os.path.isdir(os.path.join(tmp_dir, d))]
            if dirs:
                extract_dir = os.path.join(tmp_dir, dirs[0])

    except subprocess.TimeoutExpired:
        print(json.dumps({"error": f"Timeout downloading npm package '{target}' (30s limit)"}))
        sys.exit(1)

    result = {
        "source": "npm",
        "original_target": target,
        "package_name": target,
        "resolved_path": extract_dir,
        "is_temporary": True,
        "temp_root": tmp_dir,
        "target_type": target_type,
    }

    print(json.dumps(result, indent=2))


def _parse_github_url(url):
    """Parse a GitHub URL into (owner, repo, branch, subpath).

    Supports:
      https://github.com/owner/repo
      https://github.com/owner/repo/tree/branch/sub/path
      https://github.com/owner/repo/tree/branch
    """
    # Strip trailing slash and .git
    url = url.rstrip("/")
    if url.endswith(".git"):
        url = url[:-4]

    pattern = r"https?://github\.com/([^/]+)/([^/]+)(?:/tree/([^/]+)(?:/(.+))?)?"
    match = re.match(pattern, url)
    if not match:
        return None

    owner = match.group(1)
    repo = match.group(2)
    branch = match.group(3)  # None if not in URL
    subpath = match.group(4)  # None if not in URL

    return owner, repo, branch, subpath


def _command_exists(cmd):
    """Check if a command is available on PATH."""
    try:
        subprocess.run([cmd, "--version"], capture_output=True, timeout=5)
        return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


if __name__ == "__main__":
    main()
