#!/usr/bin/env bash
# Package every skill as a standalone zip for Agensi, one zip per skill, in dist/agensi/.
#
# Plugin agents a skill calls (`<plugin>:<group>:<name>`) are copied from
# plugins/<plugin>/agents/<group>/ into the zip's references/agents/, where the
# skill's "Standalone install" fallback reads them.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/agensi"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$OUT"
rm -f "$OUT"/*.zip

for skill_dir in "$ROOT"/plugins/*/skills/*/; do
  skill="$(basename "$skill_dir")"
  plugin="$(basename "$(dirname "$(dirname "$skill_dir")")")"

  cp -R "$skill_dir" "$STAGE/$skill"

  for group in $(grep -oE "\`$plugin:[a-z0-9-]+:" "$skill_dir/SKILL.md" | cut -d: -f2 | sort -u); do
    agents="$ROOT/plugins/$plugin/agents/$group"
    [[ -d "$agents" ]] || continue
    mkdir -p "$STAGE/$skill/references/agents"
    cp "$agents"/*.md "$STAGE/$skill/references/agents/"
  done

  (cd "$STAGE" && zip -qrX "$OUT/$skill.zip" "$skill" -x '*.DS_Store')
  echo "Packaged $skill"
done
