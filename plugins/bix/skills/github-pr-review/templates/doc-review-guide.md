# Documentation Review Guide

As part of every PR review, check for missing or stale documentation on public API surfaces touched by the PR.

## Language Detection

The gather script provides `primary_language`. If it is `null` or not in the table below, **skip documentation review entirely** with a note: "Skipping doc review — unsupported or undetected language."

## Language Conventions

| Language | Convention | Tags/Sections to check |
|----------|-----------|----------------------|
| javascript, typescript | JSDoc (`/** ... */`) | `@param`, `@returns`, `@throws`, `@example` |
| python | Docstrings (Google, NumPy, or reST) | Args, Returns, Raises sections |
| go | godoc (comment above declaration) | Package comments, exported function/type comments |
| csharp | XML docs (`/// <summary>`) | `<summary>`, `<param>`, `<returns>`, `<exception>` |
| rust | rustdoc (`///` or `//!`) | Function docs, `# Examples`, `# Panics`, `# Errors` |
| java | Javadoc (`/** ... */`) | `@param`, `@return`, `@throws` |
| ruby | YARD (`#` comments) | `@param`, `@return`, `@raise` |
| kotlin | KDoc (`/** ... */`) | `@param`, `@return`, `@throws` |
| php | PHPDoc (`/** ... */`) | `@param`, `@return`, `@throws` |
| swift | Swift doc comments (`///`) | `- Parameter`, `- Returns`, `- Throws` |

## What to Check

For every file changed in the PR, inspect **public API surfaces only**:

1. **Public classes/structs/interfaces** — must have a summary describing purpose
2. **Public methods/functions** — must document parameters, return value, and thrown exceptions
3. **Public properties/fields** — must have a summary if their purpose isn't self-evident from the name
4. **Constructors** — must document all parameters

Do NOT flag missing docs on private/internal members unless the project consistently documents them (follow existing conventions).

## What Counts as Stale

Documentation is **stale** when:
- A method's parameters changed (added/removed/renamed) but docs were not updated
- A method's return type changed but the return description wasn't updated
- A method's behavior changed significantly but the summary still describes old behavior
- A class was refactored to a different responsibility but the doc still describes the old one

## Severity

- **Missing docs** on new public members → `Nit`
- **Stale/misleading docs** that describe wrong behavior → `Warning`

## Formatting Rules

1. **Always use `suggestion` blocks** — so the author can accept the fix with one click
2. **Use `start_line` and `line`** for multi-line suggestions that replace an existing doc block + signature
3. **Match existing style** — if the codebase uses `///` XML docs, suggest `///`. If it uses `/** */` JSDoc, suggest JSDoc. Mirror indentation and formatting
4. **Be accurate** — read the actual implementation before writing the doc. Don't guess what parameters do
5. **Documentation comments go through the same per-comment approval flow** — Post / Skip / Modify
