# PR Description Template

Use this template to structure the PR description. **Only include sections that have relevant changes** — omit empty sections entirely.

---

## Template

```markdown
## TL;DR

| Area | Files | What Changed |
|------|-------|--------------|
| {area} | `{file1}`, `{file2}` | {one-line summary of change} |

- {Brief one-liner summarizing the most important change}
- {Brief one-liner summarizing another key change}
- {Keep to 3-5 bullet points max}

---

## Features

- **{Short title}** — {What was added and why. Describe the user-facing or developer-facing behavior.}

## Bug Fixes

- **{Short title}** — {What was broken, what caused it, and how it was fixed.}

## Improvements

Group by area when there are 2+ areas. Use subheadings.

### {Area Name} (e.g., UI, API, Performance, DX)
- **{Short title}** — {What was improved and why.}

## Refactoring

- **{Short title}** — {What was restructured, from what to what, and why. No behavior change.}

## Documentation

- **{Short title}** — {What was documented or updated.}

## Tests

- **{Short title}** — {What test coverage was added or changed.}

## Dependencies

- **{Short title}** — {What was added, removed, or updated. Include version info if relevant.}

## CI/CD

- **{Short title}** — {What changed in the build/deploy pipeline.}
```

---

## Section rules

1. **TL;DR** always comes first — this is the quick-glance summary for reviewers.
2. **Features** before Bug Fixes — new capabilities take priority in description flow.
3. **Bug Fixes** before Improvements — fixes are more critical context than enhancements.
4. **Improvements** grouped by area with subheadings when there are multiple areas.
5. **Refactoring** is for structural/architectural changes with no behavior change.
6. **Documentation**, **Tests**, **Dependencies**, **CI/CD** — include only when relevant.

## Formatting rules

- Use **bold short titles** followed by an em dash (`—`) and explanation.
- Be concise but precise — a reviewer should understand the *what* and *why* without reading the code.
- If the existing PR body contains ticket/issue links, preserve them at the top under a `**Tickets:**` line.
- Never fabricate changes — only describe what is actually in the diff.
