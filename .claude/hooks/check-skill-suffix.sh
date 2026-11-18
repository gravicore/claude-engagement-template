#!/usr/bin/env bash
# check-skill-suffix.sh - PostToolUse check for skill directory names.
# Warns when a skill directory lacks the grv- prefix or does not end in an allowed suffix. Feedback
# only: the tool already ran, so exit 2 just shows the message to Claude. CI enforces the prefix and
# global uniqueness; suffixes are checked only here.
#
# Allowed suffixes: see docs/contributing/SKILL-AUTHORING.md (keep the two lists in sync).
#
# Input: hook JSON on stdin. Exit: 0 fine or not applicable, 2 feedback.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HOOK_DIR/_hook-input.sh"

read_hook_input
FILE="$(json_get tool_input.file_path)" || exit 0

[[ "$FILE" =~ /skills/([^/]+)/SKILL\.md$ ]] || exit 0
SKILL_NAME="${BASH_REMATCH[1]}"

ALLOWED_SUFFIXES="writer|brief|summary|review|notes|reference|apply|release|run|init|setup|sync|planner|complete|close|deliver|update|session|fix|learn"
MESSAGES=()

if [[ ! "$SKILL_NAME" =~ ^grv- ]]; then
  MESSAGES+=("WARNING: skill name '$SKILL_NAME' does not start with 'grv-'. Use grv-<action>. CI will fail on this.")
fi

if ! [[ "$SKILL_NAME" =~ -(${ALLOWED_SUFFIXES})$ ]]; then
  MESSAGES+=("WARNING: skill name '$SKILL_NAME' does not end in an allowed suffix (${ALLOWED_SUFFIXES//|/, }).")
  MESSAGES+=("  See docs/contributing/SKILL-AUTHORING.md. If the suffix is intentional, amend the taxonomy first.")
fi

[[ ${#MESSAGES[@]} -eq 0 ]] && exit 0
printf '%s\n' "${MESSAGES[@]}" >&2
exit 2
