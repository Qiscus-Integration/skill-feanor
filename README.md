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
One-time setup per repository. Installs the git pre-commit hook as a *managed block* between BEGIN/END markers so it coexists with other tooling (husky, lefthook, custom hooks). Re-running the skill is idempotent — it refreshes only the managed block. Also offers to create a `.pr-review-context.md` for project-specific rules.

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
bash ~/.claude/plugins/cache/qiscus-plugins/skill-feanor/skills/setup-hook/scripts/install.sh
```

The installer detects the current state and acts accordingly:

| Existing hook state | Installer behavior |
|--|--|
| No file | Creates `.git/hooks/pre-commit` with shebang + managed block |
| Markers present | Replaces only the block between markers |
| Other hook code, no markers | Appends the managed block (other content preserved) |
| Legacy pre-0.4.0 install (no markers, feanor-only file) | Prompts before overwriting; writes a `.legacy.<ts>.bak` backup. Pass `--yes` to skip the prompt. |

**Verify:**
```bash
grep -F "skill-feanor:pre-commit BEGIN" .git/hooks/pre-commit
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

## Skipping a single commit

`git commit --no-verify` skips **every** pre-commit hook in the file, not just feanor's block. To skip only the feanor review while letting other pre-commit tooling run, set the env var:

```bash
SKILL_FEANOR_SKIP=1 git commit -m "wip: experimental"
```

GUI clients (VS Code Source Control, GitKraken, JetBrains) have no per-click env-var injection. Workarounds:

- Add `"git.env": { "SKILL_FEANOR_SKIP": "1" }` to `.vscode/settings.json` temporarily.
- Commit from a terminal with the env var set.
- Use the GUI's "commit (no verify)" action when bypassing every hook is fine.

The commit-message marker approach (e.g. `[skip feanor]`) is not supported — git fires pre-commit *before* writing the new message to `.git/COMMIT_EDITMSG`, so the hook can't read it. This is a git design constraint, not a missing feature.

---

## Uninstalling from a repo

```bash
bash ~/.claude/plugins/cache/qiscus-plugins/skill-feanor/skills/setup-hook/scripts/uninstall.sh
```

Behavior:
- Strips only the managed block between BEGIN/END markers.
- Deletes `.git/hooks/pre-commit` entirely if no other content remained.
- Other hook code (husky, lefthook, custom scripts) is preserved.
- Legacy pre-0.4.0 install: prompts before deletion, writes a `.legacy.<ts>.bak` backup. Pass `--yes` to skip the prompt.

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

---

## Roadmap to v1.0.0

The plugin is on the `0.x` track — the public surface (marker strings, env var name, CLI flags, severity buckets, rule IDs) may still change. Items targeted before cutting `1.0.0`:

- **Decide fail-mode when `claude` is unavailable.** Today the hook prints a warning and lets the commit through (fail-open). For production use this is a silent bypass. Need an explicit, documented contract — fail-closed by default, or fail-open with a louder signal.
- **Timeout around the `claude` call.** Network hiccups or slow reviews can hang the commit indefinitely. Wrap the invocation with `timeout` and define behavior on timeout.
- **Exit-code-based gating.** The hook currently greps stdout for `COMMIT_STATUS: BLOCKED`. Fragile against any change to the review skill's output format. Replace with a defined exit-code contract on the review side.
- **`CHANGELOG.md`.** Per-version entries so consumers know what shipped.
- **Automated tests.** Today install/uninstall/skip behavior is verified by hand. Needs a small bash test suite (or `bats`) covering: fresh install, marker replace, legacy migration, env var skip, worktrees, custom `core.hooksPath`.
- **Burn-in.** 0.5.0 / 0.6.0 in real repos for several weeks before promising stability with `1.0.0`.
- **Git tag.** Cut `v1.0.0` only after the items above land.
