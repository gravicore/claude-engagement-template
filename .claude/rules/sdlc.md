---
paths:
  - "plugins/sdlc/**"
---

# Authoring rules for the sdlc plugin

- `sdlc` is the generic layer. Nothing engagement-specific goes in it: no client name, no project key, no repo name.
  Every project coordinate is read from `.sdlc/config.json` in the consuming repo
  (`plugins/sdlc/references/config-contract.md`).
- Skill names carry no prefix here. Skills call each other as `Skill(skill="sdlc:<skill>")`.
- The gates listed under "Gates that are not configurable" in `plugins/sdlc/README.md` are never made optional by a
  flag, a config key or an `--autonomous` mode.
- A skill wraps gsd-core; it never patches it and never reimplements what it already does. A new reliance on gsd-core
  behaviour is recorded in `plugins/sdlc/references/gsd-core-assumptions.md`.
- Every full skill has a sibling `tests.yaml` that exercises its main gate.
