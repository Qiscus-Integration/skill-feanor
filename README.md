# skill-feanor

A Claude plugin that reviews frontend code changes automatically before every `git commit`. Catches common bugs, security issues, and convention violations in HTML, JavaScript, TypeScript, JSX/TSX, Vue SFCs, and HTML ERB — so your manual PR reviewers can focus on the complex stuff.

---

## How it works

```
dev edits code
       ↓
git commit
       ↓
pre-commit hook fires
       ↓
Claude reviews staged frontend files
       ↓
  ┌─────────────────────────────────────────┐
  │ BLOCKING issues found?                  │
  │  Yes → commit aborted, fix first        │
  │  No  → commit proceeds                  │
  │       (WARNING + INFO printed anyway)   │
  └─────────────────────────────────────────┘
       ↓
git push → PR review focused on complex changes only
```

---

## Skills

### `pre-commit-review`
The core review skill. Triggered automatically by the pre-commit hook, or manually by asking Claude to "review my staged changes".

Covers:
- **HTML** — accessibility (alt, labels, roles), semantic structure, inline styles, heading hierarchy
- **JavaScript / TypeScript** — debugger statements, hardcoded secrets, empty catch blocks, console.log, `any` type, `@ts-ignore`, fire-and-forget async, `var` usage
- **JSX / React** — missing keys in lists, `dangerouslySetInnerHTML`, missing effect dependencies, inline object/array props, component-in-render
- **Vue SFCs** — `v-for` without `:key`, `v-html`, prop mutation, `$parent` access, props without types
- **HTML ERB** — `raw()` / `.html_safe` XSS, unescaped JS interpolation, N+1 query patterns, hardcoded routes, logic in views

Issues are reported in three severities, all surfaced at commit time:
- **BLOCKING** — commit is aborted until fixed
- **WARNING** — reported but commit proceeds
- **INFO** — minor suggestions

### `setup-hook`
One-time setup per repository. Installs the git pre-commit hook and optionally creates a `.pr-review-context.md` file for project-specific rules.

---

## Installation

### 1. Install the plugin into Claude Code

Inside Claude Code, run `/plugin list`, then add this marketplace source:

```
Qiscus-Integration/skill-feanor
```

Once the marketplace is added, install the plugin:

```
/plugin install skill-feanor@qiscus-plugins
```

That's it — no cloning required. Claude Code fetches it directly from GitHub.

### 2. Set up the hook in your project repo

**Prerequisites:**
- [Claude Code CLI](https://claude.ai/download) installed and on your PATH
- This plugin installed (step 1 above)

Open Claude inside your project directory and ask: *"Set up the frontend pre-commit hook in this repo"*. The `setup-hook` skill will guide you through it.

Or manually:
```bash
# from inside your project repo
cp ~/.claude/plugins/cache/qiscus-plugins/skill-feanor/skills/setup-hook/scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Verify:**
```bash
cat .git/hooks/pre-commit   # should show the hook script
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
rm .git/hooks/pre-commit
```

The plugin itself remains installed in Claude Code and can be re-added to any repo at any time.

---

## Updating the rules

Rules live in plain markdown files inside `plugins/skill-feanor/skills/pre-commit-review/references/`. To update a rule, edit the relevant file and rebuild the `.plugin` artifact.

**Where each file type's rules live:**

| File | Rules for |
|------|-----------|
| `plugins/skill-feanor/skills/pre-commit-review/references/html-rules.md` | HTML |
| `plugins/skill-feanor/skills/pre-commit-review/references/js-ts-rules.md` | JS, TS, JSX, TSX, Vue (script block) |
| `plugins/skill-feanor/skills/pre-commit-review/references/jsx-rules.md` | JSX / React specific |
| `plugins/skill-feanor/skills/pre-commit-review/references/vue-rules.md` | Vue SFC specific |
| `plugins/skill-feanor/skills/pre-commit-review/references/erb-rules.md` | HTML ERB |

**Contribution workflow:**

1. Clone the plugin repo
2. Edit the relevant rules file
3. Open a PR — rules are plain markdown, easy to review
4. Once merged, rebuild the `.plugin` and commit it:
   ```bash
   ./plugins/skill-feanor/build.sh
   ```
5. Teammates reinstall the updated `.plugin` file

**Rebuilding manually** (if you don't want to use `build.sh`):
```bash
cd plugins/skill-feanor
zip -r ../../skill-feanor.plugin . -x "*.DS_Store"
```
