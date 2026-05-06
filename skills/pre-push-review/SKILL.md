---
name: pre-push-review
description: >
  Review frontend code changes before a git push. Use when the user says "review my
  changes before pushing", "run pre-push review", "check my frontend code", or when
  invoked automatically by the git pre-push hook. Covers HTML, JavaScript, TypeScript,
  JSX/TSX, Vue single-file components, and HTML ERB templates.
metadata:
  version: "0.1.0"
  supported-types: "html, js, ts, jsx, tsx, vue, erb"
---

Review all frontend code changes in the current branch that have not yet been pushed. Apply file-type-specific rules, produce a severity-categorized report, and emit a machine-readable status line so the git hook can decide whether to block the push.

## Step 1: Resolve the diff range

Run the following to determine what commits are about to be pushed:

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

If an upstream branch exists, use `@{u}..HEAD` as the diff range. If it does not (new branch, no tracking), fall back to `HEAD~1..HEAD`. If HEAD is the first commit ever, use `--root`.

Get the filtered diff (frontend files only):

```bash
git diff <range> -- '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb'
```

Also get the file list for quick reference:

```bash
git diff <range> --name-only -- '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb'
```

If no frontend files changed, output:

```
No frontend files changed. Skipping review.

REVIEW_STATUS: PASSED
```

Then stop.

## Step 2: Group changed files by type

Bucket each changed file into one of these categories for rule application:

| Type | Extensions |
|------|-----------|
| HTML | `.html` (non-ERB) |
| JavaScript | `.js`, `.mjs`, `.cjs` |
| TypeScript | `.ts` (non-JSX) |
| JSX / React | `.jsx`, `.tsx` |
| Vue SFC | `.vue` |
| ERB Template | `.html.erb`, `.erb` |

**Skip entirely:** `*.min.js`, `dist/`, `build/`, `node_modules/`, `*.lock`, `*.snap`, auto-generated files (look for `// @generated` or `// This file is auto-generated` headers).

**Treat with lighter scrutiny** (apply only BLOCKING rules): test files (`*.spec.*`, `*.test.*`, `__tests__/`, `spec/`).

## Step 3: Apply rules per file type

For each changed file, load and apply the rules from the corresponding reference file:

- HTML → `references/html-rules.md`
- JS / TS → `references/js-ts-rules.md`
- JSX / TSX → `references/js-ts-rules.md` + `references/jsx-rules.md`
- Vue → `references/js-ts-rules.md` + `references/vue-rules.md`
- ERB → `references/erb-rules.md`

Read the full file content (not just the diff) when context beyond the changed lines is needed to evaluate a rule correctly. Prefer precision — only flag issues that are clearly present.

Severity definitions:

- **BLOCKING** — Must be resolved before this push. Bugs, security vulnerabilities, breaking patterns, or runtime errors.
- **WARNING** — Should be resolved soon. Code quality, conventions, maintainability problems.
- **INFO** — Optional improvement. Minor style notes, suggestions, good-to-knows.

## Step 4: Incorporate project context

If a `.pr-review-context.md` file was loaded via the SessionStart hook (it appears in your context as "## Project-Specific Review Context"), apply any additional rules or special patterns it defines. Project rules take precedence over the generic reference rules when they conflict.

## Step 5: Output the review report

Use this exact format:

```
╔══════════════════════════════════════════╗
║      Frontend Pre-Push Review Report     ║
╚══════════════════════════════════════════╝

  Files reviewed : <N>
  Commits        : <N> (<short commit range>)
  File types     : <list of types found>

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
<1-3 sentence plain-English summary. Mention the most important
finding. Note if zero issues were found.>

REVIEW_STATUS: BLOCKED
```

Rules for the status line:
- Print `REVIEW_STATUS: BLOCKED` if there is **at least one BLOCKING issue**.
- Print `REVIEW_STATUS: PASSED` if there are zero BLOCKING issues (warnings and info are fine).
- The status line **must always be the very last line** of output with no trailing whitespace or blank lines after it, so the hook script can reliably grep for it.

If a section has zero items, omit the section header entirely (do not print "── BLOCKING ISSUES (0) ──").
