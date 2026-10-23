# rewrite: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is a loose, tangled scribble on the left that flows through a small amber arrow into a neat white outline of a structured card made of stacked, evenly spaced bars on the right, showing messy text becoming an organized prompt.

## 2. Skill name

Prompt Rewriter with Frameworks

Slug: `rewrite`

## 3. Skill summary

Rewrite a rough prompt into a structured one using one of 20 prompt engineering frameworks.

## 4. Full description

**What it does**
- Takes your raw prompt and rewrites it using a prompt engineering framework.
- Recommends the best-fit framework from a catalog of 20, with a runner-up and a one-sentence reason for each.
- Lets you browse the 20 frameworks by category, or use your own template (file or pasted text).
- Shows the rewrite for approval, then hands it to the main session to act on.

**Problems it solves**
- Vague or half-formed prompts that give inconsistent results.
- Not knowing which framework (RISEN, TIDD-EC, CO-STAR, Chain of Thought and others) suits the task.
- Rewrites that ignore what you were already working on.
- Long framework catalogs filling up your main session context.

**How it works**
1. Capture your prompt (from the argument, or by asking) and write a short summary of the current conversation.
2. A Haiku sub-agent recommends a primary framework and a runner-up. You accept one, browse all 20 by category, or choose custom/skip.
3. The skill loads the matching template file.
4. A second Haiku sub-agent rewrites the prompt into the framework's sections. Anything it had to guess is tagged `[inferred]`.
5. You choose: use it, try another framework, or edit it first.
6. The approved prompt is handed to the main session as instructions.

**Why install it**
- Free and open source (Apache-2.0).
- Happy path is one question: accept the recommendation.
- The catalog and rewrite work stay in cheap sub-agents, not your main context.
- Intent is preserved: it restructures, it does not add requirements.

**Requirements**
- Claude Code with the Agent tool and AskUserQuestion.
- No scripts, no external services, no extra dependencies.

## 5. The request

```
/rewrite "Write a script that renames all the photos in a folder by date"
```

Or in plain language: "Rewrite this prompt for me with a good framework: write a script that renames all the photos in a folder by date."

## 6. The result

Summary: the skill read the prompt and the session context (a Python utility project, Python 3.11, no third-party packages). The recommender suggested TIDD-EC and offered Chain of Thought as the runner-up. You accepted the recommendation, and the rewriter produced the prompt below. Items tagged `[inferred]` were not in your original text, so check them.

Question shown to you:

> Based on your prompt, I recommend **TIDD-EC**. How would you like to proceed?
> 1. **Use TIDD-EC (recommended)**: The prompt asks for a script with specific naming behavior, which suits precise do/don't rules.
> 2. **Use Chain of Thought instead**: Better if you want the model to reason through edge cases such as missing dates before coding.
> 3. **Browse all frameworks**
> 4. **Custom / Skip**

Rewritten using TIDD-EC:

```
Task
Write a Python script that renames every photo in a folder based on its date.

Instructions
Accept a folder path as a command-line argument. For each image file in the folder, read the date the photo was taken and rename the file to YYYY-MM-DD_HHMMSS.ext. Print each old name and new name. [inferred] Use the file modification time when no capture date is stored in the file.

Do
- Support common photo extensions (.jpg, .jpeg, .png). [inferred]
- Handle two photos with the same timestamp by adding a numeric suffix.
- Offer a dry-run flag that prints changes without renaming. [inferred]

Don't
- Do not overwrite existing files.
- Do not rename files that are not images.
- Do not recurse into subfolders. [inferred]

Examples
IMG_4021.jpg (taken 2024-06-03 14:22:09) becomes 2024-06-03_142209.jpg. [inferred]

Context
Part of a Python 3.11 utility project that uses only the standard library.
```

Then you were asked: Use this prompt / Try another framework / Edit first. You chose "Use this prompt", and the skill output:

Now executing the rewritten prompt:

(the prompt above, verbatim, which the main session then acts on)

Next steps
- Check each `[inferred]` line and edit anything that is wrong.
- Choose "Try another framework" to compare, for example, Plan-and-Solve.
- Choose "Edit first" to request changes before the prompt is run.

## 7. Compatibility note

Built for and tested on Claude Code. It depends on the Agent tool (Haiku sub-agents), AskUserQuestion for the menus, `${CLAUDE_SKILL_DIR}` to find its template files, and slash-command invocation. The zip bundles the agent instructions in `references/agents/` so it runs without the plugin. Other SKILL.md agents may run parts of it but are not tested.

## 8. Categories, tags, use cases

- Categories: Prompt & Skill Engineering, Writing & Content, Productivity
- Tags: prompt-engineering, prompt-rewrite, prompt-frameworks, risen, tidd-ec, co-star, chain-of-thought, haiku, sub-agents
- Use cases:
  - Turning a rough idea into a clear prompt
  - Choosing a prompt framework for a task
  - Structuring prompts for code generation
  - Writing audience-aware emails and posts
  - Polishing an existing prompt before reuse

## 9. Permissions

- Tools used:
  - Terminal / Shell: Yes, only to read a custom template file you point to (with `cat`).
  - Read Files: Yes, reads its bundled framework templates and agent instructions, and a custom template if you give one.
  - Write Files: No. The skill writes nothing to disk.
  - Browser: No.
  - Network Access: No.
  - Environment Variables: No (uses `${CLAUDE_SKILL_DIR}` to locate its own files).
- Needs access to: None.
- File scopes: `${CLAUDE_SKILL_DIR}/templates/*.md`, `${CLAUDE_SKILL_DIR}/references/agents/*.md`, and an optional custom template path you provide.
- Notes: The skill only reads its own template files and, if you choose, one template file you name. It sends your prompt and a short conversation summary to sub-agents inside your Claude Code session. It does not edit files, run project commands or contact outside services. The rewritten prompt is only run after you approve it.

## 10. Known limitations

- Built for Claude Code. It needs the Agent tool and AskUserQuestion, so it is not tested elsewhere.
- Both the recommendation and the rewrite require sub-agents. If a sub-agent errors or returns nothing, the skill tells you and offers another framework.
- If the recommender's reply cannot be parsed or names an unknown framework, the skill falls back to browsing the catalog.
- The catalog is fixed at 20 frameworks. Anything else needs a custom template.
- The conversation summary is capped at about 150 words, so long sessions are only roughly captured.
- Rewrites restructure your prompt. They do not add goals, and guessed details are tagged `[inferred]` for you to verify.
- Quality depends on the Haiku model used for rewriting. Review the result before using it.
- "Skip rewriting" echoes the original prompt and ends the skill.

## 11. FAQ

**Q:** How do I install it?
A: Download the zip from Agensi and add it to your Claude Code skills folder, or install the full set as a Claude Code plugin from https://github.com/IamBiswajitSahoo/ClaudeSkills. Then run `/rewrite "your prompt"`.

**Q:** What do I need?
A: Claude Code. There are no scripts, packages or external accounts to set up.

**Q:** Will it change my files or run my prompt without asking?
A: No. It writes no files. It shows the rewrite and asks whether to use it, try another framework or edit first. Only after you pick "Use this prompt" does the main session act on it.

**Q:** How much will it cost in tokens?
A: The catalog and rewrite work run in Haiku sub-agents, so the 20-framework catalog does not enter your main context. The happy path is one question. Browse mode is two.

**Q:** Can I use my own template?
A: Yes. Choose Custom / Skip, then give a path to a .md or .txt file, or paste the template text.

**Q:** Where did the idea come from?
A: It was inspired by the open-source Prompt Architect skill by Charles Kelsoe (https://github.com/ckelsoe/claude-skill-prompt-architect). This version uses Haiku sub-agents, a recommend-first flow and a curated set of 20 frameworks.

**Q:** What if I do not pass a prompt?
A: The skill asks you for it, then continues the same way.
