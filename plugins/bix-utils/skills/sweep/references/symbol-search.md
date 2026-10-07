# Symbol search

Read before any usage, dead-code, rename or placement claim. Each rule exists because
ignoring it produced a wrong answer that looked right.

## Prefer the language server

Use LSP find-references when one is available. Fall back to grep only when it is not, and then
apply every rule below.

## Searches that silently miss

- **Declarations come in more shapes than you list.** `class|struct|interface|enum` misses
  `record`, `type`, `trait`, `object`, `def`, `fn`, arrow-function consts and re-exports.
- **Not every reference has an import.** Ancestor-namespace resolution, same-package access,
  globals, barrel files and wildcard imports leave no import line. Build the consumer set from
  usage, not imports.
- **Extension methods, mixins and decorators** are called without naming the declaring type.
  Search for the member name, not the type.
- **Reflection, DI and serialization** reach code by string: config keys, route tables, DI
  registrations, `nameof`, JSON keys, templates, scene or asset files. Grep non-code files too.
- **Strip comments and string literals** before counting a usage, or a comment fakes one.
- **Short or common names are unusable as bare probes** (`Id`, `Label`, `Get`). Use whole-word
  matches with a qualifying context, or hand-verify every hit.
- **A filename need not match what it declares**, and a misfiled file is invisible to a
  path-based search. Pair every path survey with a declaration search.

## Verify before concluding

- **Zero hits is a claim, not a result.** Run two controls in the same command: a name you know is
  present and one you know is absent. If the positive control fails, discard the result.
- **Print `pwd` in the same command as any ad-hoc grep.** A persisted working directory silently
  narrows a search.
- **Existence is a weak check.** To verify "X lives at P", confirm P declares X.
- **Compile scripted regexes with multiline mode** and assert any index is non-empty before using
  it; an empty index reads as "no problems found".
