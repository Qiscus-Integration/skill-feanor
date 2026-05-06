#!/bin/bash
# ============================================================
#  frontend-push-review — git pre-push hook
#  Installed by the frontend-push-review Claude plugin.
#
#  To bypass this hook:  git push --no-verify
#  To uninstall:         rm .git/hooks/pre-push
# ============================================================

set -euo pipefail

# ── Colour helpers (gracefully degrade if terminal has no colour) ──
if [ -t 1 ] && command -v tput &>/dev/null && tput colors &>/dev/null; then
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  CYAN=$(tput setaf 6)
else
  BOLD="" RESET="" RED="" GREEN="" YELLOW="" CYAN=""
fi

echo ""
echo "${BOLD}${CYAN}🔍  Running frontend pre-push review...${RESET}"
echo ""

# ── Sanity checks ──────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  echo "${YELLOW}⚠️   Claude Code CLI not found. Skipping pre-push review.${RESET}"
  echo "    Install Claude Code to enable automatic reviews: https://claude.ai/download"
  echo ""
  exit 0
fi

# ── Check if there are any frontend files in the diff ─────────────
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "HEAD~1")
CHANGED=$(git diff "${UPSTREAM}..HEAD" --name-only -- \
  '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb' 2>/dev/null || true)

if [ -z "$CHANGED" ]; then
  echo "${GREEN}✅  No frontend files changed. Skipping review.${RESET}"
  echo ""
  exit 0
fi

# ── Run Claude review ──────────────────────────────────────────────
REVIEW_OUTPUT=$(claude --print "Run pre-push-review on my current git changes" 2>&1) || true

echo "$REVIEW_OUTPUT"
echo ""

# ── Parse result ──────────────────────────────────────────────────
if echo "$REVIEW_OUTPUT" | grep -q "REVIEW_STATUS: BLOCKED"; then
  echo "${RED}${BOLD}❌  Blocking issues found. Push aborted.${RESET}"
  echo "    Fix the issues above, then push again."
  echo "    To skip the review:  ${BOLD}git push --no-verify${RESET}"
  echo ""
  exit 1
fi

echo "${GREEN}${BOLD}✅  Review passed. Proceeding with push.${RESET}"
echo ""
exit 0
