#!/bin/bash
# Removes only the skill-feanor block from .git/hooks/pre-commit.
# If the block is the only content, deletes the hook file.
set -euo pipefail

ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help)
      cat <<'USAGE'
Usage: uninstall.sh [-y|--yes]
  -y, --yes   Skip interactive confirmation when removing a legacy
              (pre-0.4.0) unmarked install.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

BEGIN_MARKER="# >>> skill-feanor:pre-commit BEGIN - managed block, do not edit"
END_MARKER="# <<< skill-feanor:pre-commit END"
LEGACY_SIGNATURE="Frontend Pre-Commit Review Hook (skill-feanor)"

HOOKS_DIR="$(git rev-parse --git-path hooks 2>/dev/null)" || {
  echo "Not inside a git repository." >&2
  exit 1
}
HOOK_PATH="$HOOKS_DIR/pre-commit"

if [ ! -f "$HOOK_PATH" ]; then
  echo "No pre-commit hook to uninstall."
  exit 0
fi

if ! grep -qF "$BEGIN_MARKER" "$HOOK_PATH"; then
  if grep -qF "$LEGACY_SIGNATURE" "$HOOK_PATH"; then
    # Legacy unmarked install (pre-0.4.0). Whole file was skill-feanor at install time,
    # but user may have hand-edited it — confirm before deleting.
    echo ""
    echo "Detected a legacy skill-feanor pre-commit hook (no marker block)."
    echo "Hook: $HOOK_PATH"
    echo ""
    echo "Uninstalling will delete the entire file."
    echo "Any manual edits to the legacy script will be lost."
    echo ""

    CONFIRMED=0
    reply=""
    if [ "$ASSUME_YES" -eq 1 ]; then
      CONFIRMED=1
    else
      if read -r -p "Delete the file? [y/N] " reply; then
        :
      elif [ -r /dev/tty ] && read -r -p "Delete the file? [y/N] " reply < /dev/tty; then
        :
      else
        echo "No input available for confirmation. Re-run with --yes to remove non-interactively." >&2
        exit 1
      fi
      case "$reply" in
        y|Y|yes|YES) CONFIRMED=1 ;;
      esac
    fi

    if [ "$CONFIRMED" -ne 1 ]; then
      echo "Aborted. Legacy hook left in place."
      exit 1
    fi

    BACKUP="$HOOK_PATH.legacy.$(date +%Y%m%d%H%M%S).bak"
    cp "$HOOK_PATH" "$BACKUP"
    rm -f "$HOOK_PATH"
    echo "Removed legacy skill-feanor pre-commit hook at $HOOK_PATH (backup: $BACKUP)."
    exit 0
  fi
  echo "skill-feanor block not found in $HOOK_PATH. Nothing to remove."
  exit 0
fi

TMP="$(mktemp)"
TMP_TRIM="$(mktemp)"
trap 'rm -f "$TMP" "$TMP_TRIM"' EXIT

awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
  $0 == begin { in_block=1; next }
  in_block && $0 == end { in_block=0; next }
  !in_block { print }
' "$HOOK_PATH" > "$TMP"

# Drop trailing blank lines.
awk '{ lines[NR]=$0; if (NF) last=NR } END { for (i=1; i<=last; i++) print lines[i] }' \
  "$TMP" > "$TMP_TRIM"

# Anything left besides a shebang or blank lines?
MEANINGFUL="$(grep -vE '^(#!.*|[[:space:]]*)$' "$TMP_TRIM" || true)"

if [ -z "$MEANINGFUL" ]; then
  rm -f "$HOOK_PATH"
  echo "Removed $HOOK_PATH (no other hook content remained)."
else
  mv "$TMP_TRIM" "$HOOK_PATH"
  chmod +x "$HOOK_PATH"
  echo "Removed skill-feanor block from $HOOK_PATH (other content preserved)."
fi
