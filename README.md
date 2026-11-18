<!-- template:begin -->

# Claude engagement template

A client-neutral template for an **engagement-tier Claude Code plugin marketplace**. Gravicore creates one instance of
this repo per client engagement; each instance becomes that client's centralized skills and agent repository.

An instance may be hosted in Gravicore's GitHub org or in the client's own org, with Gravicore contributing by pull
request. `TEMPLATE.md` documents both options without picking one.

## What you get

- `.claude-plugin/marketplace.json` - marketplace registry, pre-registering the `grv-sdlc` delivery-lifecycle plugin
- `plugins/` - plugin directories (`grv-sdlc` ships with the template)
- `templates/` - project and document templates used by skills
- `docs/enablement/` - rollout and client-org setup guidance
- `docs/contributing/` - skill and plugin authoring and testing guides
- `schemas/` - JSON schemas for `plugin.json` and marketplace entries
- `.github/` - CI workflows, git hooks, branch-protection reference, PR template, security-scan policy
- `.claude/` - Claude Code hooks and docs (client-name guard, skill-suffix and stub checks)
- `scripts/init-engagement.sh` - one-time script that fills in the placeholders for a new instance

## Create an instance

See [TEMPLATE.md](TEMPLATE.md). In short: create a repo from this template, run `scripts/init-engagement.sh` with the
engagement's name, slug, org, marketplace id, and compliance regimes, review the diff, then apply branch protection
(a human act).

## Placeholders

Five double-curly-brace tokens parameterize the template: ENGAGEMENT_NAME, ENGAGEMENT_SLUG, GITHUB_ORG,
MARKETPLACE_NAME, and COMPLIANCE_REGIMES. The init script replaces every occurrence and removes the template-only
blocks (including this section and the title above) from `README.md`, `AGENTS.md`, and `CLAUDE.md`. Until init runs,
CI skips the checks that cannot pass with unresolved placeholders.

## Status

Version 0.1.0. The `grv-sdlc` skills were generalized from a single-product original and pass the structural checks
in this repo, but none has yet been run end to end from this template, and the `tests.yaml` suites have only been
exercised with promptfoo's echo provider, not against a live model. Treat the first engagement as the hardening
pass. Local `mise run validate` needs the Python `jsonschema` package importable; CI installs it.

## License

The template scaffold and the `grv-sdlc` plugin are open source under the Apache License 2.0 (see `LICENSE` and
`NOTICE`). An instance created from this template is private to its engagement; plugins added to an instance carry
the license stated in their own `plugin.json` (`UNLICENSED` for engagement-specific work).

<!-- template:end -->

# {{ENGAGEMENT_SLUG}}

Gravicore's engagement-tier Claude plugin marketplace for **{{ENGAGEMENT_NAME}}**. Contains the plugins and skills
specific to this engagement. **Never goes public.**

## Install

In Claude Code or Claude Cowork:

```text
/plugin marketplace add {{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}
/plugin install <plugin>@{{MARKETPLACE_NAME}}
```

## Three-tier model

This repo sits in the engagement tier of Gravicore's three-tier Claude marketplace design:

- **Public tier** - plugins destined for public release.
- **Corporate tier** - plugins that stay internal to Gravicore forever.
- **Engagement tier (this repo)** - `{{MARKETPLACE_NAME}}`: {{ENGAGEMENT_NAME}} engagement only.

The other two tiers are maintained by Gravicore, are not part of this repo, and need not be reachable from it.

This instance is hosted in `{{GITHUB_ORG}}`, which is either Gravicore's org or the client's own org (in which case
Gravicore contributes by pull request).

## Three-surface compatibility

A single plugin entry serves three Claude surfaces with no per-surface forking:

- **Claude Code** - full plugin (manifest + skills + hooks + MCP)
- **Claude Cowork** - same plugin format, sandboxed shell + curated MCP
- **Claude Chat** - skills only (SKILL.md format), via Chat's skill upload/sync

## Contents

- `.claude-plugin/marketplace.json` - Claude marketplace registry
- `plugins/` - one directory per plugin
- `templates/` - project and document templates used by skills
- `docs/enablement/` - rollout and client-org setup guidance
- `docs/contributing/` - skill and plugin authoring and testing guides
- `schemas/` - JSON schemas for `plugin.json` and `marketplace-entry.json`
- `scripts/` - repo tooling
- `TEMPLATE.md` - how this repo was created from the template and how to pull template updates

## Compliance note

Skills in this repo may handle data subject to the regimes listed in {{COMPLIANCE_REGIMES}}. Never hardcode customer
PII or account identifiers into skill prompts - keep sensitive references in `plugins/<name>/references/` only.
