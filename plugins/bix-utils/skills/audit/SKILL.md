---
name: audit
description: Security audit for Claude Code skills, MCP servers, hooks, and CLAUDE.md files — runs fast pattern scan then parallel deep-analysis agents.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: "<mode> [target]  — modes: skill <path|url>, mcp [server|package], hooks, claudemd, all"
---

# Security Audit

Audit Claude Code extension surfaces for security risks: skills, MCP servers, hooks, and CLAUDE.md files.

**Arguments:** `$ARGUMENTS` — the audit mode and optional target.

**Modes:**
- `skill <path|url>` — audit a skill from a local path, GitHub URL, or GitHub subdirectory URL
- `mcp [server-name|package]` — audit configured MCP servers, or fetch a specific npm package / GitHub URL to audit
- `hooks` — audit hooks in settings.json
- `claudemd` — audit CLAUDE.md files for prompt injection
- `all` — run all audits on the current environment

**Target formats (skill and mcp modes):**
- Local path: `./path/to/skill` or `/absolute/path`
- GitHub repo: `https://github.com/user/repo`
- GitHub subdirectory: `https://github.com/user/repo/tree/main/skills/my-skill`
- npm package (mcp only): `@scope/package-name`

---

## Phase 1: Parse & Route

### Step 1 — Check prerequisites

Before anything else, verify Python 3 is available:

```bash
python3 --version 2>/dev/null || python --version 2>/dev/null
```

If neither command succeeds, stop and display:

> **Python 3 is required but was not found on your system.**
>
> Install Python 3 to use this skill:
> - **macOS:** `brew install python3` or download from https://www.python.org/downloads/
> - **Linux:** `sudo apt install python3` or `sudo dnf install python3`
> - **Windows:** Download from https://www.python.org/downloads/ (check "Add to PATH" during install)
> - **WSL:** `sudo apt install python3`

If the version is Python 2.x (not 3.x), show the same message — Python 3 is required.

Store the working python command (`python3` or `python`) for use in later phases.

### Step 2 — Parse arguments

Extract the mode and target from `$ARGUMENTS`:
- If `$ARGUMENTS` starts with `skill`, extract the target (second argument — can be a local path, GitHub URL, or GitHub subdirectory URL). If no target given, use `AskUserQuestion`:
  > "What skill would you like to audit? You can provide:"
  > - A **local path** — `./path/to/skill`
  > - A **GitHub URL** — `https://github.com/user/repo`
  > - A **GitHub subdirectory** — `https://github.com/user/repo/tree/main/skills/my-skill`
- If `$ARGUMENTS` starts with `mcp`, the optional second argument can be:
  - A configured server name (audits local config)
  - A GitHub URL (downloads and audits the MCP server source)
  - An npm package name like `@scope/package` (downloads and audits the package)
  - Empty (audits all configured MCP servers)
- If `$ARGUMENTS` is `hooks`, `claudemd`, or `all`, no extra arguments needed.
- If `$ARGUMENTS` is empty or unrecognized, use `AskUserQuestion` to present the modes:
  > "What would you like to audit?"
  > - **skill** — Audit a skill (local path or GitHub URL)
  > - **mcp** — Audit MCP servers (configured, or fetch by URL/package name)
  > - **hooks** — Audit hooks in settings.json
  > - **claudemd** — Audit CLAUDE.md files
  > - **all** — Run all audits on current environment

### Step 3 — Resolve target

For `skill` and `mcp` modes where a target is provided, resolve it to a local directory:

```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/resolve-target.py" "<target>" --type <skill|mcp>
```

The script outputs JSON with:
- `source` — `local`, `github`, or `npm`
- `resolved_path` — the local directory to audit
- `is_temporary` — whether the directory was downloaded (should be cleaned up after audit)
- `temp_root` — the temp directory to clean up (only if `is_temporary` is true)
- `error` — if resolution failed, display this to the user and stop

If the source is `github` or `npm`, inform the user: "Downloaded {source} target to temporary directory for auditing."

For `mcp` mode without a target: verify MCP config files exist by running the gather script. If no servers found, report "No MCP servers configured" and stop.

For `hooks` mode: no resolution needed — the gather script reads settings files directly.

**Cleanup reminder:** If `is_temporary` is true, the temp directory at `temp_root` should be cleaned up after the audit completes. Note this for Phase 4.

---

## Phase 2: Quick Scan (Fast, Low-Token)

This phase runs fast bash-based scripts to get an immediate overview. Results determine whether deep analysis is needed and which sub-agents to spawn.

### Step 1 — Run inventory and pattern scan

Based on the mode, run the appropriate gather scripts and the pattern scanner. Run them in parallel where possible using multiple Bash calls.

**For `skill` mode:**
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/gather-skill-inventory.py" "<target-path>"
```
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/pattern-scan.py" "<target-path>" --type skill
```

**For `mcp` mode:**
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/gather-mcp-config.py" "<server-name-or-empty>"
```
Then run pattern scan on each MCP server's source if it references local files.

**For `hooks` mode:**
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/gather-hooks-config.py"
```
Then run pattern scan on any referenced script files.

**For `claudemd` mode:**
Run pattern scan targeting CLAUDE.md files:
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/pattern-scan.py" "./CLAUDE.md" --type skill
```
Also scan `.claude/CLAUDE.md` if it exists.

**For `all` mode:**
Run all four gather scripts in parallel (4 Bash calls simultaneously):
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/gather-hooks-config.py"
```
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/gather-mcp-config.py"
```
```bash
{PYTHON_CMD} "${CLAUDE_SKILL_DIR}/scripts/pattern-scan.py" "." --type plugin
```

### Step 2 — Present quick scan summary

Display a brief summary to the user:

```
## Quick Scan Results

Risk Score: {score}/100 — {verdict}
Files scanned: {files_scanned}
Pattern matches: {critical} critical, {high} high, {medium} medium, {low} low

{If verdict is SAFE: "No suspicious patterns detected."}
{If verdict is CAUTION+: list top 3 findings by severity}
```

### Step 3 — Decide next steps

Use `AskUserQuestion`:

**If verdict is SAFE (score 0-20):**
> "Quick scan found no suspicious patterns. Would you like to run a deep analysis anyway?"
> - **Deep scan** — Run parallel agents for thorough semantic analysis
> - **Done** — Accept quick scan results

**If verdict is CAUTION or higher (score 21+):**
> "Quick scan flagged {N} findings. Recommend deep analysis to verify."
> - **Deep scan** — Run parallel agents to analyze flagged areas (recommended)
> - **Show findings** — View quick scan details without deep analysis
> - **Done** — Stop here

If the user selects **Done**, skip to Phase 4 (Report) using only quick scan results.
If the user selects **Show findings**, display all pattern scan findings grouped by severity, then stop.

---

## Phase 3: Deep Analysis (Parallel Sub-Agents)

Launch focused sub-agents in parallel based on the audit mode. Each agent receives its template instructions, the quick scan results, and the gathered inventory data.

### Step 1 — Prepare agent prompts

Read the relevant agent template files from `${CLAUDE_SKILL_DIR}/templates/`:

- `skill` mode → read `agent-skill-audit.md`
- `mcp` mode → read `agent-mcp-audit.md`
- `hooks` mode → read `agent-hooks-audit.md`
- `claudemd` mode → read `agent-claudemd-audit.md`
- `all` mode → read ALL four templates

### Step 2 — Launch parallel agents

Launch `Agent` calls in parallel — one per audit surface. Each agent receives:
1. The template instructions (from the file read in Step 1)
2. The quick scan JSON results relevant to its scope
3. The inventory/config JSON from Phase 2
4. The target path or working directory

**For `skill` mode** — launch 1 agent:
- Skill audit agent with skill inventory + pattern scan results

**For `mcp` mode** — launch 1 agent:
- MCP audit agent with MCP config data

**For `hooks` mode** — launch 1 agent:
- Hooks audit agent with hooks config data

**For `claudemd` mode** — launch 1 agent:
- CLAUDE.md audit agent with pattern scan results for CLAUDE.md files

**For `all` mode** — launch up to 4 agents in parallel:
- Hooks audit agent
- MCP audit agent
- CLAUDE.md audit agent
- Pattern-based findings analysis agent (if any skill/plugin paths provided)

Each agent call should include the model parameter `"model": "sonnet"` to optimize for speed and cost. Use the `description` parameter to label each agent clearly (e.g., "MCP server security audit", "Hooks security audit").

### Step 3 — Collect results

Wait for all agents to complete. Collect their structured findings. Merge findings from all agents into a unified list, sorted by severity (Critical > High > Medium > Low > Info).

If any agent fails or times out, note it in the report and continue with available results.

---

## Phase 4: Report

### Step 1 — Calculate final score

Combine the quick scan risk score with deep analysis findings:
- Start with the pattern scan risk score
- Add weight for any NEW findings from deep analysis not already in the pattern scan
- Cap at 100

Re-evaluate the verdict based on the combined score:
- 0-20: **SAFE** — No significant security concerns
- 21-40: **CAUTION** — Minor concerns, proceed with awareness
- 41-60: **SUSPICIOUS** — Multiple red flags, manual review recommended
- 61-80: **DANGEROUS** — Serious concerns, do NOT install/use without expert review
- 81-100: **MALICIOUS** — Strong indicators of malicious intent, AVOID

### Step 2 — Build the report

Load `${CLAUDE_SKILL_DIR}/templates/report.md` for the report structure. Fill in all sections:

1. **Header** — target, date, mode, risk score, verdict
2. **Scope audited** — which surfaces were checked and their status
3. **Critical & High findings** — always shown in full
4. **Medium & Low findings** — in a collapsed details block
5. **Informational notes** — in a collapsed details block
6. **What looks clean** — positive signals (proper frontmatter, no binaries, etc.)
7. **Recommendations** — prioritized action items

### Step 3 — Present report

Display the complete report to the user. If the verdict is DANGEROUS or MALICIOUS, add a clear warning banner at the top:

```
> **WARNING:** This audit found serious security concerns. Do NOT install or use this {skill/plugin/config} without careful manual review of each finding.
```

If the source was a GitHub URL or npm package, include the original URL in the report header so the user knows exactly what was audited.

### Step 4 — Cleanup

If the target was downloaded (i.e., `is_temporary` is true from Phase 1 Step 3), clean up the temporary directory:

```bash
rm -rf "<temp_root>"
```

---

## Important Rules

- **Never auto-remediate** — this is an audit tool, not a fixer. Report findings; don't modify files.
- **Never fabricate findings** — only report patterns and behaviors actually observed in the target.
- **Always show the quick scan first** — the user should see immediate results before waiting for deep analysis.
- **Always use parallel agents** — never run deep analysis sequentially when multiple surfaces are being audited.
- **Always use sonnet model for sub-agents** — deep analysis agents should use `"model": "sonnet"` to reduce cost and latency.
- **Always present findings by severity** — Critical first, Info last.
- **Never expand scope silently** — if auditing a skill, don't scan the whole filesystem. Stick to the target.
- **Always respect user choice** — if the user says "Done" after quick scan, stop. Don't push for deep analysis.
- **Context matters** — a deployment skill needing Bash access is normal; a text formatting skill needing Bash is suspicious. Assess purpose vs. permissions.
