#!/usr/bin/env bash
# lint-yaml.sh - PostToolUse lint: runs yamllint with the repo config over a written workflow file.
# Scope matches CI "Lint YAML workflows" (.github/workflows/ only).
#
# Input: hook JSON on stdin. Exit: 0 clean, skipped or not applicable, 2 lint errors (shown to Claude).

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HOOK_DIR/_hook-input.sh"

read_hook_input
FILE="$(json_get tool_input.file_path)" || exit 0

case "$FILE" in
  */.github/workflows/*.yml | */.github/workflows/*.yaml) ;;
  *) exit 0 ;;
esac
[[ -f "$FILE" ]] || exit 0
command -v yamllint >/dev/null 2>&1 || exit 0

if ! OUT="$(yamllint -c "${CLAUDE_PROJECT_DIR:-$PWD}/.yamllint.yml" "$FILE" 2>&1)"; then
  echo "yamllint failed on $FILE:" >&2
  echo "$OUT" >&2
  exit 2
fi
exit 0
