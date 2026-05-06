---
name: pre-push-review
description: >
  Review frontend code changes before a git commit or push. Use when the user says
  "review my changes before committing", "run pre-commit review", "check my staged changes",
  "review my changes before pushing", "run pre-push review", or when invoked automatically
  by the git pre-commit or pre-push hook. Covers HTML, JavaScript, TypeScript, JSX/TSX,
  Vue single-file components, and HTML ERB templates.
metadata:
  version: "0.2.0"
  supported-types: "html, js, ts, jsx, tsx, vue, erb"
---

Review frontend code changes and produce a severity-categorized report. This skill operates in two modes depending on which git hook invokes it. Read the mode carefully — it determines which diff to use, which severities to report, and what status line to emit.

## Fail-closed contract

**Reference files are mandatory.** Before applying any rules, read the relevant reference file(s) from `${CLAUDE_PLUGIN_ROOT}/skills/pre-push-review/references/`. If any required reference file cannot be read (sandbox restriction, missing file, permission error, empty content), you MUST NOT improvise rules from your own judgment.

Instead, abort the review and emit:

- In commit mode:
  ```
  Cannot load rule reference files. Review aborted to avoid false PASS.
  Reason: <specific error, e.g. "sandbox blocked read of references/js-ts-rules.md">

  COMMIT_STATUS: BLOCKED
  ```
- In push mode:
  ```
  Cannot load rule reference files. Review skipped.
  Reason: <specific error>

  REVIEW_STATUS: PASSED
  ```

A diff being "trivial" (single comment, whitespace-only, etc.) is NOT grounds to skip rule loading. Rules govern what counts as trivial — JT-B22, for example, classifies certain comment-only diffs as BLOCKING. Never let perceived triviality override the fail-closed contract.

## Mode detection

The hook script sets the environment variable `FEANOR_MODE` before invoking Claude:

- `FEANOR_MODE=commit` → **pre-commit mode**: review staged changes, report BLOCKING issues only, block the commit if found.
- `FEANOR_MODE=push` → **pre-push mode**: review unpushed commits, report WARNING and INFO only (BLOCKING already caught at commit time), never block.

If `FEANOR_MODE` is not set, default to `push` mode.

---

## pre-commit mode (`FEANOR_MODE=commit`)

### Step 1: Get staged changes

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

### Step 2: Apply BLOCKING rules only

Apply only rules marked **BLOCKING** from the corresponding reference files. Skip WARNING and INFO entirely — they are deferred to the pre-push review.

- HTML → `references/html-rules.md` (BLOCKING only)
- JS / TS → `references/js-ts-rules.md` (BLOCKING only)
- JSX / TSX → `references/js-ts-rules.md` + `references/jsx-rules.md` (BLOCKING only)
- Vue → `references/js-ts-rules.md` + `references/vue-rules.md` (BLOCKING only)
- ERB → `references/erb-rules.md` (BLOCKING only)

Apply project-specific BLOCKING rules from `.pr-review-context.md` if present.

**CRITICAL: Severity must always come from the reference file, never from your own judgment.** Every rule in the reference files has an explicit severity heading (`## BLOCKING`, `## WARNING`, `## INFO`). If a rule is listed under `## BLOCKING`, it is BLOCKING — regardless of how minor it may seem (e.g., a missing space, a quote style violation). Do not reclassify rules based on intuition.

### Step 3: Output

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

── SUMMARY ────────────────────────────────────────────────────
<1-2 sentence summary. If zero issues, say so clearly.>

COMMIT_STATUS: BLOCKED
```

Status line rules:
- Print `COMMIT_STATUS: BLOCKED` if there is at least one BLOCKING issue.
- Print `COMMIT_STATUS: PASSED` if there are none.
- If a section has zero items, omit the section header entirely.
- The status line must be the very last line of output with no trailing whitespace or blank lines.

---

## pre-push mode (`FEANOR_MODE=push`)

### Step 1: Get unpushed commits

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

If upstream exists, use `@{u}..HEAD`. If not (new branch), fall back to `HEAD~1..HEAD`.

```bash
git diff <range> -- '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb'
git diff <range> --name-only -- '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb'
```

If no frontend files changed, output:
```
No frontend files changed. Skipping review.

REVIEW_STATUS: PASSED
```
Then stop.

### Step 2: Apply WARNING and INFO rules only

Apply only rules marked **WARNING** or **INFO** from the corresponding reference files. Skip BLOCKING entirely — those were already enforced at commit time.

- HTML → `references/html-rules.md` (WARNING + INFO only)
- JS / TS → `references/js-ts-rules.md` (WARNING + INFO only)
- JSX / TSX → `references/js-ts-rules.md` + `references/jsx-rules.md` (WARNING + INFO only)
- Vue → `references/js-ts-rules.md` + `references/vue-rules.md` (WARNING + INFO only)
- ERB → `references/erb-rules.md` (WARNING + INFO only)

Apply project-specific WARNING/INFO rules from `.pr-review-context.md` if present.

**CRITICAL: Severity must always come from the reference file, never from your own judgment.** Every rule has an explicit severity heading (`## BLOCKING`, `## WARNING`, `## INFO`). A rule listed under `## WARNING` is WARNING — do not upgrade it to BLOCKING or downgrade it to INFO based on intuition. Report it exactly as classified in the reference file.

### Step 3: Output

```
╔══════════════════════════════════════════╗
║      Frontend Pre-Push Review Report     ║
╚══════════════════════════════════════════╝

  Files reviewed : <N>
  Commits        : <N> (<short commit range>)
  File types     : <list of types found>

── WARNINGS (<N>) ─────────────────────────────────────────────
⚠️   <path/to/file.ext>:<line>
    <Description>
    → Fix: <Remediation>

── INFO (<N>) ─────────────────────────────────────────────────
ℹ️   <path/to/file.ext>:<line>
    <Description>

── SUMMARY ────────────────────────────────────────────────────
<1-3 sentence summary. Note if zero issues found. Remind the
developer these are non-blocking suggestions.>

REVIEW_STATUS: PASSED
```

Status line rules:
- Always print `REVIEW_STATUS: PASSED` — the pre-push report never blocks.
- If a section has zero items, omit the section header entirely.
- The status line must be the very last line of output with no trailing whitespace or blank lines.

---

## Shared rules

**Skip entirely (both modes):** `*.min.js`, `dist/`, `build/`, `node_modules/`, `*.lock`, `*.snap`, auto-generated files (`// @generated` or `// This file is auto-generated` headers).

**Test files** (`*.spec.*`, `*.test.*`, `__tests__/`, `spec/`): apply BLOCKING rules in commit mode, skip entirely in push mode.

**File type mapping:**

| Type | Extensions |
|------|-----------|
| HTML | `.html` (non-ERB) |
| JavaScript | `.js`, `.mjs`, `.cjs` |
| TypeScript | `.ts` (non-JSX) |
| JSX / React | `.jsx`, `.tsx` |
| Vue SFC | `.vue` |
| ERB Template | `.html.erb`, `.erb` |