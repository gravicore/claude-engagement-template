# Skill Authoring Guide

This is the canonical reference for authoring Claude Code plugins and skills in an
engagement marketplace repository (an instance of the engagement template). A new contributor should not need to read any
other file to create a valid, CI-passing skill.

## What Is a Skill

A skill is a Claude Code prompt (SKILL.md) packaged inside a plugin directory. Each skill
does one thing well and produces one output type. Skills in this repo are specific to
the engagement the instance serves - workflow automation, compliance helpers, and engagement-scoped tooling.

## Plugin Structure

Plugins you author for this engagement live at `plugins/{{PREFIX}}-<plugin-name>/` (the engagement prefix is in
`.engagement.json`; the generic `sdlc` plugin shipped by the template is the unprefixed exception). Layout:

```text
plugins/{{PREFIX}}-<plugin-name>/
|-- .claude-plugin/
|   `-- plugin.json          # required manifest
|-- skills/
|   `-- {{PREFIX}}-<action>/     # skill names MUST start with the engagement prefix
|       |-- SKILL.md         # the prompt - description + allowed-tools frontmatter
|       `-- tests.yaml       # behavioral test fixtures (full skills only - stubs exempt)
`-- references/              # optional - static files the skill reads at runtime
    `-- *.md
```

## plugin.json Required Fields

Every plugin must have a `.claude-plugin/plugin.json` with exactly these fields:

```json
{
  "name": "{{PREFIX}}-<plugin-name>",
  "description": "One sentence.",
  "version": "0.1.0",
  "author": { "name": "{{ENGAGEMENT_NAME}}" },
  "homepage": "https://github.com/{{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}",
  "repository": "https://github.com/{{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}",
  "license": "UNLICENSED"
}
```

## marketplace.json Entry Format

Every plugin must have a corresponding entry in `.claude-plugin/marketplace.json`:

```json
{
  "name": "{{PREFIX}}-<plugin-name>",
  "description": "One sentence.",
  "source": "./plugins/{{PREFIX}}-<plugin-name>",
  "version": "0.1.0"
}
```

## Skill Naming Rules

Every skill directory in an engagement plugin must start with the engagement prefix:

```text
plugins/{{PREFIX}}-<plugin-name>/skills/{{PREFIX}}-<action>/
```

For example, with prefix `acme`: `plugins/acme-servicing/skills/acme-loan-summary/`. Skills in a generic plugin (listed
in `.engagement.json` `genericPlugins`, today only `sdlc`) carry no prefix.

**Uniqueness:** Skill names must be globally unique across ALL plugins in the marketplace, generic ones included.
CI enforces the prefix rule and global uniqueness on every PR (`scripts/check-naming.py`).

**`name:` is required and must equal the directory name.** Claude Code treats `name` as optional and defaults it to the
directory name; this repo requires it so the two can never diverge, and the `validate-frontmatter` workflow fails a
SKILL.md whose `name` is missing or differs from its directory.

**Invocation.** Plugin skills are namespaced: invoke `/<plugin>:<skill>`, for example `/sdlc:phase-run`. A flat
`/phase-run` alias is not documented for plugin skills in general (the skills docs describe a bare alias only
conditionally, for a skill that sets `name:`, and only when no other command uses the name), so do not rely on it:
UNVERIFIED - confirm against current docs. The repo rule that skill names are globally unique still holds.

## SKILL.md Frontmatter

Every skill begins with YAML frontmatter declaring its name, trigger description and allowed tools:

```yaml
---
name: {{PREFIX}}-<action>
description: >
  One sentence trigger description. Include keywords users would naturally say.
  Triggers on: "phrase 1", "phrase 2", "phrase 3".
allowed-tools: ["Read", "Write", "Edit", "Bash"]
---
```

Stubs use `allowed-tools: []` and the body must say "This skill is not yet implemented."
See [STUB-FORMAT.md](./STUB-FORMAT.md) for the exact template.

## Skill Naming Convention

All skill names use a fixed suffix system: the last hyphen-separated word of the directory name (or the whole name, for
a one-word generic skill such as `learn`) must come from the table below. Using any other suffix requires amending this doc, the allowed list in
`.claude/hooks/check-skill-suffix.sh`, and `.claude/docs/naming-convention.md` together. The hook warns but does not
block; CI does not check suffixes.

Artifact suffixes (the skill produces or critiques a document; examples use the illustrative prefix `acme`):

| Suffix       | Use Case                                                | Examples                         |
| ------------ | ------------------------------------------------------- | -------------------------------- |
| `-writer`    | Structured doc generated from inputs                    | `acme-sow-writer`, `epic-writer` |
| `-brief`     | Short executive summary from inputs                     | `acme-status-brief`              |
| `-summary`   | Compression of existing content                         | `acme-call-summary`              |
| `-review`    | Critique output - does not draft                        | `acme-compliance-review`         |
| `-notes`     | Structured notes from a session                         | `acme-meeting-notes`             |
| `-reference` | Read-only Q&A surfacing info from references            | `acme-policy-reference`          |
| `-apply`     | Text-only transformation applying a style/voice/policy  | `acme-template-apply`            |
| `-release`   | Drafts a structured release-style document from a brief | `acme-press-release`             |

Lifecycle suffixes (the skill drives a step of a delivery workflow and may call tools, write files, or update trackers):

| Suffix      | Use Case                                             | Examples                      |
| ----------- | ---------------------------------------------------- | ----------------------------- |
| `-run`      | Drives a unit of work end to end                     | `phase-run`, `milestone-run`  |
| `-init`     | One-time intake that creates the starting artifacts  | `milestone-init`              |
| `-setup`    | One-time kickoff or bootstrap of an environment/unit | `milestone-setup`             |
| `-sync`     | Reconciles two systems or artifact sets              | `milestone-sync`, `docs-sync` |
| `-planner`  | Produces plans for pending work                      | `milestone-planner`           |
| `-complete` | Takes a unit of work through its completion gates    | `phase-complete`              |
| `-close`    | Closes out after a release or merge                  | `release-close`               |
| `-deliver`  | Delivers one ticket as an engineering change         | `story-deliver`               |
| `-update`   | Enriches an existing record with new detail          | `story-update`                |
| `-session`  | Bootstraps and supervises an interactive session     | `uat-session`                 |
| `-fix`      | Collects findings and drives a fix loop              | `phase-review-fix`            |
| `-learn`    | Extracts and promotes learnings                      | `learn`                       |

## Authoring Rules

| Rule                | Requirement                                                                                                                 |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| One output type     | Each skill produces exactly one type of artifact                                                                            |
| Draft vs. review    | Skills named `-writer` or `-brief` draft only; `-review` critiques only; lifecycle suffixes may act, within `allowed-tools` |
| Stub honesty        | Stubs must have `allowed-tools: []` AND "not yet implemented" in the body                                                   |
| Length limit        | Non-stub SKILL.md files must not exceed 120 lines                                                                           |
| Testing requirement | Full skills must have a sibling `tests.yaml` with 3-5 test cases; stubs are exempt                                          |
| No PII in skills    | Never hardcode customer names, personal identifiers, or account numbers - use references/                                   |

## Confidentiality Rules

| Rule                                      | Enforcement                                                                                                           |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| No client names outside `references/`     | CI fails the PR (enforcement); a Claude Code PreToolUse hook also refuses the write locally (convenience, bypassable) |
| No hardcoded secrets, API keys, or tokens | CI runs gitleaks on every PR                                                                                          |
| No customer PII in skill prompts          | Code review + gitleaks                                                                                                |
| `license` is `Apache-2.0` or `UNLICENSED` | Generic layer is open source; engagement-specific plugins stay proprietary                                            |

## Versioning

- Bump `plugin.json` version and `marketplace.json` version together in the same PR. Claude Code uses the `plugin.json`
  value when both are set and `claude plugin validate` warns when they differ; CI (version drift check) fails the PR
  when they differ, so the marketplace entry can never silently disagree
- Use semver: `0.x.y` while pre-stable, `1.0.0` when battle-tested
- Manual version bumps are correct at this scale

## Skill Testing

Full skills (non-stubs) must ship with a `tests.yaml` fixture file alongside `SKILL.md`.
Stubs are exempt. `mise run validate` enforces this.

The fixture format is: the skill as the system message, the test input as the user turn.

```yaml
prompts:
  - label: skill-chat
    raw: '[{"role":"system","content":{{ skill | dump }}},{"role":"user","content":{{ user_input | dump }}}]'

defaultTest:
  vars:
    skill: file://SKILL.md
```

See [`SKILL-TESTING.md`](./SKILL-TESTING.md) for the complete fixture, why it is shaped this way, and how to run tests
locally.
