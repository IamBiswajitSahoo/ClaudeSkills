# RTF Framework

**Best for:** The minimum viable prompt scaffold — quick "give me X in format Y" requests where you just need to pin down who, what, and how it's delivered. Use when CO-STAR or RISEN feel like overkill.

## Template Structure

Rewrite the prompt into these sections:

### Role
State who the AI should act as — "senior backend engineer", "technical editor", "data analyst". One line. The role shapes vocabulary, depth, and assumptions.

### Task
State exactly what the AI should do in a single imperative sentence. No background, no rationale — just the action. "Write…", "Summarize…", "Generate…", "Refactor…".

### Format
Specify the exact output shape — markdown table, JSON with these keys, three bullet points, 200-word paragraph, fenced code block in language X. Be concrete; "structured" is not a format.

## Rules for This Framework
- All three sections are mandatory — RTF loses its value if any one is vague
- Keep each section to 1–2 lines; if you need more, you probably want CO-STAR or RISEN instead
- If the original prompt has no implied role, infer the most natural one and mark with [inferred]
- Format must be testable — a reader should be able to look at the output and say yes/no it matches
