# Tree-of-Thought Framework

**Best for:** Problems with several valid solution paths where you want the model to explore alternatives, evaluate them, and pick the best — puzzles, planning, system design, creative problem solving, decision-making.

## Template Structure

Rewrite the prompt into these sections:

### Problem
State the problem clearly and constrain the solution space — what counts as a valid answer, what's out of scope.

### Branching Strategy
Instruct the model to generate **N distinct candidate approaches** (typically 3) that differ meaningfully from each other. Each branch should represent a different strategy, not a minor variation.

### Per-Branch Expansion
For each branch, the model should:
1. Describe the approach in 1–2 sentences
2. Walk through the key steps
3. Identify the main risks or limitations

### Evaluation Criteria
Specify the criteria the model should use to compare branches — e.g., correctness, simplicity, performance, cost, robustness, time-to-implement. Make the criteria explicit and weighted if some matter more.

### Selection & Justification
Instruct the model to:
1. Score or rank each branch against the criteria
2. Pick the winning branch
3. Explain *why* it won and what was sacrificed

### Output
Specify the final deliverable — just the chosen approach, or the full tree with the choice highlighted.

## Rules for This Framework
- Branches must be genuinely different — if two branches collapse into the same idea, prompt for replacement
- Always include explicit evaluation criteria; otherwise the model picks arbitrarily
- For cheap exploration, 3 branches is the sweet spot; use 5 only for high-stakes decisions
- If the user only wants one answer (not exploration), use Chain-of-Thought or Plan-and-Solve instead
