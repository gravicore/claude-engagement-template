#!/usr/bin/env bash
# check-stub-format.sh - PostToolUse check for stub SKILL.md files.
# A stub has "allowed-tools: []" and must say "not yet implemented". Feedback only: the tool already
# ran, so exit 2 just shows the message to Claude. CI check "Validate plugin integrity" is the gate.
#
# Input: hook JSON on stdin. Exit: 0 fine or not applicable, 2 feedback.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HOOK_DIR/_hook-input.sh"

read_hook_input
FILE="$(json_get tool_input.file_path)" || exit 0

[[ "$FILE" =~ /SKILL\.md$ ]] || exit 0
[[ -f "$FILE" ]] || exit 0
grep -q '^allowed-tools: \[\]' "$FILE" 2>/dev/null || exit 0
grep -qi 'not yet implemented' "$FILE" 2>/dev/null && exit 0

{
  echo "WARNING: stub SKILL.md at $FILE has allowed-tools: [] but is missing 'not yet implemented'."
  echo "  Add a body line such as: 'This skill is not yet implemented.'"
  echo "  CI will fail on this file."
} >&2
exit 2
