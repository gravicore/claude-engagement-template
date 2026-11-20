## What

<!-- One sentence: what does this PR add or change? -->

## Why

<!-- What problem does it solve, or what capability does it add? -->

## Checklist

- [ ] Skill description triggers correctly (tested in Claude Code or Cowork)
- [ ] New engagement plugins and skills are named `{{PREFIX}}-<name>` (generic plugins such as `sdlc` excepted), and skill names are globally unique
- [ ] `references/` files are internal-only - no client names, no secrets, no PII
- [ ] `marketplace.json` version bumped if adding a new plugin
- [ ] `plugin.json` version matches `marketplace.json` entry
- [ ] `license` in plugin.json is correct: `UNLICENSED` for engagement-specific plugins, `Apache-2.0` only for the generic layer
- [ ] Tested on at least one surface (Code or Cowork)

## Surface tested

- [ ] Claude Code
- [ ] Claude Cowork
- [ ] Claude Chat (skills only)

## Notes for reviewer

<!-- Anything the approver should know before merging -->
