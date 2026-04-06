#!/usr/bin/env bash
# Sync the version in VERSION across every plugin.json and the marketplace.json.
# Single source of truth: the repo-root VERSION file.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(cat "$ROOT/VERSION" | tr -d '[:space:]')"

if [[ -z "$VERSION" ]]; then
  echo "VERSION file is empty" >&2
  exit 1
fi

echo "Syncing version $VERSION..."

python3 - "$ROOT" "$VERSION" <<'PY'
import json, sys, pathlib

root = pathlib.Path(sys.argv[1])
version = sys.argv[2]

files = sorted(root.glob("plugins/*/.claude-plugin/plugin.json"))
files.append(root / ".claude-plugin" / "marketplace.json")

for f in files:
    if not f.exists():
        continue
    data = json.loads(f.read_text())
    if isinstance(data, dict) and "plugins" in data and isinstance(data["plugins"], list):
        for p in data["plugins"]:
            p["version"] = version
    if "version" in data:
        data["version"] = version
    f.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    print(f"  {f.relative_to(root)}")
PY

echo "Done."
