---
name: rewrite
description: Rewrite prompts using proven prompt engineering frameworks — select from 20 curated frameworks or provide a custom template, then get a structured rewrite via a fast sub-agent.
metadata:
  author: Biswajit Sahoo (https://github.com/IamBiswajitSahoo)
  license: Apache-2.0
argument-hint: '"your prompt here"'
---

# Rewrite

Rewrite a user's raw prompt into a structured version using a proven prompt engineering framework. Uses a haiku sub-agent for fast, low-cost transformation.

**Arguments:** `$ARGUMENTS` — the user's prompt text to rewrite.

---

## Phase 1: Capture Prompt

### Step 1 — Parse arguments

Extract the user's prompt from `$ARGUMENTS`:
- If `$ARGUMENTS` is not empty, use it as the original prompt → proceed to Phase 2.
- If `$ARGUMENTS` is empty, use `AskUserQuestion` to ask:
  > "What prompt would you like to rewrite?"
  - Provide no options — let the user type freely via the "Other" input.
  - Actually, use two placeholder options since AskUserQuestion requires at least 2:
    - **"I'll type my prompt"** — description: "Type your prompt in the text field below"
    - **"Paste from clipboard"** — description: "Paste your prompt in the text field below"
  - The user will type their prompt in the "Other" text field. Use whatever they provide as the original prompt.

---

## Phase 2: Select Framework

Use a 2-step category-then-framework selection flow via `AskUserQuestion`.

### Step 1 — Pick a category

Present via `AskUserQuestion`:

> "Which type of framework fits your prompt?"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **Essential (Recommended)** | RISEN, TIDD-EC, CRAFT, APE — covers 80% of tasks |
| 2 | **Specialized** | CO-STAR, K.E.R.N.E.L., BAB, Chain of Thought — audience, validation, transformation, reasoning |
| 3 | **Advanced** | RACE, CRISPE, SCRIBE, C.R.E.A.T.E. — niche and creative frameworks |
| 4 | **Reasoning** | Tree-of-Thought, Plan-and-Solve, Self-Refine, Skeleton-of-Thought — multi-step reasoning and structured generation |
| 5 | **Quick & Clarify** | RTF, Step-Back, Chain-of-Density, Reverse-Role — minimal scaffolds, abstraction, dense summaries, requirement elicitation |
| 6 | **Custom / Skip** | Provide your own template or use the prompt as-is |

### Step 2 — Pick a framework

Based on the category selected, present a second `AskUserQuestion`:

**If Essential:**
> "Select a framework:"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **RISEN (Recommended)** | Role, Instructions, Steps, End goal, Narrowing — structured multi-step tasks |
| 2 | **TIDD-EC** | Task, Instructions, Do, Don't, Examples, Context — precision and code generation |
| 3 | **CRAFT** | Context, Role, Action, Format, Tone — general purpose |
| 4 | **APE** | Action, Purpose, Expectation — quick minimal tasks |

**If Specialized:**
> "Select a framework:"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **CO-STAR** | Context, Objective, Style, Tone, Audience, Response — content and communications |
| 2 | **K.E.R.N.E.L.** | Keep simple, Easy to verify, Reproducible, Narrow, Explicit, Logical — meta-validation checklist |
| 3 | **BAB** | Before, After, Bridge — transformation and migration tasks |
| 4 | **Chain of Thought** | Step-by-step reasoning breakdown for analysis and problem-solving |

**If Advanced:**
> "Select a framework:"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **RACE** | Role, Action, Context, Expectation — fast expert-driven tasks |
| 2 | **CRISPE** | Capacity, Insight, Statement, Personality, Experiment — multiple output variants |
| 3 | **SCRIBE** | Specify role, Contextualize, Responsibility, Instructions, Banter, Evaluate — iterative dialogue |
| 4 | **C.R.E.A.T.E.** | Character, Request, Examples, Adjustments, Type of output, Extras — content with style control |

**If Reasoning:**
> "Select a framework:"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **Tree-of-Thought** | Generate multiple solution branches, evaluate against criteria, pick the winner — for problems with several valid paths |
| 2 | **Plan-and-Solve** | Devise an explicit numbered plan first, then execute and verify — for multi-step problems where order matters |
| 3 | **Self-Refine** | Draft → critique against a rubric → revise — for quality-sensitive single-shot tasks |
| 4 | **Skeleton-of-Thought** | Outline 3–7 points first, then expand each into the target length — for long structured outputs |

**If Quick & Clarify:**
> "Select a framework:"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **RTF** | Role · Task · Format — the minimum viable scaffold for quick "give me X in format Y" requests |
| 2 | **Step-Back** | Ask a more abstract question first to recall the principle, then apply it to the specific question |
| 3 | **Chain-of-Density** | Iteratively pack more entities into a fixed-length summary — for dense, high-coverage summaries |
| 4 | **Reverse-Role** | The model interviews *you* with clarifying questions before producing — for vague or open-ended requests |

**If Custom / Skip:**
> "How would you like to proceed?"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **Custom template (file)** | Provide a file path to a .md or .txt template |
| 2 | **Custom template (text)** | Paste your template text directly |
| 3 | **Skip rewriting** | Use the original prompt as-is, no rewriting |

If **Skip rewriting** is selected:
- Output the original prompt in a fenced code block
- State: "Original prompt passed through without rewriting."
- **Stop here** — do not proceed to Phase 3.

If **Custom template (file)** is selected:
- Use `AskUserQuestion` to ask: "Enter the path to your template file:"
- Read the file using:
  ```bash
  cat "{file_path}"
  ```
- Use the file contents as the template text.

If **Custom template (text)** is selected:
- Use `AskUserQuestion` to ask: "Paste your template:"
- Use the user's response as the template text.

### Step 3 — Load the framework template

For any named framework selected in Step 2, read the corresponding template file:

```bash
cat "${CLAUDE_SKILL_DIR}/templates/{framework_key}.md"
```

Where `{framework_key}` is the lowercase key mapped from the selection:

| Framework | Key |
|-----------|-----|
| RISEN | `risen` |
| TIDD-EC | `tidd-ec` |
| CRAFT | `craft` |
| APE | `ape` |
| CO-STAR | `co-star` |
| K.E.R.N.E.L. | `kernel` |
| BAB | `bab` |
| Chain of Thought | `chain-of-thought` |
| RACE | `race` |
| CRISPE | `crispe` |
| SCRIBE | `scribe` |
| C.R.E.A.T.E. | `create` |
| Tree-of-Thought | `tree-of-thought` |
| Plan-and-Solve | `plan-and-solve` |
| Self-Refine | `self-refine` |
| Skeleton-of-Thought | `skeleton-of-thought` |
| RTF | `rtf` |
| Step-Back | `step-back` |
| Chain-of-Density | `chain-of-density` |
| Reverse-Role | `reverse-role` |

Store the template text for use in Phase 3.

---

## Phase 3: Rewrite via Sub-Agent

### Step 1 — Delegate to the `prompt-rewriter` sub-agent

> **CRITICAL: You MUST delegate the rewriting to the `prompt-rewriter` sub-agent. Do NOT rewrite the prompt yourself inline.**

This plugin provides a `prompt-rewriter` sub-agent (defined in `plugins/bix-utils/agents/rewrite/rewriter.md`). Invoke it using the **Agent** tool with `subagent_type: "bix-utils:rewrite:rewriter"`.

Pass the original prompt and template as the task prompt:

```
Rewrite the following user prompt using the framework template below. Output ONLY the rewritten prompt.

---
ORIGINAL PROMPT:

{original_prompt}

---
FRAMEWORK TEMPLATE:

{template_text}
```

Set `description` to `"Rewrite prompt: {framework_name}"`.
Set `model` to `"haiku"` for fastest response.

The sub-agent's returned result is the rewritten prompt text.

### Step 2 — Present the result

Display the rewritten prompt to the user:

> **Rewritten using {framework_name}:**
>
> ```
> {rewritten_prompt}
> ```

---

## Phase 4: Confirm

### Step 1 — Ask the user how to proceed

Use `AskUserQuestion`:

> "How would you like to proceed with the rewritten prompt?"

| Option | Label | Description |
|--------|-------|-------------|
| 1 | **Use this prompt** | Proceed with the rewritten prompt — the main session will act on it |
| 2 | **Try another framework** | Go back and pick a different framework to rewrite with |
| 3 | **Edit first** | Make changes to the rewritten prompt before using it |

**If Try another framework:** Loop back to Phase 2, Step 1. Preserve the original prompt.

**If Edit first:**
- Use `AskUserQuestion` to ask: "What changes would you like to make?"
- Apply the requested edits to the rewritten prompt.
- Re-display the edited prompt and repeat Phase 4, Step 1.

**If Use this prompt:** Proceed to Phase 5.

---

## Phase 5: Handoff

### Step 1 — Output the final prompt

Output the final rewritten prompt as plain text (not in a code block) so the main session agent interprets it as the instruction to act on:

> Now executing the rewritten prompt:

Then output the rewritten prompt text verbatim.

---

## Important Rules

- **ALWAYS delegate rewriting** to the `prompt-rewriter` sub-agent via `subagent_type: "bix-utils:rewrite:rewriter"`. Never rewrite inline.
- **NEVER modify the user's intent** — the rewrite restructures and clarifies, it does not add new requirements or change the goal.
- **ALWAYS present the rewritten prompt** for user approval before acting on it.
- If the sub-agent returns an error or empty result, inform the user and suggest trying a different framework.
- The **Skip rewriting** option should simply echo the original prompt and end the skill.
- Custom templates work with both file paths and inline text.
- Keep the framework selection flow to exactly 2 questions (category → framework). Do not add extra tiers.
