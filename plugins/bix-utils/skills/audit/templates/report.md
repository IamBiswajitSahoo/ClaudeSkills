# Audit Report Template

Use this template to format the final audit report. Replace placeholders with actual values.

---

## Security Audit Report

**Target:** {target_description}
**Date:** {date}
**Mode:** {audit_mode}

---

### Risk Score: {score}/100 — {verdict}

| Severity | Count |
|----------|-------|
| Critical | {critical_count} |
| High     | {high_count} |
| Medium   | {medium_count} |
| Low      | {low_count} |
| Info     | {info_count} |

---

### Scope Audited

| Surface | Status | Findings |
|---------|--------|----------|
| Skill/Plugin files | {skill_status} | {skill_findings} |
| MCP servers | {mcp_status} | {mcp_findings} |
| Hooks | {hooks_status} | {hooks_findings} |
| CLAUDE.md files | {claudemd_status} | {claudemd_findings} |

---

### Critical & High Findings

{critical_high_findings}

---

### Medium & Low Findings

<details>
<summary>Click to expand {medium_low_count} findings</summary>

{medium_low_findings}

</details>

---

### Informational Notes

<details>
<summary>Click to expand {info_count} notes</summary>

{info_findings}

</details>

---

### What Looks Clean

{clean_items}

---

### Recommendations

{recommendations}
