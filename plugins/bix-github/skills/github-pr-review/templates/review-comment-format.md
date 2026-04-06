# Review Comment Format & Technical Reference

## Determining Correct Line Numbers

**Comments must target the correct line number in the new version of the file, and that line must be visible in the PR diff.**

### How to determine the `line` value:

1. Read the diff hunk header: `@@ -oldStart,oldCount +newStart,newCount @@`
   - `newStart` is the starting line number in the new version of the file
2. Count lines from `newStart`, incrementing for every line that is NOT a deletion:
   - Context lines (` ` prefix): increment
   - Added lines (`+` prefix): increment
   - Deleted lines (`-` prefix): do NOT increment
3. The `line` value must be the line number in the **new version** (RIGHT side)
4. The line **must be visible in the diff** — GitHub rejects or misplaces comments on lines outside diff hunks

### Example:

```diff
@@ -10,6 +10,7 @@ public class Foo
 {                          // new file line 10
     private int x;         // new file line 11
+    private int y;         // new file line 12 (added)
     private int z;         // new file line 13
```

To comment on the added `private int y;` line, use `"line": 12`.

### Verification step:

After determining line numbers, read the actual file content to confirm correctness. Use `gh api repos/:owner/:repo/contents/<path>?ref=<branch>` or read the file locally.

### Multi-line suggestions:

- `start_line`: first line of the range (inclusive)
- `line`: last line of the range (inclusive)
- Both must be within the same diff hunk

---

## JSON API Reference

**Always use JSON input with `--input -` for creating reviews.**

```bash
# Step 1: Create PENDING review
cat <<'JSONEOF' | gh api repos/:owner/:repo/pulls/<PR_NUMBER>/reviews -X POST --input -
{
  "commit_id": "<COMMIT_SHA>",
  "comments": [
    {
      "path": "path/to/file.ts",
      "line": 42,
      "body": "Comment text\n\n```suggestion\n// suggested replacement\n```"
    }
  ]
}
JSONEOF

# Step 2: Submit the pending review
gh api repos/:owner/:repo/pulls/<PR_NUMBER>/reviews/<REVIEW_ID>/events \
  -X POST \
  -f event="COMMENT" \
  -f body="Optional overall review message"
```

### Comment object fields

**Required:**
- `path` (string): File path relative to repo root
- `line` (integer): Line number in new version — must be in the diff
- `body` (string): Comment text with optional suggestion block

**Optional:**
- `start_line` (integer): Start of multi-line range
- `side` (string): `"RIGHT"` (default) for new code, `"LEFT"` for deleted code

**Top-level required:**
- `commit_id` (string): Latest commit SHA from the PR
- `comments` (array): Array of comment objects

---

## Event Types

| Event | When to use | Typical situations |
|-------|------------|-------------------|
| `REQUEST_CHANGES` | Any Critical findings posted | Security vulnerabilities, bugs, data loss |
| `COMMENT` | Only Warning/Nit findings posted | Convention issues, suggestions, questions |
| `APPROVE` | Zero findings or only minor nits | PR looks good, optional style tweaks |

Auto-determination rule: if any posted comment is `[Critical]` → REQUEST_CHANGES. If only `[Warning]`/`[Nit]` → COMMENT. If zero comments → let user choose.

---

## Severity Display Format

During per-comment approval, present findings with severity labels:

```
[Critical] Comment 1 — `src/auth.ts` line 20: Missing null check on token refresh
[Warning]  Comment 2 — `src/utils.ts` line 55: Redundant database query in loop
[Nit]      Comment 3 — `src/config.ts` line 8: Consider renaming for clarity
```

Pre-existing issues (detected via git blame) get an additional tag:

```
[Warning] [Pre-existing] Comment 4 — `src/db.ts` line 30: Unvalidated SQL input
```

Pre-existing findings are shown **after** all new findings, grouped separately.

---

## Code Suggestions

Inside the JSON `body` field, use `\n` for newlines:

```json
{
  "path": "src/auth.ts",
  "line": 20,
  "body": "Explanation of the issue\n\n```suggestion\nconst fixed = \"corrected code\";\n```\n\nAdditional context."
}
```

Code suggestions replace the entire line or line range. Ensure suggested code is complete.

### Nested code blocks

When suggesting changes to markdown files containing triple backticks, use 4 backticks:

```json
{
  "body": "Fix formatting\n\n````suggestion\n```javascript\nconst x = 1;\n```\n````"
}
```

---

## Syntax Rules

**DO:**
- Use JSON input via `cat <<'JSONEOF' | gh api ... --input -`
- Use `line` as an integer (not string) in JSON
- Escape newlines as `\n` and quotes as `\"` in JSON strings
- Verify line numbers against actual diff hunks
- Always create pending reviews, even for single comments

**DON'T:**
- Use `-f 'comments[][path]=...'` flag syntax — causes 422 errors
- Use a line number not visible in the diff
- Guess line numbers without checking the diff
- Post reviews without user approval
- Skip pending review under time pressure
