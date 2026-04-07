# Reverse-Role Framework

**Best for:** Vague requests where requirements need to be elicited before any work begins — fuzzy feature ideas, unclear specs, "I want a tool that does X but I'm not sure what". Flips the script so the model interrogates *you* before producing output.

## Template Structure

Rewrite the prompt into these sections:

### Goal
State the user's high-level goal as best as it can be inferred from the original prompt. Mark assumptions with [inferred].

### Reversed Role
Instruct the model to act as an **interviewer**, not a producer. Its job is to ask clarifying questions until it has enough information to proceed with confidence.

### Question Strategy
Tell the model:
1. Ask 3–5 questions per round (not one at a time — batch them)
2. Prioritize the questions that would change the *shape* of the answer most
3. Avoid yes/no questions — prefer open-ended or multiple-choice
4. Stop asking once it has enough information; do not pad with low-value questions

### Stopping Condition
Define when the model should stop interviewing and switch to producing:
- After N rounds of questions, OR
- When the user says "go", "that's enough", or similar, OR
- When all critical unknowns are resolved (model decides)

### Handoff
Once interviewing is complete, instruct the model to:
1. Summarize what it learned
2. Restate the now-clarified goal
3. Then produce the actual output (or hand back to the user for a fresh prompt)

## Rules for This Framework
- The model must NOT start producing the output until the interview is complete
- Questions should reveal hidden requirements, not extract trivia
- If the original prompt is already clear, this framework adds friction — use RTF or RISEN instead
- Best paired with high-stakes or open-ended tasks where misalignment is expensive
