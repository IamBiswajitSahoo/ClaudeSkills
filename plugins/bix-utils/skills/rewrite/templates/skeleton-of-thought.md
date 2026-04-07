# Skeleton-of-Thought Framework

**Best for:** Long structured outputs where latency matters — essays, reports, multi-section documentation, tutorials. Generate the outline first, then expand each point (potentially in parallel), giving faster perceived response time and more consistent structure.

## Template Structure

Rewrite the prompt into these sections:

### Topic
State exactly what the output is about. Include scope, length target, and audience.

### Skeleton First
Instruct the model to produce a **skeleton outline** before writing any prose:
1. List 3–7 top-level points as short phrases (not full sentences)
2. Each point should be a self-contained section
3. Points should be ordered logically and not overlap
4. Stop and present the skeleton — do NOT expand yet

### Expansion Rules
Specify how each skeleton point should be expanded:
- Target length per point (e.g., "1 paragraph", "3 bullets", "100 words")
- Style, tone, and voice
- Whether expansions can reference each other or must be self-contained
- Format (markdown, plain text, headings)

### Expand Each Point
Instruct the model to expand every skeleton point into the target length. Each expansion should:
1. Stand on its own as a complete section
2. Stay strictly within its skeleton point's scope (don't drift)
3. Use the format and length specified

### Final Assembly
Specify how to stitch the expansions together — with headings, transitions, intro/outro, etc.

## Rules for This Framework
- Skeleton points must be parallel in structure — avoid mixing one-word and full-sentence points
- The skeleton is non-negotiable: expansions cannot add or remove points
- Best for outputs longer than ~500 words; shorter pieces don't benefit from skeletoning
- For exploratory or single-thread reasoning, use Chain-of-Thought instead
