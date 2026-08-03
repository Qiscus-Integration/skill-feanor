---
name: setup-hook
description: >
  Install the frontend git pre-commit hook in the current repository. Use when the user says
  "set up the hook", "install the hook", "configure this plugin for my repo",
  "add the git hook", or "how do I activate this in my project". Run once per repo.
  Idempotent — re-running only refreshes the managed block.
metadata:
  version: "0.7.0"
---

Install a git pre-commit hook that reviews staged frontend changes. BLOCKING issues abort the commit; WARNING and INFO are reported but do not block.

The hook content is wrapped between marker lines:

```
# >>> skill-feanor:pre-commit BEGIN - managed block, do not edit
...
# <<< skill-feanor:pre-commit END
```

Re-running install replaces only that block. Other hook code (husky, lefthook, custom checks) is preserved. Uninstall strips only the block.

## Step 1: Verify prerequisites

Check that the current working directory is a git repository:

```bash
git rev-parse --git-dir 2>/dev/null
```

If this fails, stop and tell the user to run this from within their project's root directory.

Check that the Claude Code CLI is on the PATH:

```bash
which claude 2>/dev/null || command -v claude 2>/dev/null
```

If `claude` is not found, stop and instruct the user to install Claude Code first. Point them to https://claude.ai/download.

## Step 2: Inspect existing hook (informational)

```bash
HOOKS_DIR="$(git rev-parse --git-path hooks)"
ls -la "$HOOKS_DIR/pre-commit" 2>/dev/null || echo "no existing pre-commit hook"
```

If the file exists, check whether it already contains a managed skill-feanor block:

```bash
grep -F "skill-feanor:pre-commit BEGIN" "$HOOKS_DIR/pre-commit" 2>/dev/null \
  && echo "managed block present — install will refresh it" \
  || echo "no managed block — install will append one to the existing hook"
```

No confirmation is needed for either case; the installer never touches code outside the markers. Only ask the user before proceeding if the existing hook looks unusual (binary, very large, suspicious content).

## Step 3: Run the installer

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/setup-hook/scripts/install.sh"
```

Behavior:

- No hook file → creates one with `#!/bin/bash` + managed block.
- Hook exists, markers present → replaces only the block between markers.
- Hook exists, no markers, but legacy signature detected (`Frontend Pre-Commit Review Hook (skill-feanor)`) → asks for `y/N` confirmation before overwriting the entire file, saves a `.legacy.<timestamp>.bak` next to the hook, then writes the marker-wrapped version.
- Hook exists, no markers, no legacy signature → appends the managed block after existing content (user's other hook code preserved).

Pass `--yes` to skip the legacy-migration prompt (e.g., when running non-interactively). If a legacy hook is found, no TTY is attached, and `--yes` is not passed, the installer aborts with a clear message.

The block body is wrapped in a subshell so its `set -euo pipefail` and `exit` calls do not affect other hook code.

Verify executable:

```bash
ls -la "$HOOKS_DIR/pre-commit"
```

## Step 4: Offer to create a project context file

Ask the user: "Would you like to create a `.pr-review-context.md` file? This is where you define project-specific rules — things the generic reviewer doesn't know, like your naming conventions, patterns to avoid, or recurring issues from past reviews. It gets loaded automatically on every review."

If yes, create `.pr-review-context.md` in the current directory with this template:

```markdown
# PR Review Context

This file is automatically loaded by the skill-feanor plugin.
Add project-specific rules, patterns, and context that the reviewer should know.

## Project Overview

<!-- Brief description of this project and its frontend stack -->
<!-- Example: Customer-facing chat widget. React 18 + TypeScript, bundled with Vite. -->

## Tech Stack

<!-- List the main frameworks, libraries, and versions -->
<!-- Example: React 18, TypeScript 5, Tailwind CSS 3, React Query -->

## Special Rules

<!-- Rules specific to this codebase that override or supplement the defaults -->
<!-- Example: -->
<!-- - All API calls must go through the `useApi` custom hook, not raw fetch -->
<!-- - Component files must be co-located with their CSS module (ComponentName.module.css) -->
<!-- - Use `cx()` from classnames for conditional classes, not string interpolation -->

## Patterns to Avoid

<!-- Anti-patterns that have caused issues in this repo before -->
<!-- Example: -->
<!-- - Do not use `useLayoutEffect` — causes SSR issues in this app -->
<!-- - Avoid accessing `window` at module level; always check `typeof window !== 'undefined'` -->

## Common Issues Found in Manual Review

<!-- Issues that reviewers keep flagging — help Claude catch these early -->
<!-- Example: -->
<!-- - Missing loading states in async components -->
<!-- - Hardcoded pixel values instead of Tailwind spacing tokens -->
```

## Step 5: Confirm success

Print a clear confirmation:

```
✅ Hook installed:
   .git/hooks/pre-commit  — reviews staged frontend changes (managed block)

How it works:
  git commit
    → Feanor reviews staged files for BLOCKING, WARNING, and INFO issues
    → BLOCKING:        commit aborted, fix and retry
    → WARNING + INFO:  reported but commit proceeds

Re-running setup-hook is safe — only the managed block between
"# >>> skill-feanor:pre-commit BEGIN" and "# <<< skill-feanor:pre-commit END"
is replaced. Other hook content stays intact.

Optional project context:
  - Edit .pr-review-context.md to add project-specific rules
  - Loaded automatically on every review — no configuration needed
```

## Skipping the review

Skip feanor while still letting other pre-commit hooks (lint, lefthook, husky
tasks) run. `git commit --no-verify` is the global escape hatch — it skips
every hook in the file, which is usually not what you want.

**Per-tool skip — environment variable:**

```bash
SKILL_FEANOR_SKIP=1 git commit -m "wip: experimental"
```

Why no commit-message marker? Tested git's actual hook order: pre-commit fires
*before* git writes the new commit message to `.git/COMMIT_EDITMSG`. The file
on disk holds the *previous* commit's message at the time pre-commit runs, so
any "[skip feanor]" marker in the current message is unreadable from inside the
hook. This is a hard git design constraint, not something we can work around.

**GUI clients (VS Code / GitKraken / JetBrains):**

The commit button has no per-click env-var injection. Workarounds:

- *Workspace toggle.* Add to `.vscode/settings.json` when you need to skip:
  ```json
  { "git.env": { "SKILL_FEANOR_SKIP": "1" } }
  ```
  Affects all git operations VS Code runs in that workspace until you remove it.
- *Terminal commit.* Stage in the GUI, then commit from a terminal with the env
  var set.
- *`--no-verify`.* Use the GUI's "commit (no verify)" action when you need to
  bypass every hook.

## Uninstall

When the user asks to remove the hook ("uninstall the hook", "remove the pre-commit hook", "disable feanor"):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/setup-hook/scripts/uninstall.sh"
```

Behavior:

- Markers present → strips only content between BEGIN/END. If the remaining file has no meaningful content (only shebang/blanks), deletes the hook file entirely. Otherwise leaves other hook code in place.
- No markers, legacy signature detected → asks for `y/N` confirmation, writes a `.legacy.<timestamp>.bak`, then deletes the hook.
- No markers, no legacy signature → does nothing.

Pass `--yes` to skip the legacy confirmation prompt.
