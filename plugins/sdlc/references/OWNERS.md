# sdlc Ownership

**Owner team:** @{{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}-maintainers
**Audience:** every engineering team that delivers through the lifecycle skills
**Chat channel:** not set yet
**Skill requests:** open a GitHub issue in this repo with the label `plugin:sdlc` and the title prefix `[skill-request]`
**Bug reports:** open a GitHub issue in this repo with the label `plugin:sdlc`

## What the owner decides

- Reviews every pull request that touches `plugins/sdlc/` (CODEOWNERS routes it).
- Approves instruction changes proposed by `sdlc:learn promote` for this plugin.
- Decides when a template update for the generic layer is pulled into this instance (see `TEMPLATE.md`).

`sdlc` is the generic layer shipped by the template. A change that is specific to this engagement belongs in an
engagement plugin, not here: see `docs/PLUGIN-TAXONOMY.md`.
