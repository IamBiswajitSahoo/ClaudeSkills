#!/usr/bin/env bash
# Safety-net cleanup for load-session temp transcripts.
#
# The session-summarizer sub-agent rm's its transcript file after reading,
# and the skill rm's the file after a full-mode load. This hook is a
# belt-and-braces sweep that runs at SessionStart to remove any temp files
# left behind by an interrupted run (crash, network drop, user cancel).
#
# Removes any bix-load-session-*.md files in the system temp dir that are
# older than 1 hour. The age guard avoids racing an in-progress load.

set -u

TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"

# -mmin +60 = modified more than 60 minutes ago
find "$TMP" -maxdepth 1 -type f -name 'bix-load-session-*.md' -mmin +60 -delete 2>/dev/null || true

exit 0
