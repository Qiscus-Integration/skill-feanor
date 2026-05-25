---
name: pre-commit-review
description: >
  Review frontend code changes at commit time, or audit a single file on demand. Use when the user says
  "review my changes before committing", "run pre-commit review", "check my staged changes",
  "run feanor review", "feanor review <path>", or when invoked automatically by the git pre-commit hook.
  Covers HTML, JavaScript, TypeScript, JSX/TSX, Vue single-file components, and HTML ERB templates.
metadata:
  version: "0.6.2"
  supported-types: "html, js, ts, jsx, tsx, vue, erb"
---

Review frontend code and produce a severity-categorized report. Two modes:

- **Hook mode (default)** — invoked by the git pre-commit hook with no file argument. Reviews staged diff. BLOCKING issues abort the commit; WARNING and INFO are reported but do not block.
- **File mode** — invoked when the user names a specific path (e.g. "feanor review src/foo.tsx"). Reviews the full file content top-to-bottom. Advisory only — no `COMMIT_STATUS` line.

## Fail-closed contract

**Reference files are mandatory.** Before applying any rules, read the relevant reference file(s) from `${CLAUDE_PLUGIN_ROOT}/skills/pre-commit-review/references/`. If any required reference file cannot be read (sandbox restriction, missing file, permission error, empty content), you MUST NOT improvise rules from your own judgment.

Instead, abort the review and emit:

```
Cannot load rule reference files. Review aborted to avoid false PASS.
Reason: <specific error, e.g. "sandbox blocked read of references/js-ts-rules.md">

COMMIT_STATUS: BLOCKED
```

A diff being "trivial" (single comment, whitespace-only, etc.) is NOT grounds to skip rule loading. Rules govern what counts as trivial — JT-B22, for example, classifies certain comment-only diffs as BLOCKING. Never let perceived triviality override the fail-closed contract.

---

## Step 1: Determine mode and collect content

**File mode** — if the user named one or more file paths (e.g. "feanor review src/foo.tsx"):

1. Resolve each path relative to the repo root. If a path does not exist or is not a supported type (see file-type mapping below), report it and skip.
2. Read the full content of each file with the `Read` tool. Skip files matched by the **Skip entirely** list in the Shared rules section.
3. Proceed to Step 2 with the full file content as the review target. **Do not** run `git diff`.

**Hook mode** — no file path given:

```bash
git diff --cached -- '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb'
git diff --cached --name-only -- '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb'
```

If no frontend files are staged, output:
```
No frontend files staged. Skipping review.

COMMIT_STATUS: PASSED
```
Then stop.

## Step 2: Apply all rules (BLOCKING + WARNING + INFO)

Apply every rule from the corresponding reference files, regardless of severity:

- HTML → `references/html-rules.md`
- JS / TS → `references/js-ts-rules.md`
- JSX / TSX → `references/js-ts-rules.md` + `references/jsx-rules.md`
- Vue → `references/js-ts-rules.md` + `references/vue-rules.md`
- ERB → `references/erb-rules.md`

Apply project-specific rules from `.pr-review-context.md` if present.

**CRITICAL: Severity must always come from the reference file, never from your own judgment.** Every rule has an explicit severity heading (`## BLOCKING`, `## WARNING`, `## INFO`). Report each finding under exactly the severity its rule was classified with. Do not upgrade, downgrade, or reclassify based on intuition.

## Step 3: Output

**Hook mode**:

```
╔══════════════════════════════════════════╗
║     Frontend Pre-Commit Review Report    ║
╚══════════════════════════════════════════╝

  Files staged  : <N>
  File types    : <list of types found>

── BLOCKING ISSUES (<N>) ──────────────────────────────────────
❌  <path/to/file.ext>:<line>
    <Clear description of the issue and why it matters>
    → Fix: <Specific, actionable remediation>

── WARNINGS (<N>) ─────────────────────────────────────────────
⚠️   <path/to/file.ext>:<line>
    <Description>
    → Fix: <Remediation>

── INFO (<N>) ─────────────────────────────────────────────────
ℹ️   <path/to/file.ext>:<line>
    <Description>

── SUMMARY ────────────────────────────────────────────────────
<1-3 sentence summary. State whether commit is blocked. Note that
WARNING and INFO are non-blocking suggestions.>

COMMIT_STATUS: BLOCKED
```

Status line rules (hook mode only):
- Print `COMMIT_STATUS: BLOCKED` if there is at least one BLOCKING issue.
- Print `COMMIT_STATUS: PASSED` if there are zero BLOCKING issues (WARNING and INFO do not block).
- If a section has zero items, omit the section header entirely.
- The status line must be the very last line of output with no trailing whitespace or blank lines.

**File mode**:

Use the same header, sections, and severity formatting, but:
- Replace the `Files staged` line with `Files reviewed`.
- Replace the report title with `Frontend File Review Report`.
- Omit the `COMMIT_STATUS` line entirely — file mode is advisory.
- The SUMMARY should describe the findings without referring to commits.

---

## Shared rules

**Skip entirely:** `*.min.js`, `dist/`, `build/`, `node_modules/`, `*.lock`, `*.snap`, auto-generated files (`// @generated` or `// This file is auto-generated` headers).

**Test files** (`*.spec.*`, `*.test.*`, `__tests__/`, `spec/`): apply BLOCKING rules only. Skip WARNING and INFO to avoid noise on test-specific patterns.

**File type mapping:**

| Type | Extensions |
|------|-----------|
| HTML | `.html` (non-ERB) |
| JavaScript | `.js`, `.mjs`, `.cjs` |
| TypeScript | `.ts` (non-JSX) |
| JSX / React | `.jsx`, `.tsx` |
| Vue SFC | `.vue` |
| ERB Template | `.html.erb`, `.erb` |
