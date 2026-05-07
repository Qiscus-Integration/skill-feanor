#!/bin/bash
# ============================================================
#  Frontend Pre-Push Review Hook (skill-feanor)
#  Reports WARNING and INFO issues across unpushed commits.
#  Never blocks — BLOCKING issues are caught at commit time.
#
#  To bypass:  git push --no-verify
#  To uninstall: rm .git/hooks/pre-push
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
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  CYAN=$(tput setaf 6)
else
  BOLD="" RESET="" GREEN="" YELLOW="" CYAN=""
fi

echo ""
echo "${BOLD}${CYAN}🔍  Feanor: reviewing unpushed commits for warnings...${RESET}"
echo ""

if ! command -v claude &>/dev/null; then
  echo "${YELLOW}⚠️   Claude Code CLI not found. Skipping pre-push review.${RESET}"
  echo "    Install Claude Code to enable: https://claude.ai/download"
  echo ""
  exit 0
fi

UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "HEAD~1")
CHANGED=$(git diff "${UPSTREAM}..HEAD" --name-only -- \
  '*.html' '*.js' '*.mjs' '*.cjs' '*.ts' '*.tsx' '*.jsx' '*.vue' '*.erb' 2>/dev/null || true)

if [ -z "$CHANGED" ]; then
  echo "${GREEN}✅  No frontend files changed. Skipping review.${RESET}"
  echo ""
  exit 0
fi

# Run in push mode — reports WARNING and INFO only, never blocks
REVIEW=$(FEANOR_MODE=push claude \
  --add-dir "$HOME/.claude/plugins" \
  --print "Run feanor review on my current git changes" 2>&1) || true

echo "$REVIEW"
echo ""

# Pre-push never blocks — always exit 0
echo "${GREEN}${BOLD}✅  Review complete. Proceeding with push.${RESET}"
echo ""
exit 0
