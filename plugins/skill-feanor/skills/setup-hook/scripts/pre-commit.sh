#!/bin/bash
# ============================================================
#  Frontend Pre-Commit Review Hook (skill-feanor)
#  Checks staged changes for BLOCKING issues only.
#
#  To bypass:  git commit --no-verify
#  To uninstall: rm .git/hooks/pre-commit
# ============================================================

set -euo pipefail

if [ -t 1 ] && command -v tput &>/dev/null && tput colors &>/dev/null; then
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  CYAN=$(tput setaf 6)
else
  BOLD="" RESET="" RED="" GREEN="" CYAN=""
fi

echo ""
echo "${BOLD}${CYAN}🔍  Feanor: checking staged changes for blocking issues...${RESET}"
echo ""

if ! command -v claude &>/dev/null; then
  echo "${BOLD}⚠️   Claude Code CLI not found. Skipping pre-commit review.${RESET}"
  echo "    Install Claude Code to enable: https://claude.ai/download"
  echo ""
  exit 0
fi

CHANGED=$(git diff --cached --name-only -- \
  '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb' 2>/dev/null || true)

if [ -z "$CHANGED" ]; then
  echo "${GREEN}✅  No frontend files staged. Skipping review.${RESET}"
  echo ""
  exit 0
fi

REVIEW=$(FEANOR_MODE=commit claude \
  --add-dir "$HOME/.claude/plugins" \
  --print "Run pre-push-review on my staged changes" 2>&1) || true

echo "$REVIEW"
echo ""

if echo "$REVIEW" | grep -qE "(COMMIT|REVIEW)_STATUS: BLOCKED"; then
  echo "${RED}${BOLD}❌  Blocking issues found. Commit aborted.${RESET}"
  echo "    Fix the issues above, then try committing again."
  echo "    To skip the review:  ${BOLD}git commit --no-verify${RESET}"
  echo ""
  exit 1
fi

echo "${GREEN}${BOLD}✅  No blocking issues. Proceeding with commit.${RESET}"
echo ""
exit 0