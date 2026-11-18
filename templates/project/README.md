# Project Starter Files

Starter instruction files and config for a client application repository that adopts the
`sdlc` delivery process. Nothing here is installed automatically: you copy these files into
the application repo once, fill them in, and from then on they belong to that repo.

| File                      | Goes to                       | Purpose                                                                                        |
| ------------------------- | ----------------------------- | ---------------------------------------------------------------------------------------------- |
| `AGENTS.md`               | repo root                     | Tool-agnostic project instructions: review, verification, security, tracker and release rules  |
| `CLAUDE.md`               | repo root                     | Claude Code specifics; includes `AGENTS.md` and maps bare engine commands to `sdlc:*` wrappers |
| `.sdlc/config.json`       | `.sdlc/config.json`           | Project coordinates every `sdlc` skill reads                                                   |
| `ONBOARDING-CHECKLIST.md` | `docs/` or the first setup PR | Repo-readiness sign-off for the lead engineer                                                  |

## Adopt in seven steps

1. **Copy the files.** From this directory into the application repo, keeping the paths above.
   If the repo already has an `AGENTS.md` or `CLAUDE.md`, merge by hand: keep its project rules,
   add the process sections from the starter.
2. **Fill every `<!-- FILL: ... -->` block** in `AGENTS.md` and `CLAUDE.md`. Each block says what
   to write; `grep -n "FILL:" AGENTS.md CLAUDE.md` lists what is left. The starter rules outside
   the FILL blocks are the process. Remove one only by decision, in a commit that says why.
3. **Write `.sdlc/config.json`.** Replace every synthetic value (`PROJ`, `example-org`,
   `https://staging.example.com`, the zeroed ids). Every key is required; an unused capability
   takes `none`, `null` or `[]`, never a missing key. Transition values are ids, not display
   names. Validate against the plugin's schema:

   ```bash
   python3 -m pip install jsonschema
   python3 -c "import json, jsonschema; jsonschema.validate(json.load(open('.sdlc/config.json')), json.load(open('<plugin-dir>/references/sdlc-config.schema.json'))); print('valid')"
   ```

   The file holds coordinates only. Never put a token, password or connection string in it.

4. **Install gsd-core globally** on every machine that will run the skills, at or above
   `engine.gsdCoreMinVersion`:

   ```bash
   npx @opengsd/gsd-core@latest --claude --global
   ```

   This installs to `~/.claude/gsd-core/` (repository `github.com/open-gsd/gsd-core`). Verified on
   1.19.0; re-check on newer versions. Do not vendor or patch it in the application repo.

5. **Add the marketplace and install the plugin** in Claude Code:

   ```text
   /plugin marketplace add <org>/<engagement-marketplace-repo>
   /plugin install sdlc@<marketplace-name>
   ```

   Claude Code namespaces plugin skills as `/<plugin>:<skill>`, so type `/sdlc:epic-writer`.
   This guide writes that full form throughout; a flat `/epic-writer` alias is UNVERIFIED -
   confirm against current docs before relying on it.

6. **Work through `ONBOARDING-CHECKLIST.md`.** The lead engineer signs it before the first
   agent-delivered phase. An item that cannot be met yet is recorded as a named gap, not skipped.
7. **Run a first epic.** Have the product owner create it with `/sdlc:epic-writer`, then turn it
   into a milestone. Two PRs, each merged by a human before the next step, because later skills
   read the earlier PR's artifacts from `main`:

   ```text
   /sdlc:milestone-init <epic-key>     interactive intake; opens the intake PR
   (a human reviews and merges the intake PR)
   /sdlc:milestone-setup               branch, groom the epic, sync stories, plan every phase; opens the setup PR
   (a human reviews and merges the setup PR)
   ```

   Then deliver phases with `/sdlc:phase-run <N>` and `/sdlc:phase-complete <N>`. The unattended
   alternative is `/sdlc:epic-run <epic-key>` after the intake PR has merged: it runs setup and every
   phase on one worktree with no mid-run merge. The full lifecycle is the table in `AGENTS.md`
   under `# Delivery Workflow`.

## What stays human

Merging a PR, recording UAT sign-off, closing a ticket, publishing a release and changing a
ruleset always wait for a named person. No config key turns these off.

## Keeping the files current

- A rule learned the hard way goes into `AGENTS.md` (or `CLAUDE.md` if it exists only because of
  the tool) as a rule plus a one-line why. `/sdlc:learn promote` proposes these after each release.
- When a rule is superseded, rewrite every summary of it, not just the body.
- On a gsd-core version bump, re-test the list in the plugin's
  `references/gsd-core-assumptions.md`, then raise `engine.gsdCoreMinVersion`.
- These starters are not re-synced from the template. Compare against a newer template by hand
  when the process changes, and adopt changes through a reviewed PR.
