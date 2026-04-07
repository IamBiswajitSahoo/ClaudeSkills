# Plan-and-Solve Framework

**Best for:** Multi-step reasoning problems where the model tends to skip planning and dive straight into execution — math word problems, multi-stage code tasks, anything with intermediate state. Beats vanilla Chain-of-Thought on tasks where the *order* of steps matters.

## Template Structure

Rewrite the prompt into these sections:

### Problem
State the problem clearly. Include all data, constraints, and the exact thing being asked for.

### Plan First
Instruct the model to **devise a plan before solving**:
1. Break the problem into ordered sub-problems
2. List the sub-problems explicitly as a numbered plan
3. Note any dependencies between steps
4. Do NOT start solving yet

### Solve
Instruct the model to execute the plan:
1. Work through each sub-problem in order
2. Carry intermediate results forward
3. Reference the plan step number for each piece of work

### Verify
Instruct the model to check the final answer against the original problem:
- Does it answer the actual question?
- Are units, formats, and edge cases correct?
- If verification fails, revise and re-solve.

### Output
Specify whether to show the plan + work + answer, or just the final answer.

## Rules for This Framework
- The plan must come BEFORE any solving — enforce this explicitly in the rewrite
- Each plan step should produce a concrete intermediate result
- Skip this framework for one-step problems (it adds noise); use RTF or APE instead
- For problems with multiple valid solution paths, use Tree-of-Thought instead
