#!/usr/bin/env bash
# format-file.sh - PostToolUse formatter: runs Prettier over a written .md, .json, .yml or .yaml file
# with the repo's own config. CI "Format check" is the gate; this only saves a failed push.
#
# Input: hook JSON on stdin. Exit: 0 formatted or not applicable, 2 prettier failed (shown to Claude).

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HOOK_DIR/_hook-input.sh"

read_hook_input
FILE="$(json_get tool_input.file_path)" || exit 0

case "$FILE" in
  *.md | *.json | *.yml | *.yaml) ;;
  *) exit 0 ;;
esac
[[ -f "$FILE" ]] || exit 0

PROJECT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$PROJECT" || exit 0

# Prefer an installed prettier at the pinned version (mise installs it); otherwise fetch that version.
if [[ "$(prettier --version 2>/dev/null)" == "3.8.3" ]]; then
  PRETTIER=(prettier)
else
  PRETTIER=(npx --yes prettier@3.8.3)
fi

if ! OUT="$("${PRETTIER[@]}" --write --config .prettierrc.json --ignore-path .prettierignore "$FILE" 2>&1)"; then
  echo "prettier failed on $FILE:" >&2
  echo "$OUT" >&2
  exit 2
fi
exit 0
