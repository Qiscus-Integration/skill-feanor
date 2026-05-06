# skill-feanor

A Claude plugin that reviews frontend code changes automatically before every `git push`. Catches common bugs, security issues, and convention violations in HTML, JavaScript, TypeScript, JSX/TSX, Vue SFCs, and HTML ERB — so your manual PR reviewers can focus on the complex stuff.

---

## How it works

```
dev edits code
       ↓
git push
       ↓
pre-push hook fires
       ↓
Claude reviews changed frontend files
       ↓
  ┌────────────────────────────────┐
  │ BLOCKING issues found?         │
  │  Yes → push aborted, fix first │
  │  No  → push proceeds           │
  └────────────────────────────────┘
       ↓
PR created → manual review focused on complex changes only
```

---

## Skills

### `pre-push-review`
The core review skill. Triggered automatically by the git hook, or manually by asking Claude to "review my changes before pushing".

Covers:
- **HTML** — accessibility (alt, labels, roles), semantic structure, inline styles, heading hierarchy
- **JavaScript / TypeScript** — debugger statements, hardcoded secrets, empty catch blocks, console.log, `any` type, `@ts-ignore`, fire-and-forget async, `var` usage
- **JSX / React** — missing keys in lists, `dangerouslySetInnerHTML`, missing effect dependencies, inline object/array props, component-in-render
- **Vue SFCs** — `v-for` without `:key`, `v-html`, prop mutation, `$parent` access, props without types
- **HTML ERB** — `raw()` / `.html_safe` XSS, unescaped JS interpolation, N+1 query patterns, hardcoded routes, logic in views

Issues are reported in three severities:
- **BLOCKING** — push is aborted until fixed
- **WARNING** — reported but push proceeds
- **INFO** — minor suggestions

### `setup-hook`
One-time setup per repository. Installs the git pre-push hook and optionally creates a `.pr-review-context.md` file for project-specific rules.

---

## Setup (per repository)

**Prerequisites:**
- [Claude Code CLI](https://claude.ai/download) installed and on your PATH
- This plugin installed in Claude Code

**Install the hook:**

Open Claude and ask: *"Set up the frontend pre-push hook in this repo"* from within your project directory. The `setup-hook` skill will guide you through it.

Or manually:
```bash
cp /path/to/plugin/skills/setup-hook/scripts/pre-push.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

**Verify:**
```bash
cat .git/hooks/pre-push   # should show the hook script
```

---

## Project-Specific Context

Each repo can have a `.pr-review-context.md` file in its root. This file is automatically loaded at the start of every review session and lets you extend the default rules with project knowledge:

```markdown
# PR Review Context

## Tech Stack
React 18, TypeScript 5, Tailwind CSS 3

## Special Rules
- All API calls must go through the `useApi` hook, not raw fetch
- Use `cx()` for conditional classes, not string interpolation

## Patterns to Avoid
- Do not use `useLayoutEffect` — causes SSR issues
- Never access `window` at module level

## Common Issues
- Missing loading states in async components
- Hardcoded pixel values instead of Tailwind spacing tokens
```

The `setup-hook` skill creates a filled template for you.

---

## Uninstalling from a repo

```bash
rm .git/hooks/pre-push
```

The plugin itself remains installed in Claude Code and can be re-added to any repo at any time.

---

## Updating the rules

Rules live in plain markdown files inside `skills/pre-push-review/references/`. To update a rule, edit the relevant file and rebuild the `.plugin` artifact.

**Where each file type's rules live:**

| File | Rules for |
|------|-----------|
| `skills/pre-push-review/references/html-rules.md` | HTML |
| `skills/pre-push-review/references/js-ts-rules.md` | JS, TS, JSX, TSX, Vue (script block) |
| `skills/pre-push-review/references/jsx-rules.md` | JSX / React specific |
| `skills/pre-push-review/references/vue-rules.md` | Vue SFC specific |
| `skills/pre-push-review/references/erb-rules.md` | HTML ERB |

**Contribution workflow:**

1. Clone the plugin repo
2. Edit the relevant rules file
3. Open a PR — rules are plain markdown, easy to review
4. Once merged, rebuild the `.plugin` and commit it:
   ```bash
   ./build.sh
   ```
5. Teammates reinstall the updated `.plugin` file

**Rebuilding manually** (if you don't want to use `build.sh`):
```bash
cd skill-feanor
zip -r ../skill-feanor.plugin . -x "*.DS_Store"
```
