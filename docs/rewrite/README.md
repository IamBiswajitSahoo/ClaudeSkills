# /bix-utils:rewrite

Rewrite your prompts using proven prompt engineering frameworks. A fast sub-agent recommends the best-fit framework for your prompt, and another sub-agent restructures it into a clear, LLM-optimized version.

## Installation

```bash
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-utils@Biswajit-Claude-Skills
```

## Usage

| Command | What It Does |
| ------- | ------------ |
| `/bix-utils:rewrite "Build a REST API for user management"` | Rewrite the prompt using a recommended framework |
| `/bix-utils:rewrite` | Interactive mode — prompts you to type or paste your prompt |

The skill walks you through framework selection interactively — no flags or options to memorize.

## How It Works

```text
┌──────────────────────────────────────────────────────┐
│ Step 1: You provide your raw prompt                  │
│   /bix-utils:rewrite "your prompt here"              │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 2: Recommender sub-agent suggests a framework   │
│   Accept · Use runner-up · Browse · Custom/Skip      │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 3 (optional): Browse 20 frameworks by category  │
│   Core · Content · Reasoning · Expert · Quick        │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 4: Haiku rewriter sub-agent transforms prompt   │
│   Fast, cheap — pure text transformation             │
└─────────────────────────┬────────────────────────────┘
                          ▼
┌──────────────────────────────────────────────────────┐
│ Step 5: Review & confirm                             │
│   Use it · Try another framework · Edit first        │
└──────────────────────────────────────────────────────┘
```

Happy path is **one question**: accept the recommendation. Browse mode costs two questions (category → framework).

## Frameworks

The skill includes 20 curated frameworks organized into five categories.

### Core Structured — general-purpose scaffolds, 80% of tasks

| Framework | Stands For | Best For |
| --------- | ---------- | -------- |
| **RISEN** | **R**ole, **I**nstructions, **S**teps, **E**nd goal, **N**arrowing | Multi-step structured work, complex implementations — safe default |
| **TIDD-EC** | **T**ask, **I**nstructions, **D**o, **D**on't, **E**xamples, **C**ontext | Code generation and precision tasks with strict do/don't rules |
| **CRAFT** | **C**ontext, **R**ole, **A**ction, **F**ormat, **T**one | General-purpose prompts where tone and format matter |
| **APE** | **A**ction, **P**urpose, **E**xpectation | Minimal 3-part scaffold for quick one-offs |

### Content & Communication — audience, validation, transformation

| Framework | Stands For | Best For |
| --------- | ---------- | -------- |
| **CO-STAR** | **C**ontext, **O**bjective, **S**tyle, **T**one, **A**udience, **R**esponse | Audience-sensitive writing — emails, pitches, posts |
| **K.E.R.N.E.L.** | **K**eep simple, **E**asy to verify, **R**eproducible, **N**arrow, **E**xplicit, **L**ogical | Meta-validation — polishing an existing prompt with a quality checklist |
| **BAB** | **B**efore, **A**fter, **B**ridge | Transformations — refactoring, migration, upgrades, rewriting |

### Reasoning — analysis, planning, iterative quality

| Framework | Origin | Best For |
| --------- | ------ | -------- |
| **Chain of Thought** | Wei et al., 2022 | Step-by-step reasoning, debugging, root-cause analysis |
| **Tree-of-Thought** | Yao et al., 2023 | Exploring multiple solution branches and picking a winner |
| **Plan-and-Solve** | Wang et al., 2023 | Produce a numbered plan, then execute it — when order matters |
| **Self-Refine** | Madaan et al., 2023 | Draft → critique → revise loop for quality-sensitive outputs |
| **Skeleton-of-Thought** | Ning et al., 2023 | Outline first, then expand — long, structured outputs |

### Expert & Creative — personas, variants, dialogue, creative

| Framework | Stands For | Best For |
| --------- | ---------- | -------- |
| **RACE** | **R**ole, **A**ction, **C**ontext, **E**xpectation | Fast expert-persona tasks — a lighter RISEN |
| **CRISPE** | **C**apacity, **I**nsight, **S**tatement, **P**ersonality, **E**xperiment | A/B testing, multiple variants, creative exploration |
| **SCRIBE** | **S**pecify, **C**ontextualize, **R**esponsibility, **I**nstructions, **B**anter, **E**valuate | Iterative, conversational, interview-style workflows |
| **C.R.E.A.T.E.** | **C**haracter, **R**equest, **E**xamples, **A**djustments, **T**ype, **E**xtras | Creative content with tight style and format control |

### Quick & Clarify — minimum scaffolds and clarifying moves

| Framework | Best For |
| --------- | -------- |
| **RTF** (Role · Task · Format) | The smallest useful scaffold — when you just need a shape |
| **Step-Back** | Abstract the underlying principle first, then apply it |
| **Chain-of-Density** | Dense, entity-rich summaries of long documents |
| **Reverse-Role** | Let the model interview *you* — great for vague requests |

### Custom / Skip

You can also:

- **Provide your own template** — give a file path (`.md`, `.txt`) or paste raw template text directly
- **Skip rewriting** — pass the prompt through as-is

## Token Efficiency

- **Haiku sub-agents** — both the recommender and the rewriter run on Haiku for speed and low cost
- **Catalog isolation** — the 20-framework catalog lives inside the recommender sub-agent, never entering the main-session context
- **1-question happy path** — accept the recommendation and you're done; browse mode is only 2 questions

## Inspiration & References

This skill was inspired by the open-source **[Prompt Architect](https://github.com/ckelsoe/claude-skill-prompt-architect)** skill by Charles Kelsoe. We adapted the concept for this marketplace — using Haiku sub-agents for recommendation and rewriting, a recommend-first UX, and a curated set of 20 frameworks spanning classic scaffolds and modern reasoning techniques.

Framework sources include [AiPromptsX](https://aipromptsx.com/prompts/frameworks), [Parloa](https://www.parloa.com/knowledge-hub/prompt-engineering-frameworks/), [Synaptic Labs](https://blog.synapticlabs.ai/unleash-your-chatgpts-potential-with-the-scribe-method), and foundational papers: [Chain of Thought (Wei et al., 2022)](https://arxiv.org/abs/2201.11903), [Tree of Thoughts (Yao et al., 2023)](https://arxiv.org/abs/2305.10601), [Plan-and-Solve (Wang et al., 2023)](https://arxiv.org/abs/2305.04091), [Self-Refine (Madaan et al., 2023)](https://arxiv.org/abs/2303.17651), and [Skeleton-of-Thought (Ning et al., 2023)](https://arxiv.org/abs/2307.15337).

## Requirements

- No external dependencies — the skill uses only Claude Code's built-in tools and Haiku sub-agents
