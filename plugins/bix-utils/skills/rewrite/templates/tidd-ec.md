# TIDD-EC Framework

**Best for:** Precision tasks, code generation, structured data output, tasks with strict requirements and explicit guardrails.

## Template Structure

Rewrite the prompt into these sections:

### Task
Identify the specific task type and state it clearly — e.g., "Write a function", "Generate a config", "Review this code". Use a precise verb.

### Instructions
Provide detailed requirements and specifications. Include technical details, expected behavior, input/output descriptions, and any standards to follow.

### Do
List explicit behaviors, patterns, or elements to INCLUDE. These are positive instructions — things the output must contain or demonstrate.

### Don't
List explicit behaviors, patterns, or elements to AVOID. These are negative instructions — anti-patterns, common mistakes, or things that would make the output incorrect.

### Examples
If the original prompt contains or implies input/output examples, include them here. If none are provided, infer a minimal example that illustrates the expected behavior and mark it with [inferred].

### Context
Provide surrounding context — the project, codebase, system, or situation that this task exists within. Include relevant technical constraints (language, framework, environment).

## Rules for This Framework
- Do and Don't sections create strong guardrails — make them specific, not vague
- Examples are the strongest signal for output quality — include them when possible
- Task should use a single, precise action verb
