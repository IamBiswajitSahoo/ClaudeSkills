# /rewrite

> Also available as `/bix:rewrite`

Rewrite your prompts using proven prompt engineering frameworks. Pick a framework, and a fast sub-agent restructures your prompt into a clear, structured version optimized for LLM comprehension.

## Installation

```bash
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix@Biswajit-Claude-Skills
```

## Usage

| Command | What It Does |
| ------- | ------------ |
| `/rewrite "Build a REST API for user management"` | Rewrite the prompt using a selected framework |
| `/rewrite` | Interactive mode — prompts you to type or paste your prompt |

The skill walks you through framework selection interactively — no flags or options to memorize.

## How It Works

```
┌──────────────────────────────────────────────────────┐
│ Step 1: You provide your raw prompt                  │
│   /rewrite "your prompt here"                        │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 2: Pick a category                              │
│   Essential · Specialized · Advanced · Custom/Skip   │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 3: Pick a framework within that category        │
│   e.g. RISEN, TIDD-EC, CO-STAR, etc.                │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 4: Haiku sub-agent rewrites your prompt         │
│   Fast, cheap — pure text transformation             │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 5: Review & confirm                             │
│   Use it · Try another framework · Edit first        │
└──────────────────────────────────────────────────────┘
```

## Frameworks

The skill includes 12 curated frameworks organized into three categories.

### Essential — covers 80% of tasks

| Framework | Stands For | Best For |
| --------- | ---------- | -------- |
| **RISEN** | **R**ole, **I**nstructions, **S**teps, **E**nd goal, **N**arrowing | Structured multi-step tasks, complex implementations, detailed reports |
| **TIDD-EC** | **T**ask, **I**nstructions, **D**o, **D**on't, **E**xamples, **C**ontext | Code generation, precision tasks, anything with strict requirements |
| **CRAFT** | **C**ontext, **R**ole, **A**ction, **F**ormat, **T**one | General-purpose prompt writing, everyday tasks |
| **APE** | **A**ction, **P**urpose, **E**xpectation | Quick one-off tasks where minimal structure is sufficient |

### Specialized — audience, validation, transformation, reasoning

| Framework | Stands For | Best For |
| --------- | ---------- | -------- |
| **CO-STAR** | **C**ontext, **O**bjective, **S**tyle, **T**one, **A**udience, **R**esponse | Content creation, writing, communications — anything where audience and tone matter |
| **K.E.R.N.E.L.** | **K**eep simple, **E**asy to verify, **R**eproducible, **N**arrow scope, **E**xplicit constraints, **L**ogical structure | Meta-validation — refines any prompt by applying a quality checklist rather than imposing new structure |
| **BAB** | **B**efore, **A**fter, **B**ridge | Transformation tasks — refactoring, migration, upgrading, rewriting |
| **Chain of Thought** | Problem, Reasoning, Sub-questions, Verification, Answer | Reasoning, analysis, debugging, problem-solving — tasks where step-by-step thinking improves quality |

### Advanced — niche and creative

| Framework | Stands For | Best For |
| --------- | ---------- | -------- |
| **RACE** | **R**ole, **A**ction, **C**ontext, **E**xpectation | Fast expert-driven tasks, lighter alternative to RISEN |
| **CRISPE** | **C**apacity, **I**nsight, **S**tatement, **P**ersonality, **E**xperiment | A/B testing, generating multiple variants, creative exploration |
| **SCRIBE** | **S**pecify role, **C**ontextualize, **R**esponsibility, **I**nstructions, **B**anter, **E**valuate | Iterative conversational workflows, tasks that benefit from back-and-forth dialogue |
| **C.R.E.A.T.E.** | **C**haracter, **R**equest, **E**xamples, **A**djustments, **T**ype of output, **E**xtras | Content generation with fine control over style, format, and examples |

### Custom / Skip

You can also:
- **Provide your own template** — give a file path (`.md`, `.txt`) or paste raw template text directly
- **Skip rewriting** — pass the prompt through as-is

## Choosing a Framework

Not sure which framework to pick? Here's a quick guide:

| Your Situation | Recommended Framework |
| -------------- | --------------------- |
| Building or implementing something step-by-step | **RISEN** |
| Writing code with specific do's and don'ts | **TIDD-EC** |
| General task, just want it clearer | **CRAFT** |
| Simple ask, don't need much structure | **APE** |
| Writing for a specific audience or tone | **CO-STAR** |
| Prompt already exists, just needs polish | **K.E.R.N.E.L.** |
| Refactoring or migrating from A to B | **BAB** |
| Complex reasoning or debugging | **Chain of Thought** |

## Token Efficiency

- **Sub-agent uses Haiku** — the rewriting is a text transformation task, not deep analysis, so it uses the fastest and cheapest model available
- **No tools needed** — the sub-agent has zero tool access (pure text in, text out), minimizing overhead
- **2-step selection** — category then framework, always exactly 2 questions, no deep pagination chains

## Inspiration & References

This skill was inspired by the open-source **[Prompt Architect](https://github.com/ckelsoe/claude-skill-prompt-architect)** skill by Charles Kelsoe, which implements 27 prompt engineering frameworks with intent-based routing. We adapted the concept to the bix plugin conventions — using a haiku sub-agent for fast rewriting, a 2-step category-based selection UX, and a curated set of 12 frameworks instead of the full 27.

The frameworks themselves come from various sources in the prompt engineering community:

| Framework | Origin |
| --------- | ------ |
| RISEN | [AiPromptsX](https://aipromptsx.com/blog/risen-framework-prompt-engineering-guide), [Easy AI Beginner](https://easyaibeginner.com/risen-framework-ai-prompt-for-chatgpt/) |
| CO-STAR | Winner of Singapore's first GPT-4 Prompt Engineering competition ([Parloa](https://www.parloa.com/knowledge-hub/prompt-engineering-frameworks/)) |
| TIDD-EC | [Medium — CO-STAR and TIDD-EC](https://vivasai01.medium.com/mastering-prompt-engineering-a-guide-to-the-co-star-and-tidd-ec-frameworks-3334588cb908) |
| CRAFT | [Geeky Gadgets](https://www.geeky-gadgets.com/craft-prompt-framework/), [Monica Poling](https://monicapoling.com/the-craft-prompt-framework-for-better-ai-results/) |
| APE | [AiPromptsX — Frameworks](https://aipromptsx.com/prompts/frameworks) |
| K.E.R.N.E.L. | [CyberCorsairs](https://cybercorsairs.com/the-kernel-prompting-framework/), [Medium — KERNEL Formula](https://nurxmedov.medium.com/stop-guessing-your-ai-prompts-use-this-6-step-k-e-r-n-e-l-formula-6e0953b846e0) |
| BAB | [AiPromptsX](https://aipromptsx.com/prompts/frameworks), [Parloa](https://www.parloa.com/knowledge-hub/prompt-engineering-frameworks/) |
| Chain of Thought | [Wei et al., 2022](https://arxiv.org/abs/2201.11903) — the foundational paper on chain-of-thought prompting |
| RACE | [Parloa](https://www.parloa.com/knowledge-hub/prompt-engineering-frameworks/) |
| CRISPE | [Medium — CRISPE](https://sourcingdenis.medium.com/crispe-prompt-engineering-framework-e47eaaf83611) |
| SCRIBE | [Synaptic Labs](https://blog.synapticlabs.ai/unleash-your-chatgpts-potential-with-the-scribe-method) |
| C.R.E.A.T.E. | [AI Monks](https://medium.com/aimonks/chatgpt-power-prompts-cheatsheet-c-r-e-a-t-e-framework-for-prompting-b852b2b9b248), developed by AI consultant Dave Birss |

The initial framework research was also informed by a Reddit post on [r/PromptEngineering](https://www.reddit.com/r/PromptEngineering/comments/1nt7x7v/after_1000_hours_of_prompt_engineering_i_found/) discussing real-world framework effectiveness.

## Requirements

- No external dependencies — the skill uses only Claude Code's built-in tools and a haiku sub-agent
