#!/bin/bash
# Installs (or updates) the skill-feanor pre-commit block in .git/hooks/pre-commit.
# Coexists with other hook content via BEGIN/END markers.
set -euo pipefail

ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help)
      cat <<'USAGE'
Usage: install.sh [-y|--yes]
  -y, --yes   Skip interactive confirmation when migrating a legacy
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCK_SRC="$SCRIPT_DIR/pre-commit.sh"
BEGIN_MARKER="# >>> skill-feanor:pre-commit BEGIN - managed block, do not edit"
END_MARKER="# <<< skill-feanor:pre-commit END"
LEGACY_SIGNATURE="Frontend Pre-Commit Review Hook (skill-feanor)"

if [ ! -f "$BLOCK_SRC" ]; then
  echo "Source script missing: $BLOCK_SRC" >&2
  exit 1
fi

HOOKS_DIR="$(git rev-parse --git-path hooks 2>/dev/null)" || {
  echo "Not inside a git repository." >&2
  exit 1
}
mkdir -p "$HOOKS_DIR"
HOOK_PATH="$HOOKS_DIR/pre-commit"

# Strip shebang from block source; isolate via subshell so set/exit don't leak.
BLOCK_BODY="$(sed '1{/^#!/d;}' "$BLOCK_SRC")"

NEW_BLOCK_FILE="$(mktemp)"
NEW_HOOK_FILE="$(mktemp)"
trap 'rm -f "$NEW_BLOCK_FILE" "$NEW_HOOK_FILE"' EXIT

{
  printf '%s\n' "$BEGIN_MARKER"
  printf '(\n'
  printf '%s\n' "$BLOCK_BODY"
  printf ') || exit $?\n'
  printf '%s\n' "$END_MARKER"
} > "$NEW_BLOCK_FILE"

if [ -f "$HOOK_PATH" ] && grep -qF "$BEGIN_MARKER" "$HOOK_PATH"; then
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v blockfile="$NEW_BLOCK_FILE" '
    BEGIN {
      while ((getline line < blockfile) > 0) {
        block = block (block ? "\n" : "") line
      }
      close(blockfile)
    }
    $0 == begin { print block; in_block=1; next }
    in_block && $0 == end { in_block=0; next }
    !in_block { print }
  ' "$HOOK_PATH" > "$NEW_HOOK_FILE"
  mv "$NEW_HOOK_FILE" "$HOOK_PATH"
  ACTION="Updated skill-feanor block in"
elif [ -f "$HOOK_PATH" ] && grep -qF "$LEGACY_SIGNATURE" "$HOOK_PATH"; then
  # Legacy unmarked install (pre-0.4.0). Whole file was skill-feanor at install time,
  # but the user may have hand-edited it since — confirm before overwriting.
  echo ""
  echo "Detected a legacy skill-feanor pre-commit hook (no marker block)."
  echo "Hook: $HOOK_PATH"
  echo ""
  echo "Migrating will replace the entire file with a fresh shebang + managed block."
  echo "Any manual edits to the legacy script will be lost."
  echo ""

  CONFIRMED=0
  reply=""
  if [ "$ASSUME_YES" -eq 1 ]; then
    CONFIRMED=1
  else
    # Prefer current stdin (covers both interactive TTY and piped input).
    # Fall back to /dev/tty if stdin is closed/EOF (e.g., < /dev/null).
    if read -r -p "Proceed with migration? [y/N] " reply; then
      :
    elif [ -r /dev/tty ] && read -r -p "Proceed with migration? [y/N] " reply < /dev/tty; then
      :
    else
      echo "No input available for confirmation. Re-run with --yes to migrate non-interactively." >&2
      exit 1
    fi
    case "$reply" in
      y|Y|yes|YES) CONFIRMED=1 ;;
    esac
  fi

  if [ "$CONFIRMED" -ne 1 ]; then
    echo "Aborted. Legacy hook left unchanged."
    exit 1
  fi

  # Back up before overwriting.
  BACKUP="$HOOK_PATH.legacy.$(date +%Y%m%d%H%M%S).bak"
  cp "$HOOK_PATH" "$BACKUP"

  {
    printf '#!/bin/bash\n\n'
    cat "$NEW_BLOCK_FILE"
  } > "$HOOK_PATH"
  ACTION="Migrated legacy unmarked install (backup: $BACKUP) to managed block in"
elif [ -f "$HOOK_PATH" ]; then
  {
    cat "$HOOK_PATH"
    printf '\n'
    cat "$NEW_BLOCK_FILE"
  } > "$NEW_HOOK_FILE"
  mv "$NEW_HOOK_FILE" "$HOOK_PATH"
  ACTION="Appended skill-feanor block to existing"
else
  {
    printf '#!/bin/bash\n\n'
    cat "$NEW_BLOCK_FILE"
  } > "$HOOK_PATH"
  ACTION="Created"
fi

chmod +x "$HOOK_PATH"
echo "$ACTION $HOOK_PATH"
