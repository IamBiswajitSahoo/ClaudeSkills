# Self-Refine Framework

**Best for:** Quality-sensitive single-shot tasks where one revision cycle dramatically improves output — writing, code, code review, summaries, proposals, anything where "first draft" isn't good enough.

## Template Structure

Rewrite the prompt into these sections:

### Task
State exactly what to produce. Be specific about deliverable, length, and format.

### Initial Draft
Instruct the model to produce a first version of the output. Do not optimize — just generate.

### Critique Criteria
Specify the rubric the model should use to critique its own draft. Make the criteria concrete and checkable. Examples:
- For writing: clarity, concision, tone consistency, audience fit, no jargon
- For code: correctness, edge cases, naming, error handling, idioms of the language
- For summaries: faithfulness, coverage, no hallucinations, no padding

### Self-Critique
Instruct the model to:
1. Review its own draft against each criterion
2. List concrete issues (not vague impressions)
3. For each issue, note what specifically should change

### Revise
Instruct the model to produce a revised version that addresses every issue raised in the critique. The revision should be a full rewrite, not a patch.

### Output
Specify whether to show the draft + critique + revision, or just the final revised output.

## Rules for This Framework
- The critique must be specific — "could be clearer" is not actionable
- One refinement cycle is usually enough; more than 2 hits diminishing returns
- If the critique finds nothing wrong, the model must say so explicitly (don't manufacture issues)
- For tasks where exploration matters more than polish, use Tree-of-Thought instead
