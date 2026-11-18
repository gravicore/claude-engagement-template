# Naming Convention

## Plugin names

Plugin directories and marketplace entries both use the `grv-<name>` pattern:

| Context                         | Form                  | Example                   |
| ------------------------------- | --------------------- | ------------------------- |
| Plugin directory on disk        | `plugins/grv-<name>/` | `plugins/grv-sdlc/`       |
| `marketplace.json` entry `name` | `grv-<name>`          | `grv-sdlc`                |
| Namespaced skill invocation     | `/<plugin>:<skill>`   | `/grv-sdlc:grv-phase-run` |

The install command is `grv-<name>@{{MARKETPLACE_NAME}}`, for example `grv-sdlc@{{MARKETPLACE_NAME}}`. It is kept out of the
table above because init substitutes the marketplace name and a substituted table would no longer be Prettier-aligned.

`plugin.json` requires a `name` field matching `^grv-.+$` that must equal the directory name.

## Skill names

All skill directories use the `grv-<action>` pattern:

| Context                | Form                                        | Example                                  |
| ---------------------- | ------------------------------------------- | ---------------------------------------- |
| Skill directory        | `plugins/grv-<plugin>/skills/grv-<action>/` | `plugins/grv-sdlc/skills/grv-phase-run/` |
| `name:` in SKILL.md    | the directory name                          | `grv-phase-run`                          |
| Invocation (supported) | `/<plugin>:<skill>`                         | `/grv-sdlc:grv-phase-run`                |
| Flat alias `/<skill>`  | not relied on - UNVERIFIED                  | `/grv-phase-run`                         |

Claude Code namespaces plugin skills as `/<plugin-name>:<skill-name>` (skills docs, checked 2026-11-18); that is the form
to write in documentation and prompts. The same docs describe a bare `/<name>` alias for a plugin skill only
conditionally (a skill that sets `name:`, when no other command uses the name), so a flat `/grv-<action>` alias is
unverified: confirm against current docs before depending on it.

Skill names stay **globally unique** across all plugins, as a repo rule: it keeps every skill unambiguous in prose and in
any flat alias. CI enforces both the `grv-` prefix and global uniqueness on every PR.

Skill directory names also end in one suffix from the fixed taxonomy (`-writer`, `-run`, `-sync`, ...). The allowed list
lives in `docs/contributing/SKILL-AUTHORING.md` and is enforced as a warning by `.claude/hooks/check-skill-suffix.sh`.

See `docs/contributing/SKILL-AUTHORING.md` for the full authoring reference.
