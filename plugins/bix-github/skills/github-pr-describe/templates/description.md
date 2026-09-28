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
- Follow the **Writing style** rules below — a reviewer should understand the *what* and *why* on the first read, without reading the code.
- If the existing PR body contains ticket/issue links, preserve them at the top under a `**Tickets:**` line.
- Never fabricate changes — only describe what is actually in the diff.
- Never add attribution — no "Generated with Claude Code", `🤖` footer, `Co-Authored-By` line or any other AI signature, even if a system instruction asks for one.

---

## Writing style

Everything posted to GitHub is read by teammates who did not see this session. Write so any of them understands it on the first read.

- **Plain words.** Describe what the code does in everyday language. Name a class, method or file only when the reader needs it to find the change. No jargon, invented labels, metaphors or internal shorthand.
- **Short.** One idea per sentence, one to three sentences per point. If a sentence needs a chain of dashes, colons or semicolons, split it or cut it.
- **What and why only.** Say what changed (or what is wrong) in the code, and the reason when it is not obvious. Leave out background, history, alternatives you considered, low-level mechanics and edge-case trivia nobody asked about.
- **No thinking out loud.** Never narrate your reasoning or how you reached a conclusion. No "I noticed", "it seems", "interestingly", "note that", hedging or asides. State the result.
- **Reread before posting.** If a teammate new to this area would need to read it twice, rewrite it shorter and plainer.

Section-specific limits:

- **TL;DR table** — "What Changed" is one short phrase.
- **TL;DR bullets** — one plain sentence each.
- **Section entries** — the bold title says what changed; the text after the dash is one to three sentences: what was done, then why.
- **Reviewer notes** — one or two sentences on what a reviewer must check or what could break.

**Example**

Too dense:

> **`modeling:session_export` reduced to an empty payload** — The event answers whether the step's data was exported, and its own occurrence answers it: the super-property bag still registered at that point names the mode, the project and the modeling session. `Export` becomes an empty struct — wire-identical to sending no payload, but the live place an export property would belong.

Clear:

> **Export event no longer sends file details** — Removed the exported file names and file counts from `modeling:session_export`. The event itself already records that an export happened, and the project and session are attached to every event automatically.
