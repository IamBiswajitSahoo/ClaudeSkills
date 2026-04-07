# /bix-session:load-session

Load context from a previous Claude Code session into your current conversation. Browse your sessions, pick one, and choose between a compact AI summary or the full transcript.

## Installation

```bash
/plugin marketplace add IamBiswajitSahoo/ClaudeSkills
/plugin install bix-session@Biswajit-Claude-Skills
```

## Usage

| Command | What It Does |
| ------- | ------------ |
| `/bix-session:load-session` | Browse recent sessions, pick one to load |
| `/bix-session:load-session my-session` | Load a named session directly |

No flags to remember — the skill walks you through each step interactively.

### Tip: Name your sessions for easy access later

Use Claude Code's built-in `/rename` command to give your current session a memorable name:

```
/rename my-feature-research
```

You can also name a session when starting it with `claude -n "my-session-name"`. Then load it later in any session with:

```
/bix-session:load-session my-feature-research
```

If you don't name your sessions, no problem — the browse view shows the first message from each session so you can find it visually.

## Loading Modes

| Mode | How It Works | Cost |
| ---- | ------------ | ---- |
| **Compact** | Summarizes the session using an AI template, injects the summary | Uses tokens (runs `claude --resume` under the hood) |
| **Full** | Parses the raw session file, extracts the conversation as-is | Free (reads from disk) |

The skill shows you estimated token usage before loading and warns if a full transcript would consume a large portion of your context window.

## Summarization Templates

When loading in compact mode, you pick a summarization template. The skill auto-recommends one based on what's in the session, but you always choose.

| Template | What You Get | When To Use | Based On |
| -------- | ------------ | ----------- | -------- |
| **Quick** | Short paragraph — the gist | You just need a reminder of what the session was about, or the session was small | Inspired by Claude's built-in `/compact` ([docs](https://platform.claude.com/docs/en/build-with-claude/compaction)) |
| **Default** | Balanced, entity-dense summary | General purpose — you want a solid overview without picking a specific focus | Chain-of-Density prompting ([arXiv:2309.04269](https://arxiv.org/abs/2309.04269)) |
| **Decisions** | Only the decisions, trade-offs, and reasoning | You discussed architecture, design choices, or trade-offs and want to recall what was decided and why | Aspect-based summarization ([Width.ai](https://www.width.ai/post/gpt-4-dialogue-summarization)) with Chain-of-Thought ([Springer](https://link.springer.com/article/10.1007/s44443-025-00041-2)) |
| **Actions** | Files changed, commands run, what was done and why | You wrote code, edited files, or ran commands and want a changelog-style recap | Dev session recap format ([Chronicle](https://github.com/ChandlerHardy/chronicle)) |
| **Discussion** | Key questions asked, findings, and open threads | You did research, brainstorming, or Q&A and want to pick up where you left off | Extractive summarization ([CrossML](https://www.crossml.com/guide-to-llm-text-summarization/)) |
| **Timeline** | Chronological phases — what happened in what order | The session was long or multi-phase and you want to see the progression | Map-reduce summarization ([Google Cloud](https://cloud.google.com/blog/products/ai-machine-learning/long-document-summarization-with-workflows-and-gemini-models)) |
| **Handoff** | Structured briefing — goals, actions, assessment, next steps | You're resuming someone else's work, onboarding, or handing off to a colleague | SOAP-style notes ([AssemblyAI](https://www.assemblyai.com/blog/summarize-meetings-llms-python)) |
| **Custom** | Your own prompt or template file (.md, .txt) | None of the above fit — you have a specific angle in mind | — |

## Requirements

- Python 3
- Claude CLI (for compact mode)
