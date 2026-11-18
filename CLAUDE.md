@AGENTS.md

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<!-- template:begin -->

> **Template state.** Placeholder tokens still present means this is the engagement template. Do not substitute them
> by hand; a human runs `scripts/init-engagement.sh` (see `TEMPLATE.md`), which also removes this block.

<!-- template:end -->

## Naming convention

@.claude/docs/naming-convention.md

## Plugin conventions

Plugin authoring: `docs/contributing/SKILL-AUTHORING.md`. A rule that applies only to one plugin's files goes in `.claude/rules/<plugin>.md` with a `paths:` list in its frontmatter (for example `plugins/sdlc/**`), so it loads only when Claude works on matching files. No such rule exists yet, so the directory does not either: Claude Code loads every `.md` file under `.claude/rules/` that has no `paths:` field in every session, so a placeholder README there would become an always-on rule.

## Project

**{{ENGAGEMENT_SLUG}} - {{ENGAGEMENT_NAME}} Plugin Marketplace**

The engagement-tier Claude plugin marketplace for {{ENGAGEMENT_NAME}}. It hosts the plugins, skills, and automations for
this engagement. It is engagement-internal: never public, never promoted to another marketplace tier without an
explicit tier decision.

### Constraints

- **Compliance**: No customer PII or account identifiers in skill prompts. Regimes in scope: {{COMPLIANCE_REGIMES}}
- **Visibility**: Engagement-internal forever - org-private on GitHub, never public, no public npm
- **Naming**: Generic plugin `plugins/sdlc/` unprefixed; engagement plugin dirs `plugins/{{PREFIX}}-<slug>/` with skills `{{PREFIX}}-<action>`; branch prefix `gsd/`; install id `{{MARKETPLACE_NAME}}`
- **CI**: The eight required status checks (listed in `AGENTS.md`) must pass on every PR; the CI workflow skips pushes that touch only planning or docs files, never PRs
- **Merge policy**: Squash-merge only, conventional commit on main, branches auto-delete

## Technology Stack

### Plugin Manifest Format

| Artifact             | Format                                   | Location                                      |
| -------------------- | ---------------------------------------- | --------------------------------------------- |
| Plugin manifest      | `plugin.json`                            | `plugins/<plugin>/.claude-plugin/plugin.json` |
| Marketplace registry | `marketplace.json`                       | `.claude-plugin/marketplace.json`             |
| Naming config        | `.engagement.json`                       | repo root                                     |
| Skill definition     | YAML frontmatter + Markdown (`SKILL.md`) | `plugins/<plugin>/skills/<skill>/SKILL.md`    |
| Hook config          | `hooks/hooks.json`                       | `plugins/<plugin>/hooks/hooks.json`           |
| MCP config           | `.mcp.json`                              | `plugins/<plugin>/.mcp.json`                  |

### Validation Toolchain

| Tool                                               | Purpose                                             |
| -------------------------------------------------- | --------------------------------------------------- |
| `jsonschema` (Python 4.20.0)                       | Validate `plugin.json` and `marketplace-entry.json` |
| `claude plugin validate` (CLI 2.1.133)             | Official plugin invariant checks                    |
| `anthropics/claude-plugins-community` (SHA-pinned) | CI reusable actions for validate and scan           |
| `gitleaks` 8.18.4                                  | Secret scanning on git history                      |
| `yamllint` 1.35.1                                  | Strict YAML lint on `.github/workflows/`            |
| `markdownlint-cli`                                 | Lint `SKILL.md` files                               |
| `prettier` 3.8.3                                   | Format Markdown, JSON, YAML, shell                  |
| `shfmt` 3.13.1                                     | Format shell scripts                                |
| `shellcheck` 0.11.0                                | Lint shell scripts                                  |
| `promptfoo` (npx)                                  | LLM skill quality testing (`mise run test`)         |

### mise tasks

- `mise run setup` - installs tools, sets `git config core.hooksPath .github/hooks`
- `mise run lint` - yamllint + markdownlint + shellcheck
- `mise run format` - prettier write + shfmt write (auto-fix)
- `mise run format-check` - mirrors CI, no writes
- `mise run validate` - schema validation + version drift + client name isolation + stub/skill checks + naming (`scripts/check-naming.py`)
- `mise run test` - promptfoo skill quality tests (live API calls; pre-CI only)

## Claude Code hooks

`.claude/settings.json` wires the scripts in `.claude/hooks/`. Hook input is JSON on stdin (`tool_input.file_path`, and
`content` or `new_string` for the client-name guard); the scripts parse it with `jq`, or `python3` when `jq` is absent,
and filter on the path themselves. Hook timeouts are in seconds.

| Event       | Matcher       | Script                                         | Effect                                                                      |
| ----------- | ------------- | ---------------------------------------------- | --------------------------------------------------------------------------- |
| PreToolUse  | `Edit\|Write` | `block-client-names.sh`                        | Exit 2 refuses a write that adds a `.clients` name outside `references/`    |
| PostToolUse | `Edit\|Write` | `post-edit.sh` (runs the steps below in order) | Exit 2 shows the message to Claude; the write has already happened          |
|             |               | `format-file.sh`, `lint-yaml.sh`               | Prettier on md/json/yml/yaml; yamllint on `.github/workflows/`              |
|             |               | `check-stub-format.sh`                         | Stub SKILL.md must say "not yet implemented"                                |
|             |               | `check-skill-suffix.sh`                        | Skill in an engagement plugin needs the prefix; any skill an allowed suffix |
|             |               | `regen-template-index.py`                      | Rebuilds `index.md` for a `templates/` directory                            |

These are a local convenience. CI is the enforcement point: Bash redirects and other tools bypass the PreToolUse guard,
and a contributor not using Claude Code never runs any of it. See `.claude/docs/VALIDATION.md`.
