# Chain of Thought Framework

**Best for:** Reasoning tasks, analysis, debugging, decision-making, problem-solving — any task where showing the reasoning process improves the output quality.

## Template Structure

Restructure the prompt to explicitly elicit step-by-step reasoning:

### Problem Statement
State the problem, question, or task clearly and completely. Include all relevant information, constraints, and context needed to reason about it.

### Reasoning Request
Add an explicit instruction to think through the problem step by step before arriving at a conclusion. Use phrases like:
- "Think through this step by step."
- "Break this down into logical steps before answering."
- "Show your reasoning process."

### Sub-Questions
If the task is complex, decompose it into logical sub-questions that, when answered in sequence, lead to the final answer. Each sub-question should build on the previous one.

### Verification
Ask the AI to verify its reasoning — check for logical errors, missed edge cases, or incorrect assumptions before presenting the final answer.

### Final Answer
Specify the desired format for the conclusion — a clear, concise answer after the reasoning is complete.

## Rules for This Framework
- The key addition is making reasoning explicit — many prompts benefit from just adding "think step by step"
- Sub-questions are optional for simple tasks — only decompose when the problem is multi-faceted
- Verification catches reasoning errors before they reach the final answer
