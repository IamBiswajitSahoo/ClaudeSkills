# Step-Back Framework

**Best for:** Questions where principles or context matter before details — math, physics, policy, system design, debugging. Forces the model to recall the relevant abstraction first, which significantly improves accuracy on reasoning-heavy tasks.

## Template Structure

Rewrite the prompt into these sections:

### Specific Question
Restate the user's concrete question exactly as asked — the thing they actually want answered.

### Step-Back Question
Formulate a more general, abstract question whose answer would provide the principles, definitions, or context needed to answer the specific question. Examples:
- Specific: "What's the pressure of a gas at 100°C and 2 mol in a 5L container?"
- Step-back: "What gas law applies, and what does it state?"

### Reasoning Plan
Instruct the model to:
1. Answer the step-back question first (recall the principle)
2. Then apply that principle to the specific question
3. Show the connection between the two

### Output
Specify what the final answer should look like — just the specific answer, or both the principle and the answer.

## Rules for This Framework
- The step-back question must be genuinely more abstract — not just a rephrasing
- Good step-back questions ask about *categories*, *laws*, *definitions*, or *frameworks*
- If the original prompt is already abstract, this framework adds little value — use Chain-of-Thought instead
- Mark inferred step-back questions with [inferred] so the user can adjust
