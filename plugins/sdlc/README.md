# sdlc

The delivery lifecycle as Claude Code skills: from a Product Owner's epic, through a gsd-core
milestone and its phases, to a published release with every Jira ticket closed on evidence. The
skills wrap the open-source [gsd-core](https://github.com/open-gsd/gsd-core) engine and add tracker
tracking, PR discipline and human gates. They never patch gsd-core and never reimplement what it
already does.

Every project coordinate (tracker keys, transition ids, repo, required checks, environments, chat
channel, named owners) comes from `.sdlc/config.json` in the consuming repo. See
[`references/config-contract.md`](references/config-contract.md). No skill hardcodes one.

## Prerequisites

- **gsd-core, installed globally**: `npx @opengsd/gsd-core@latest --claude --global`, at or above
  `engine.gsdCoreMinVersion`. Do not vendor it into the repo. The behaviours the skills rely on, and
  the re-test-on-every-bump rule, are in [`references/gsd-core-assumptions.md`](references/gsd-core-assumptions.md).
- **An Atlassian MCP connector** with Jira access to `tracker.cloudId`. Skills use its current
  operations: `getJiraIssue`, `createJiraIssue` (`contentFormat: "markdown"`), `editJiraIssue`,
  `transitionJiraIssue` (the returned status is the only proof a transition landed),
  `addOrEditJiraIssueComment`, `searchJiraIssuesUsingJql`, and `discover` plus
  `executeRead` / `executeWrite` for anything else. Never guess an operation name; discover it.
- **The connector's server id is installation-specific.** Skill frontmatter lists Atlassian tools as
  `mcp__atlassian__<operation>` (and chat as `mcp__slack__<operation>`). Name the connector `atlassian`
  (and `slack`) in your MCP configuration to get them pre-approved; otherwise extend `allowed-tools`
  locally. A tool missing from `allowed-tools` still works, with a permission prompt.
- `gh` authenticated against `repo.owner`/`repo.name`; a chat connector only if `chat.type` is not `none`.
- `.sdlc/config.json` filled from `templates/project/.sdlc/config.json`.

## Invoking the skills

Plugin skills are namespaced: invoke them as `/sdlc:<skill>` (for example
`/sdlc:phase-run 3`), and skills call each other as `Skill(skill="sdlc:<skill>")`.
Whether a flat `/<skill>` alias also resolves depends on the Claude Code version and has not been
verified; do not rely on it. Bare skill names in this README and in skill prose are names, not
commands.

## Lifecycle order

The intake PR from `milestone-init` has to merge first only on the unattended path:
`epic-run` reads the roadmap from the remote default branch. Interactive `milestone-setup`
runs straight after init in the same tree and branch, and its setup PR carries the intake with it.

```text
epic-writer -> milestone-init
  -> interactive: milestone-setup [-> milestone-sync, milestone-planner, story-update]
       -> (human readies and merges the setup PR) -> milestone-run
     unattended:  (human readies and merges the intake PR) -> epic-run (setup + run, own worktree)
  milestone-run [-> phase-run, phase-complete per phase]
  -> phase-complete per phase still awaiting human UAT, uat-session as needed
  -> (human marks the PR ready) -> phase-review-fix per phase
  -> milestone-review -> (human merges release PR)
  -> milestone-complete [-> learn, docs-sync; readies the close-out PR]
  -> (human merges close-out PR) -> release-close
```

Single tickets outside a milestone go through `story-deliver`, then `release-close` for a patch.

## Skills

| Skill                | What it does                                                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `epic-writer`        | Interviews the PO to create or enrich an Intent-Driven Design Epic (intent, user value, success criteria, out of scope, size) |
| `milestone-init`     | Interactive requirements-and-roadmap intake from an Epic over gsd-core's new-milestone; ships the intake PR                   |
| `milestone-setup`    | One-time kickoff: branch alignment, epic grooming against the code, Story sync, planning, Story enrichment, setup PR          |
| `milestone-sync`     | One Story per phase, Blocks chain, Backlog to Selected, keys written back to ROADMAP.md                                       |
| `milestone-planner`  | Sequential discuss, then planning in dependency-ordered waves                                                                 |
| `milestone-run`      | Runs every pending phase sequentially through phase-run and phase-complete; halts on a blocker                                |
| `epic-run`           | Whole epic unattended in an isolated worktree: setup, then every phase, to a draft PR, with a run ledger                      |
| `milestone-review`   | Cross-phase readiness review of the release PR; READY / NOT READY verdict in the PR body                                      |
| `milestone-complete` | Close-out PR, before the merge: verify gate, learnings, docs refresh, archive, open items, epic decision roll-up              |
| `release-close`      | After the last merge: notes, human-gated Release, chat pointer, evidence-checked per-ticket Done, prune, Epic Done last       |
| `phase-run`          | One phase from zero to draft PR: discuss, plan, execute, ship draft, with Jira tracking                                       |
| `phase-complete`     | Lane A autonomous verify to a passed report; Lane B human UAT verdict (or a dated, human-reasoned waiver)                     |
| `phase-review-fix`   | Post-ready loop: collect review and UAT findings, fix, re-verify, re-review until clean                                       |
| `story-deliver`      | Deliver one ticket as an isolated change: own worktree, branch and PR; escalates to phase planning when too big               |
| `story-update`       | Enrich a Story with post-planning detail (points, estimate, description) from plans or git state                              |
| `uat-session`        | Bootstrap a UAT session against a PR's environment with paired positive/negative checks; hands bugs off, never fixes inline   |
| `learn`              | Extract dated learnings from any scope; promote proposed instruction-file changes through a human gate                        |
| `docs-sync`          | One entry point for "make the docs true again": code-derived docs via gsd-core, knowledge docs to the configured docs space   |

## Gates that are not configurable

An agent never merges a PR, never marks a PR ready (the one exception is
`milestone-complete` readying the close-out PR as its last step), never deletes a remote or
unmerged branch without a human's explicit yes, never marks a ticket Approved, never records a human UAT verdict, never
writes a deferral or waiver reason a human did not give, never publishes a Release or posts to chat
without confirmation in the current session, and never creates, edits or bypasses a repository
ruleset. Done is written only by `release-close`, on explicit per-ticket human selection, as the
terminal act. Transitions are always by id from config, never by display name. Every ticket an agent
writes to carries `tracker.labels.provenance` permanently (labels are read-modify-write; the label is
never removed). These rules are advice the agent follows; the consuming repo should back each one with
a control outside the agent's write access (branch protection, required reviews, rulesets).

## Not ported

The source workflow also had `design-stage` (mockup registration feeding a UI design gate) and
`visual-verify` (live computed-style evidence capture). Both were specific to one product's UI and
design system, so they are not part of this plugin. A consuming repo that needs a design gate can add
its own skill and have `phase-run` honour it.
