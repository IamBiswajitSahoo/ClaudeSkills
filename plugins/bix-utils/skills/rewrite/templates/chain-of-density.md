# Chain-of-Density Framework

**Best for:** Dense, information-rich summaries of long documents — papers, reports, transcripts, articles. Each iteration packs more entities into the same word budget, producing summaries that are short *and* high-coverage.

## Template Structure

Rewrite the prompt into these sections:

### Source
Specify the document, text, or content to be summarized. Include length and any sections to focus on or exclude.

### Length Budget
Set a fixed length for every iteration — e.g., "exactly 80 words" or "3 sentences". This budget does NOT change between iterations; only density changes.

### Iteration Plan
Instruct the model to produce **N successive summaries** (typically 5), where each iteration:
1. Identifies 1–3 important entities missing from the previous summary
2. Rewrites the summary at the same length, incorporating those new entities
3. Compresses or removes filler to make room — never grows the word count

### Entity Definition
Define what counts as an "entity" for this source — e.g., people, organizations, dates, technical terms, numerical results, key concepts. Be domain-specific.

### Output Format
Specify how to deliver the iterations:
- A numbered list (Iteration 1 → N) showing progression
- OR just the final, densest summary

## Rules for This Framework
- Word count must stay constant across iterations — enforce this strictly
- Missing entities must be *important*, not trivia — quality over quantity
- Each iteration should still read fluently — density must not break readability
- If the source is already short or simple, use a basic summary instead — this framework wastes tokens
- 5 iterations is the canonical count from the original paper; reduce to 3 for shorter sources
