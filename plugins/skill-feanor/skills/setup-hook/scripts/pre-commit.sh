#!/bin/bash
# ============================================================
#  Frontend Pre-Commit Review Hook (skill-feanor)
#  Reviews staged changes for BLOCKING, WARNING, and INFO issues.
#  BLOCKING aborts the commit; WARNING + INFO are reported only.
#
#  To uninstall: rm .git/hooks/pre-commit
# ============================================================

set -euo pipefail

# ── Resolve claude binary ────────────────────────────────────────────────────
# Git hooks don't source .bashrc/.zshrc, so NVM-managed binaries may not be
# on PATH. Try common locations before giving up.
if ! command -v claude &>/dev/null; then
  # 1. NVM: source nvm.sh (no-use = don't switch node version, just expose bins)
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh" --no-use
  fi
fi
if ! command -v claude &>/dev/null; then
  # 2. Homebrew (macOS arm/intel) and common system paths
  for _try in \
      /opt/homebrew/bin/claude \
      /usr/local/bin/claude \
      "$HOME/.local/bin/claude"; do
    if [ -x "$_try" ]; then
      export PATH="$(dirname "$_try"):$PATH"
      break
    fi
  done
fi
# ────────────────────────────────────────────────────────────────────────────

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

REVIEW=$(claude \
  --add-dir "$HOME/.claude/plugins" \
  --print "Run feanor review on my staged changes" 2>&1) || true

echo "$REVIEW"
echo ""

if echo "$REVIEW" | grep -qE "COMMIT_STATUS: BLOCKED"; then
  echo "${RED}${BOLD}❌  Blocking issues found. Commit aborted.${RESET}"
  echo "    Fix the issues above, then try committing again."
  echo ""
  exit 1
fi

echo "${GREEN}${BOLD}✅  No blocking issues. Proceeding with commit.${RESET}"
echo ""
exit 0
