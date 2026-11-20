# Naming Convention

Two layers of plugins live in this repo, and they are named differently:

- **Generic layer** - plugins shipped by the template, unprefixed. Today that is one plugin, `sdlc`, whose skills are
  plain action names (`phase-run`, `release-close`, ...).
- **Engagement layer** - plugins and skills authored for this engagement. Both carry the engagement prefix, a short code
  chosen at init and recorded in the root `.engagement.json`.

`.engagement.json` is the single source the naming checks read: `prefix` (the engagement code) and `genericPlugins`
(the plugin directories that carry no prefix).

## Plugin names

- A plugin directory is valid when it is listed in `genericPlugins`, or when it starts with the engagement prefix:
  `plugins/{{PREFIX}}-<name>/`.
- `plugin.json` `name` equals the directory name, and the `marketplace.json` entry `name` equals its source directory.
- `schemas/plugin.json` only requires lowercase kebab-case (`^[a-z][a-z0-9-]*$`); the prefix rule lives in
  `scripts/check-naming.py`.

Example with prefix `acme`: the generic plugin is `plugins/sdlc/`, an engagement plugin is `plugins/acme-servicing/`.
Install with `<plugin>@<marketplace>`, for example:

```text
/plugin install sdlc@{{MARKETPLACE_NAME}}
/plugin install {{PREFIX}}-<name>@{{MARKETPLACE_NAME}}
```

The marketplace id defaults to the engagement prefix.

## Skill names

- Skills in a generic plugin carry no prefix: `plugins/sdlc/skills/phase-run/`.
- Skills in an engagement plugin start with the prefix: `plugins/{{PREFIX}}-<plugin>/skills/{{PREFIX}}-<action>/`. With
  prefix `acme`, that is `plugins/acme-servicing/skills/acme-loan-summary/`.
- `name:` in SKILL.md equals the directory name.

Invocation is namespaced as `/<plugin>:<skill>`: `/sdlc:phase-run` for the generic layer, and with prefix `acme`,
`/acme-servicing:acme-loan-summary` for an engagement skill. Skills call each other the same way, for example
`Skill(skill="sdlc:phase-run")`. Claude Code namespaces plugin skills as `/<plugin-name>:<skill-name>` (skills docs,
checked 2026-11-18); that is the form to write in documentation and prompts. The same docs describe a bare `/<name>`
alias for a plugin skill only conditionally (a skill that sets `name:`, when no other command uses the name), so a flat
`/phase-run` alias is unverified: confirm against current docs before depending on it.

Skill names stay **globally unique** across all plugins, as a repo rule: it keeps every skill unambiguous in prose and in
any flat alias. CI enforces the plugin and skill prefix rule and global uniqueness on every PR, through
`scripts/check-naming.py`; the pre-commit hook and `mise run validate` run the same script.

Skill directory names also end in one suffix from the fixed taxonomy (`-writer`, `-run`, `-sync`, ...); a generic skill
may be the suffix word alone (`learn`). The allowed list lives in `docs/contributing/SKILL-AUTHORING.md` and is
enforced as a warning by `.claude/hooks/check-skill-suffix.sh`.

See `docs/contributing/SKILL-AUTHORING.md` for the full authoring reference.
