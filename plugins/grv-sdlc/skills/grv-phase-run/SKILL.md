---
name: grv-phase-run
description: >
  Drive one GSD phase from zero to a draft PR with tracker tracking throughout: discuss, design
  gate, UI spec, plan, plan-quality gate, execute, draft PR. Skips stages whose artifacts already
  exist and runs each stage on its own (never gsd-core's --auto chaining). Never merges.
  Triggers on: "run phase N", "phase run", "start phase", "grv-phase-run".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Read
  - Edit
  - Write
  - Bash
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__atlassianUserInfo
  - mcp__atlassian__discover
  - mcp__atlassian__executeRead
---

# grv-phase-run

One phase from zero to a draft PR. Read `.grv/sdlc.json` first and stop, naming the key, if a
required key is missing. Shared rules: `../../references/pr-and-review-conventions.md` (gates,
tracker writes, PRs, branch deletion; path relative to this skill's directory). Engine behaviour:
`../../references/gsd-core-assumptions.md`. Gate criteria: `../../references/phase-gates.md`.

Phase branches are cut from `{config: repo.defaultBranch}`, so `grv-milestone-setup`'s setup PR
must be merged first. Exception: under `grv-epic-run` this skill runs in that run's worktree on the
milestone branch and reads planning artifacts from it, with no merge in between.

## Arguments

- Phase number (required). `--no-uat`: passed to the "Next" line for `grv-phase-complete` only.
- `--autonomous`: removes prompts, never gates. Every place this skill would ask a human it instead
  **halts**: swap the stage label to `halted`, print `HALT <gate> Phase {N}: <reason>` as the last
  line, stop without a PR. Halts: no CONTEXT.md (discuss is never run unattended), design gate,
  plan-quality gate after one bounded retry, any `blocking-human` checkpoint (quote it, never answer
  it). An engineering blocker earns one retry; an authorization gate earns none.

## Process

**1. Resolve the Story.** Read `.planning/ROADMAP.md`; take the backtick key on the Phase {N}
checklist line (`{config: tracker.projectKey}-NNN`). None: stop, "run `grv-milestone-setup` first".

**2. Align the branch.** From `.planning/config.json` read `git.branching_strategy` and the matching
template, and render the expected name exactly as gsd-core renders it (it has no resolver for custom
tokens, so a tracker key goes in the milestone heading text, never as a template token; a mismatch
makes gsd-core's auto-checkout fork a second branch mid-run). If the current branch differs: an open
PR on it means stop; otherwise rename locally and push the new name. Deleting the old remote name
waits for an explicit human yes (conventions, "Branch deletion"); autonomous: leave it and list it
in the report. `git fetch` and check the remote ref before claiming the rename is visible.

**3. Fetch Story and GSD state.** `getJiraIssue`: labels (keep non-stage labels), status, assignee;
add the provenance label if absent. Note `has_context` (`*-CONTEXT.md`), `has_plan` (`*PLAN.md`),
`has_summary` (`*-SUMMARY.md`).

**4. Discuss.** Skip if `has_context`. Autonomous: halt `no-context`. Otherwise stage label
`discussing`; print open `.planning/WINDOWS.md` rows and unresolved dependency `DIVERGENCES.md` rows
(informational); `Skill(skill="gsd:discuss-phase", args="{N}")` without `--auto` (it would chain
past this skill's gates into plan-phase).

**5. Design gate.** Fires only when the ROADMAP Phase {N} section has `**UI hint**: yes` and
`has_summary` is false (before planning, so a shortfall is found before the findings are spent).
Full criteria and the trace format: `../../references/phase-gates.md`, "Design gate".

- **Pass:** the staged-design record has a current entry covering every screen the phase needs.
- **Partial coverage or no record** blocks (fail closed): print the loud notice ending
  `To proceed anyway, type exactly: override {N}`. Accept only that exact string, never yes/no;
  anything else stops with labels unchanged.
- **On override:** ask a one-line reason and write `{phase_dir}/{padded}-DESIGN-OVERRIDE.md`.
- Autonomous: halt `design-gate`. The override is a human act; never write the trace here.

**6. UI spec.** A UI phase is one labelled `ux` or marked `UI hint: yes` (the label alone once let
UI phases skip this silently). If UI phase and not `has_plan`: stage label `planning`,
`Skill(skill="gsd:ui-phase", args="{N}")` without `--auto`. Then confirm the UI-SPEC maps each
designed element to an existing shared primitive or names the new one to be added; without that map
the build restates the mockup's own markup. Missing: re-run once naming the gap, then halt.

**7. Plan.** Skip if `has_plan`. Stage label `planning`;
`Skill(skill="gsd:plan-phase", args="{N} --skip-research --skip-ui")`; then
`Skill(skill="grv-sdlc:grv-story-update", args="--phase {N}")`.

**8. Plan-quality gate.** Only for a plan authored this session. Check the four properties in
`../../references/phase-gates.md`, "Plan-quality gate": tracer plan first and alone in its wave (UI-hint phases),
re-runnable scope counts backed by a committed probe, a falsifier on every success criterion, and a
named red mutation for every new guard. Fail: stop with
`run gsd:plan-phase {N} --gaps to address {finding}`. Autonomous: one retry with the finding named,
re-check, then halt `plan-quality`. Never a loop.

**9. Execute.** Skip if `has_summary`. Stage label `executing`; assign if unassigned; transition
`{config: tracker.transitions.inProgress}` now (runs last hours; the board must show it).
`Skill(skill="gsd:execute-phase", args="{N} --no-transition")`.

- Verification ending at `human_needed` is **not** a halt: continue to step 10. Do not relay its
  `/gsd-verify-work` banner; the next command is `/grv-sdlc:grv-phase-complete {N}`.
- A checkpoint answer that changes scope lands as a dated amendment in PLAN.md with the superseded
  prose corrected in the same edit; a SUMMARY showing an answered checkpoint against stale PLAN
  prose is a gap for `plan-phase --gaps`.
- Gaps, failures, or any halt: swap the stage label to `halted` (an `executing` label on an idle
  phase misleads the board), leave status In Progress, no PR. `grv-phase-complete` step 8 clears it.

**10. Draft PR.** Assign if unassigned; transition In Progress again (idempotent, for the skip path);
clear stage labels by name, keeping provenance. No `gsd:pr-branch` (one combined PR).
`Skill(skill="gsd:ship")`, then `gh pr ready --undo <n>` so it is not mergeable during verify and
UAT, then transition `{config: tracker.transitions.uat}` explicitly and confirm it (a mark-ready
automation never fires on a draft). Do not announce the preview: `grv-uat-session` does, once data
and logins are verified.

**11. Done.** Print phase, Story key, draft PR number, and Next:
`/grv-sdlc:grv-phase-complete {N}[ --no-uat]` (verify lane + UAT), `/grv-sdlc:grv-uat-session {N}`
when `{config: verification.preview}` is `per-pr`, then `Next (human): mark the PR ready` and
`/grv-sdlc:grv-phase-review-fix {N}`. This skill never readies the PR.

## Error handling

Tracker failure: log, continue, name it in the report. `has_plan` without `has_context`: discuss
first. A transition that does not land: stop, list the available transitions; never log success.
