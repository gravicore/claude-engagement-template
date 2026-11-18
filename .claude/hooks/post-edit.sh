#!/usr/bin/env bash
# post-edit.sh - PostToolUse entry point for Edit|Write. Claude Code runs the hooks of one event in
# parallel, so the steps that touch the same file are sequenced here instead: format first, then the
# checks that read the formatted result. Every step gets the original hook JSON on stdin.
#
# PostToolUse cannot block (the tool already ran). Exit 2 shows stderr to Claude as feedback, so any
# failing step makes this script exit 2 with every step's message.
#
# Exit: 0 all steps clean, 2 at least one step reported a problem.

set -uo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT="$(cat)"
STATUS=0

run_step() {
  local out
  if ! out="$(printf '%s' "$INPUT" | "$@" 2>&1)"; then
    STATUS=2
    [[ -n "$out" ]] && printf '%s\n' "$out" >&2
  fi
}

run_step bash "$HOOK_DIR/format-file.sh"
run_step bash "$HOOK_DIR/lint-yaml.sh"
run_step bash "$HOOK_DIR/check-stub-format.sh"
run_step bash "$HOOK_DIR/check-skill-suffix.sh"
run_step python3 "$HOOK_DIR/regen-template-index.py"

exit "$STATUS"
