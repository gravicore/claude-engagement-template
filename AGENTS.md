---
title: Agent Instructions - {{ENGAGEMENT_SLUG}}
scope: engagement
---

# Agent Instructions - {{ENGAGEMENT_SLUG}}

Cross-tool source of truth for agent behavior in this repo. Claude-specific nuance lives in `CLAUDE.md` (which imports this file).

<!-- template:begin -->

> **Template state.** If the placeholder tokens (double curly braces around ENGAGEMENT_NAME, ENGAGEMENT_SLUG,
> GITHUB_ORG, MARKETPLACE_NAME, COMPLIANCE_REGIMES, PREFIX) are still present anywhere in this repo, you are in the
> template, not in an engagement instance. Never fill them in by hand. A human runs `scripts/init-engagement.sh`
> once per instance (see `TEMPLATE.md`). That script also removes this block.

<!-- template:end -->

## What this repo is

`{{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}` is the engagement-tier Claude plugin marketplace for the {{ENGAGEMENT_NAME}} engagement. It is the engagement's centralized skills and agent repository: plugins, skills, and automations specific to this engagement. It is private to the engagement and never goes public.

Install identifier: `{{MARKETPLACE_NAME}}`

```text
/plugin marketplace add {{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}
/plugin install <plugin-name>@{{MARKETPLACE_NAME}}
```

### Hosting

An instance of this repo lives in one of two places. The choice is made per engagement and does not change anything else in this file.

- **Consultancy org.** The maintaining consultancy hosts and maintains the repo; the client is granted read access to install from it.
- **Client org.** The client hosts the repo in its own GitHub org; the maintaining consultancy contributes by pull request and the client controls access and branch protection.

`{{GITHUB_ORG}}` is whichever org hosts this instance; that org's administrators are the instance owner.

## Three-tier model

This repo is produced from the engagement template. Each instance is the engagement tier of a three-tier Claude marketplace design:

- **Public tier** - plugins destined for public release.
- **Corporate tier** - plugins that stay internal to the maintaining consultancy.
- **Engagement tier (this repo)** - `{{MARKETPLACE_NAME}}`: {{ENGAGEMENT_NAME}} engagement only.

Tier decision rule: if the skill is specific to {{ENGAGEMENT_NAME}}, it belongs in this repo. If it is internal to the maintaining consultancy and not specific to this engagement, it belongs in the corporate tier. The other two tiers are maintained by the consultancy, are not part of this repo, and need not be reachable from a client-hosted instance.

## Three-surface compatibility

A single plugin entry serves three Claude surfaces with no per-surface forking:

- **Claude Code** - full plugin (manifest + skills + hooks + MCP)
- **Claude Cowork** - same plugin format, sandboxed shell + curated MCP
- **Claude Chat** - skills only (SKILL.md format)

## Repo layout

Root files and top-level directories are described in the root `_index.json` - read it on entry. Per-plugin layout: one directory per plugin under `plugins/` - the generic `sdlc` plugin, and engagement plugins named `plugins/{{PREFIX}}-<slug>/`. Do not maintain a file listing here; register new root entries in `_index.json`.

## Compliance

Skills in this repo may handle data subject to the regimes listed in {{COMPLIANCE_REGIMES}}. Flag compliance implications but do not give legal advice - escalate to the engagement's compliance contact or counsel. Never hardcode customer PII or account identifiers in skill prompts - keep sensitive references in `references/` only.

## Org standards (optional)

If the hosting organization maintains engineering standards, link or vendor them wherever suits that org and note the location here. Nothing in this repo depends on them. Without standards, the conventions in `docs/contributing/` and `.claude/docs/` apply.

## Branch naming

All branches use the `gsd/` prefix. Type info belongs in the PR title, not the branch name.

| Branch                  | Means                  |
| ----------------------- | ---------------------- |
| `gsd/p1-<short-slug>`   | Phase 1                |
| `gsd/m1.0-release-prep` | Milestone wrap-up      |
| `gsd/spike-<slug>`      | Time-boxed exploration |
| `gsd/<short-slug>`      | Quick / ad-hoc work    |

Slug portion under 32 chars. `.github/hooks/pre-push` blocks pushes from branches that don't match `gsd/`, `jira/`, or `dependabot/` prefixes.

## Merge policy

Squash-merge only. Clean conventional commit (`feat(plugin): ...`, `fix(ci): ...`, `chore: ...`). Branches auto-delete on merge.

Branch protection and rulesets are applied and changed by a human repo admin, never by an agent. A blocked push or failing required check is a finding to report, not an obstacle to clear. `.github/branch-protection.json` is a reference copy only.

## CI checks

Eight required status checks, all jobs of `validate.yml`, run on every pull request to `main`: Validate plugin integrity, Scan secrets, Check CODEOWNERS entries, Lint YAML workflows, Lint SKILL.md files, Format check, Lint shell scripts, Validate plugins (claude CLI). `validate-frontmatter.yml` and `scan-plugins.yml` are path-filtered and run only when matching files change, so they are not required (a required check that never runs blocks the PR). Pushes touching only `.planning/**` or `docs/**` skip `validate.yml`; pull requests do not. A human repo admin applies the list as branch protection (`.github/branch-protection.json` is the reference copy). Full descriptions in `.claude/docs/VALIDATION.md`.

## Local hooks and CI

The Claude Code hooks in `.claude/settings.json` are a fast local guard, not the control: a PreToolUse hook refuses an Edit or Write that would put a name from `.clients` outside `references/`, and PostToolUse hooks format and lint what was written. Bash redirects and other tools bypass them, and a contributor not using Claude Code never runs them. CI is the enforcement point.

## Skill naming

The generic `sdlc` plugin and its skills carry no prefix (`/sdlc:phase-run`). Engagement plugins and their skills carry the engagement prefix from `.engagement.json`: `{{PREFIX}}-<name>` for a plugin, `{{PREFIX}}-<action>` for a skill. CI enforces this and global skill-name uniqueness through `scripts/check-naming.py`. The last word of a skill name is drawn from a fixed suffix list kept in sync across `.claude/hooks/check-skill-suffix.sh` and `docs/contributing/SKILL-AUTHORING.md`. See that guide before adding a suffix.

## Local validation

First-time setup: `mise run setup`. Pre-PR: `mise run lint && mise run validate`. Format: `mise run format` (auto-writes; run before pushing). LLM tests (makes API calls): `mise run test`.

## GSD workflow

> **STOP - branch must exist before any file changes.**
> Before touching a single file for any phase, verify the current branch is NOT `main`.
> If it is, create the phase branch first: `git checkout -b gsd/p<phase-num>-<slug>`.

> **Immediately after creating the branch - open the draft PR.**
> If `.planning/config.json` sets `draft_pr_on_start: true`, push the branch and run `gh pr create --draft` before spawning any executor agents.

- Plan before executing: run a plan command before starting work on any phase.
- Check `.planning/STATE.md` first when it exists.
- Push per wave, not per phase - so CI runs throughout execution.

## First-run check

On every new session, verify the dev toolchain is wired before doing anything else:

```sh
command -v mise >/dev/null 2>&1 && git config core.hooksPath | grep -q '.github/hooks'
```

If it fails, run `mise run setup` without asking. Do not proceed until `git config core.hooksPath` prints `.github/hooks`.
