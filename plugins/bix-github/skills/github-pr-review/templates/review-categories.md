# Review Categories

Evaluate every PR across these 5 categories, in order. For each category, draft review comments for any issues found. Not every category will produce comments — only flag genuine issues, not hypothetical ones.

## Severity Classification

Each finding must include a severity label:

- **Critical** — Bugs, security vulnerabilities, data loss risks, race conditions. Should block merge.
- **Warning** — Performance issues, convention violations, missing error handling, risky patterns. Should fix but not necessarily blocking.
- **Nit** — Style suggestions, minor improvements, optional refactoring, naming tweaks. Nice to fix.

When in doubt between two severities, pick the lower one. Err on the side of being helpful, not noisy.

---

## 1. Code Correctness

The most critical category. Check for:

- **Logic errors** — off-by-one mistakes, wrong operators, inverted conditions, incorrect boundary handling
- **Null/empty safety** — missing null checks on values that can be null, unguarded array/collection access
- **Data integrity** — shallow vs deep copies where mutation is possible, shared mutable state, race conditions
- **Edge cases** — what happens with zero-length inputs, empty collections, extreme values, or default/unset parameters
- **API contract violations** — does the code honour the contracts of the methods and types it calls (e.g. passing values outside documented ranges)
- **Regression risk** — could this change break existing callers or downstream behaviour

Typical severities: Critical for bugs and data integrity, Warning for edge cases and regression risk.

## 2. Project Conventions

Check that the PR follows the patterns and style already established in the codebase:

- **Naming conventions** — do new identifiers follow the project's existing naming style (casing, prefixes, suffixes)
- **Code organization** — are new members placed in the correct section/region, following the class structure conventions
- **Error handling patterns** — does the new code handle errors the same way the rest of the codebase does
- **Consistency** — are similar problems solved the same way as elsewhere in the project (e.g. reusing existing utilities instead of reimplementing)
- **Magic numbers** — are literal values given named constants, matching project conventions

Typical severities: Warning for error handling and consistency, Nit for naming and organization.

## 3. Performance Implications

Check for changes that could degrade runtime or memory performance:

- **Hot-path allocations** — unnecessary allocations in loops or frequently-called methods (e.g. LINQ in per-frame code, repeated `new` inside tight loops)
- **Algorithmic complexity** — nested loops, repeated linear scans, or brute-force approaches where better structures exist
- **Redundant computation** — values computed multiple times when they could be cached, duplicate collection traversals
- **Data structure choice** — using a `List` where a `HashSet` or `Dictionary` would be more appropriate for the access pattern
- **Large-scope impact** — changes to shared utilities or base classes that affect many call sites

Typical severities: Warning for hot-path and algorithmic issues, Nit for data structure suggestions.

## 4. Security Considerations

Check for vulnerabilities or unsafe patterns:

- **Input validation** — is external input (user data, file content, API responses) validated before use
- **Injection risks** — string concatenation into queries, commands, or paths without sanitization
- **Sensitive data exposure** — logging or serializing secrets, tokens, or PII
- **Access control** — are authorization checks in place where needed
- **Unsafe operations** — unchecked casts, unsafe pointer operations, or deserialization of untrusted data

Typical severities: Critical for injection and data exposure, Warning for missing validation and access control.

## 5. Test Coverage

Check last, as a complement to the above:

- **Are new public methods or behaviours covered by tests?** — if the PR adds new functionality, are there corresponding tests
- **Are edge cases tested?** — do tests cover boundary conditions, error paths, and not just the happy path
- **Are existing tests updated?** — if behaviour changed, were related tests updated to match
- **Test quality** — do tests assert meaningful outcomes or just that "no exception was thrown"

Typical severities: Warning for untested new public APIs, Nit for edge case and quality improvements.
