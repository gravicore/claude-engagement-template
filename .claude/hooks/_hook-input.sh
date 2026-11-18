#!/usr/bin/env bash
# _hook-input.sh - sourced by the other hooks. Claude Code delivers hook input as JSON on stdin
# (tool_name, tool_input.file_path, ...); it sets no per-field environment variables.
#
# read_hook_input   reads stdin once into HOOK_JSON
# json_get PATH     prints the value at a dotted path (for example tool_input.file_path), or nothing
#
# Parsing uses jq when present and python3 otherwise. When neither is available json_get fails, and
# the calling hook decides whether that is fatal.

HOOK_JSON=""

read_hook_input() {
  HOOK_JSON="$(cat)"
}

json_get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$HOOK_JSON" | jq -r --arg p "$1" 'getpath($p | split(".")) // empty' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$HOOK_JSON" | python3 -I -c '
import json, sys
try:
    d = json.load(sys.stdin)
except ValueError:
    sys.exit(1)
for k in sys.argv[1].split("."):
    d = d.get(k) if isinstance(d, dict) else None
sys.stdout.write("" if d is None else str(d))
' "$1" 2>/dev/null
  else
    return 1
  fi
}

# project_relative PATH: print PATH relative to the project directory when it lies inside it.
project_relative() {
  local project="${CLAUDE_PROJECT_DIR:-$PWD}"
  printf '%s' "${1#"$project"/}"
}
