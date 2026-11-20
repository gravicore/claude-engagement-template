#!/usr/bin/env bash
# check-skill-suffix.sh - PostToolUse check for skill directory names.
# Warns when a skill in an engagement (prefixed) plugin lacks the engagement prefix, or when a skill
# name does not end in an allowed suffix. Skills in a generic plugin (listed in .engagement.json)
# carry no prefix. Feedback only: the tool already ran, so exit 2 just shows the message to Claude.
# CI (scripts/check-naming.py) enforces the prefix and global uniqueness; suffixes are checked only here.
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

[[ "$FILE" =~ /plugins/([^/]+)/skills/([^/]+)/SKILL\.md$ ]] || exit 0
PLUGIN_NAME="${BASH_REMATCH[1]}"
SKILL_NAME="${BASH_REMATCH[2]}"

ALLOWED_SUFFIXES="writer|brief|summary|review|notes|reference|apply|release|run|init|setup|sync|planner|complete|close|deliver|update|session|fix|learn"
MESSAGES=()

# Read the prefix and whether this plugin is generic from .engagement.json; skip the prefix check
# when the file is unreadable or still holds the init placeholder.
CONFIG="${CLAUDE_PROJECT_DIR:-$PWD}/.engagement.json"
PREFIX=""
IS_GENERIC=""
if [[ -f "$CONFIG" ]] && command -v python3 >/dev/null 2>&1; then
  read -r PREFIX IS_GENERIC < <(python3 -I -c '
import json, sys
try:
    c = json.load(open(sys.argv[1]))
except (OSError, ValueError):
    sys.exit(0)
print(c.get("prefix", ""), "yes" if sys.argv[2] in c.get("genericPlugins", []) else "no")
' "$CONFIG" "$PLUGIN_NAME" 2>/dev/null) || true
fi

if [[ "$IS_GENERIC" == "no" && "$PREFIX" =~ ^[a-z][a-z0-9]{1,7}$ && ! "$SKILL_NAME" =~ ^${PREFIX}- ]]; then
  MESSAGES+=("WARNING: skill '$SKILL_NAME' in engagement plugin '$PLUGIN_NAME' does not start with '${PREFIX}-'. Use ${PREFIX}-<action>. CI will fail on this.")
fi

if ! [[ "$SKILL_NAME" =~ (^|-)(${ALLOWED_SUFFIXES})$ ]]; then
  MESSAGES+=("WARNING: skill name '$SKILL_NAME' does not end in an allowed suffix (${ALLOWED_SUFFIXES//|/, }).")
  MESSAGES+=("  See docs/contributing/SKILL-AUTHORING.md. If the suffix is intentional, amend the taxonomy first.")
fi

[[ ${#MESSAGES[@]} -eq 0 ]] && exit 0
printf '%s\n' "${MESSAGES[@]}" >&2
exit 2
