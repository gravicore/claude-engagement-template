# Stub Format

A stub is a placeholder skill - it reserves a name and trigger in the plugin, but the
implementation is deferred. Stubs are honest: they tell users the skill is not yet
implemented rather than silently doing nothing.

## Minimal Template

```markdown
---
name: grv-<action>
description: >
  One sentence trigger description. Triggers on: "phrase 1".
allowed-tools: []
---

This skill is not yet implemented.
```

Rules:

- `name` - equals the skill directory name (CI-enforced)
- `allowed-tools: []` - empty array; no tools permitted for unimplemented skills
- Body must contain exactly "not yet implemented" (case-insensitive) - CI verifies this, and the local hook reports it
- Description must include at least one trigger phrase so Claude Code can match user intent

## What CI Checks

The "Check stub format" step of the `validate-plugin-integrity` CI job (and the local `check-stub-format.sh` PostToolUse
hook, which only reports) verify:

1. The SKILL.md contains `allowed-tools: []` (identifying it as a stub)
2. The SKILL.md body contains the text "not yet implemented" (case-insensitive)

If a file has `allowed-tools: []` but is missing "not yet implemented", CI fails with:
`ERROR: Stub SKILL.md missing "not yet implemented": <path>`

## When to Un-stub

A stub graduates to a full skill when:

- The implementation is ready to ship
- The skill body is replaced with the full prompt (under 120 lines)
- `allowed-tools: []` is replaced with the actual tools the skill needs
- The plugin version is bumped in both `plugin.json` and `marketplace.json` (CI fails if they differ)
- A sibling `tests.yaml` is added (3-5 test cases required, in the format in `SKILL-TESTING.md`)

Do not partially implement a stub - keep it as a stub until the full implementation is ready.
