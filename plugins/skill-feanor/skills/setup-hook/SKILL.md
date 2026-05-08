---
name: setup-hook
description: >
  Install the frontend git pre-commit hook in the current repository. Use when the user says
  "set up the hook", "install the hook", "configure this plugin for my repo",
  "add the git hook", or "how do I activate this in my project". Run once per repo.
metadata:
  version: "0.3.0"
---

Install a git pre-commit hook that reviews staged frontend changes. BLOCKING issues abort the commit; WARNING and INFO are reported but do not block.

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

## Step 2: Check for existing hook

```bash
ls -la .git/hooks/pre-commit 2>/dev/null
```

If the file already exists, show the user its current contents and ask whether to overwrite it. Do not overwrite without confirmation.

## Step 3: Install the hook script

```bash
cp "${CLAUDE_PLUGIN_ROOT}/skills/setup-hook/scripts/pre-commit.sh" .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Confirm the file is executable:

```bash
ls -la .git/hooks/pre-commit
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
   .git/hooks/pre-commit  — reviews staged frontend changes

How it works:
  git commit
    → Feanor reviews staged files for BLOCKING, WARNING, and INFO issues
    → BLOCKING:        commit aborted, fix and retry
    → WARNING + INFO:  reported but commit proceeds

Optional project context:
  - Edit .pr-review-context.md to add project-specific rules
  - Loaded automatically on every review — no configuration needed
```
