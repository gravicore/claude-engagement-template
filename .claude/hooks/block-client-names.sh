#!/usr/bin/env bash
# block-client-names.sh - PreToolUse guard on Edit|Write.
# Refuses (exit 2, reason on stderr) a write that would put a name listed in .clients into a file
# outside references/ directories. Edit is checked on the text being added (new_string), Write on the
# whole new content (content).
#
# Scope mirrors the CI isolation check: .md .json .yml .yaml .sh files, skipping references/ and any
# dot-directory. Bash redirects, NotebookEdit and other tools bypass this hook, so it is a fast
# local guard; the CI "Validate plugin integrity" job is the enforcement point.
#
# Input: hook JSON on stdin. Exit: 0 allow, 2 block, 1 non-blocking error (cannot parse input).

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$HOOK_DIR/_hook-input.sh"

read_hook_input
FILE="$(json_get tool_input.file_path)" || {
  echo "block-client-names: cannot parse hook input (valid JSON plus jq or python3 required); CI is the enforcement point." >&2
  exit 1
}
[[ -n "$FILE" ]] || exit 0

REL="$(project_relative "$FILE")"
[[ "$REL" == /* ]] && exit 0
case "$REL" in
  references/* | */references/*) exit 0 ;;
  .* | */.*) exit 0 ;;
  *.md | *.json | *.yml | *.yaml | *.sh) ;;
  *) exit 0 ;;
esac

CLIENTS_FILE="${CLAUDE_PROJECT_DIR:-$PWD}/.clients"
[[ -f "$CLIENTS_FILE" ]] || exit 0

TOOL="$(json_get tool_name)"
if [[ "$TOOL" == "Edit" ]]; then
  TEXT="$(json_get tool_input.new_string)"
else
  TEXT="$(json_get tool_input.content)"
fi
[[ -n "$TEXT" ]] || exit 0

while IFS= read -r client || [[ -n "$client" ]]; do
  client="${client%$'\r'}"
  [[ -z "${client//[[:space:]]/}" ]] && continue
  [[ "$client" =~ ^[[:space:]]*# ]] && continue
  if printf '%s' "$TEXT" | grep -qiwF -- "$client"; then
    {
      echo "BLOCKED: a name listed in .clients would be written outside references/."
      echo "  Name: $client"
      echo "  File: $REL"
      echo "  Client names are only allowed under plugins/<name>/references/. Move the content there or remove the name."
    } >&2
    exit 2
  fi
done <"$CLIENTS_FILE"

exit 0
