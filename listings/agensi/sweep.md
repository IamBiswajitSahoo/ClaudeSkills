# sweep: Agensi listing

## 1. Image prompt (ChatGPT, 512x512)

Flat vector app icon, 512x512 pixels, square canvas. A single bold symbol centered on a rounded-square tile with a deep indigo (#2B2D6E) to teal (#1FA2A6) diagonal gradient. Symbol in white with warm amber (#FFB547) accents, subtle long shadow, generous padding, crisp edges, readable at 64px. No text, no letters, no numbers, no logos or brand marks. The symbol is a broom sweeping a few small square code blocks off to one side, leaving one neat, tidy stack of blocks in the middle. The swept pieces and the broom bristles use the amber accent.

## 2. Skill name

**Code Change Sweep**

Slug: `sweep`

## 3. Skill summary

Checks a code change against your project's rules, cuts dead code, flags risks, and fixes only what you approve.

## 4. Full description

**What it does**
- Sweeps a code change in any language: the working tree, a path, a commit range, a module, or the whole codebase.
- Checks the change against the rules your project writes down (CLAUDE.md, AGENTS.md, rule files, CONTRIBUTING.md, linter configs).
- Finds vestigial, redundant, speculative and dead code, misplaced code and reinvented helpers.
- Flags correctness, contract drift, security, performance and test risks.
- Checks touched Markdown for stale names, change-narration and bloat.
- Reports one severity-ranked table and applies only the fixes you approve.

**Problems it solves**
- Leftover helpers and plumbing after you change an approach.
- A field or key renamed on one side only, with types and tests still green.
- Rule breaks that a quick self-review misses.
- Docs that no longer match the code.
- Review feedback about avoidable complexity.

**How it works**
1. Scope and rules: picks the scope, collects the project's rule files and test/build commands. Never reads secrets.
2. Fan out: read-only lens agents (conventions on Haiku; simplify, risk and docs on Sonnet) run in parallel. Large changes are split so no agent reads more than about 400 changed lines.
3. Verify and report: the main session re-checks every claim, drops rows without file:line and a snippet, merges duplicates, and prints one table ranked Critical, High, Medium, Low.
4. Propose and apply: a short plan and only real decisions as questions. Nothing changes until you approve. Fixes land in dependency order.
5. Finish: checks for dangling references, runs the build and tests it found, lists manual checks, leaves work uncommitted.

**Why install it**
- Free and Apache-2.0.
- No built-in style guide: it enforces your project's own rules.
- Biased toward the simpler change; fixes that add abstraction are not findings.
- Cheap by design: light models do the reading.
- Read-only until you approve.

**Requirements**
- Claude Code with the Agent tool.
- A git repository.
- Optional: an LSP server for the language (otherwise grep with controls).

## 5. The request

```
/sweep main..HEAD
```

```
Sweep my changes on this branch against main before I open the PR.
```

## 6. The result

Scope: commit range `main..HEAD` in the `orders-api` repo (7 files, about 310 changed lines). Rules read: `CLAUDE.md`, `.eslintrc.json`. Test command found: `npm test`. Four lenses ran in parallel (conventions, simplify, risk, docs). After verification, 6 findings remain and 1 candidate was dropped because it had no reproducible input.

| # | Severity | File:Line | Category | Issue | Proposed fix |
|---|---|---|---|---|---|
| 1 | 🔴 Critical | src/orders/serialize.ts:42 | Contract drift | `total_cents` was renamed to `totalCents` in the response, but `web/src/api/orders.ts:88` still reads `total_cents`. The field arrives `undefined` and the order page shows NaN. Types and unit tests stay green. | Rename the reader in `web/src/api/orders.ts:88` to `totalCents`. |
| 2 | 🔴 Critical | docs/orders.md:57 | Docs accuracy | The doc says retries are "3 attempts", but `MAX_RETRIES` in `src/orders/retry.ts:6` is 5. | Change the doc to 5. |
| 3 | 🟠 High | src/orders/helpers/misc.ts:1 | Placement | New catch-all `misc.ts` holds one function, `formatMoney`, used only by `src/orders/invoice.ts`. | Move it into `invoice.ts` and delete `misc.ts`. |
| 4 | 🟡 Medium | src/orders/retry.ts:31 | Vestigial | `withCancel(fn)` wraps a call that can no longer be cancelled since the queue was removed. One call site. | Inline the call and remove `withCancel`. |
| 5 | 🟡 Medium | src/orders/create.ts:74 | Speculative | `if (!items)` repeats the check at line 60, which already throws on empty `items`. | Delete the second check. |
| 6 | 🟢 Low | src/orders/create.ts:12, :90 | Naming | `ordMgr` and `tmpRes` are abbreviated and break the naming rule in `CLAUDE.md`. | Rename to `orderManager` and `pendingResult`. |

Plan: apply 1 and 2 first (safe, mechanical). Apply 3 to 5 in order (placement, then complexity). Apply 6 last. Nothing is left out. One question: rename 6 touches only local variables, so no wire or migration impact. Approve all?

Next steps
- Reply "yes" to apply all six fixes, or name the rows you want.
- After applying, the skill greps for dangling references to `misc.ts` and `withCancel`, runs `npm test`, and reports the real output.
- Manual check: open an order in the web app and confirm the total displays.
- The changes stay uncommitted until you ask for a commit.

## 7. Compatibility note

Built for and tested on Claude Code. It depends on the Agent tool (parallel sub-agents with a model choice), slash-command invocation and `${CLAUDE_SKILL_DIR}`. In this standalone zip the lens instructions are bundled in `references/agents/` and run as general-purpose sub-agents. Other SKILL.md agents may run parts of it, but that is not tested.

## 8. Categories, tags, use cases

- Categories: Code Quality & Review, Productivity, Technical Documentation
- Tags: code-review, refactoring, dead-code, maintainability, cleanup, pre-commit, claude-code, sub-agents, docs-accuracy, tech-debt
- Use cases:
  - Pre-commit cleanup of a non-trivial change
  - Pre-PR self review against project rules
  - Finding dead code after changing an approach
  - Catching renamed fields missed on one side
  - Checking docs touched by a change
  - Module-level tidy-up of one folder

## 9. Permissions

- Tools used:
  - Terminal / Shell: yes. Runs `git diff`, grep, and the project's build and test commands.
  - Read Files: yes. Reads changed files, rule files and docs.
  - Write Files: yes, only after you approve a fix.
  - Browser: no.
  - Network Access: no. Lens agents are told not to reach the network.
  - Environment Variables: no.
- Needs access to: None (works on the local repository).
- File scopes: the files in the chosen scope (read); `CLAUDE.md`, `AGENTS.md`, `.claude/rules/**`, `.cursor/rules/**`, `CONTRIBUTING.md`, linter and formatter configs, `package.json`, `Makefile` (read); the files you approve fixes for (write).
- Notes: The skill reads code and rules to judge a change, and runs your own build and tests at the end. Lens agents are read-only. It never reads or prints secrets such as `.env*` files or keys. Edits happen only after you approve the plan, and it does not commit unless you ask.

## 10. Known limitations

- Needs a git repository; the default scope comes from `git diff HEAD` (or the last commit if the tree is clean).
- Needs a Claude Code environment with the Agent tool for the lens agents.
- Without an LSP server it falls back to grep, which can miss references made by reflection, DI or config strings.
- Agent output is untrusted, so the main session re-verifies claims. This costs extra reading on large sweeps.
- Large changes are split by module (about 5 files or 400 changed lines per agent), so very big sweeps use more tokens.
- It has no built-in style guide. If your project writes no rules, only general checks apply.
- It does not run build or tests it cannot find, and asks you to run checks that need an editor or device.
- It reports findings and proposes fixes. It does not guarantee every defect is found.

## 11. FAQ

**Q:** How do I install it?
A: Download the zip from Agensi into your Claude Code skills folder. The full set is also available as a Claude Code plugin from https://github.com/IamBiswajitSahoo/ClaudeSkills.

**Q:** How do I run it?
A: Use `/sweep` for the working tree, `/sweep src/payments` for a path, `/sweep main..HEAD` for a commit range, `/sweep --module <dir>` for a whole module, or `/sweep --all`.

**Q:** Will it change my code without asking?
A: No. It reports a table and a plan first. It applies fixes only after you approve, and leaves the work uncommitted unless you ask.

**Q:** Can it read my secrets?
A: It is instructed never to read or print `.env*` files, keys or credentials, and every agent brief repeats the rule.

**Q:** What does it cost in tokens?
A: The main session plans and verifies. Haiku and Sonnet agents do the reading, and they return table rows only. Large changes are split by module to keep each agent small.

**Q:** Does it enforce a style guide?
A: No built-in one. It enforces the rules your project writes down, such as CLAUDE.md, AGENTS.md and linter configs. A list of shared helpers there helps it catch re-implementations.

**Q:** Why did it drop a finding I expected?
A: Rows without a file:line, an exact snippet and a demonstrable failing input are dropped. It prefers fewer, provable findings over padding.
