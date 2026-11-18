---
name: grv-story-deliver
description: >
  Deliver one tracker ticket as an engineering change: pull the ticket (its description is the
  spec), implement it, open a PR. Defaults to an isolated git worktree cut from the default branch
  with its own agent team, branch and PR, so the active session's tree and open PR are untouched;
  `--attached` works on the current branch instead. Escalates phase-sized work to grv-phase-run.
  Accepts free text and files the ticket first. Never merges.
  Triggers on: "deliver PROJ-", "deliver this ticket", "pick up PROJ-", "spin off PROJ-",
  "ship this ticket in isolation", "grv-story-deliver".
allowed-tools:
  - AskUserQuestion
  - Read
  - Edit
  - Write
  - Bash
  - Agent
  - Skill
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__searchJiraIssuesUsingJql
  - mcp__atlassian__createJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__addOrEditJiraIssueComment
  - mcp__atlassian__atlassianUserInfo
  - mcp__atlassian__discover
  - mcp__atlassian__executeWrite
  - mcp__slack__slack_search_channels
  - mcp__slack__slack_send_message
---

# grv-story-deliver

The leaf deliverer: one story, one change, one PR. Read `.grv/sdlc.json` first; stop naming any
missing required key. Shared rules: `../../references/pr-and-review-conventions.md` (path relative
to this skill's directory).

It exists for **lane independence**: a quick change run inside the current session touches that
working tree and `STATE.md` and collides with in-flight roadmap work. An autonomous ticket-queue
watcher runs on the same isolated path; only the trigger differs. Not the milestone lane
(`grv-epic-run`: one branch, GSD phases), not a UAT tool (`grv-uat-session`), not Story enrichment
(`grv-story-update`), and not for non-engineering stories with no code or config deliverable.

## Modes

- **Isolated (default):** a worktree cut from fresh `origin/{config: repo.defaultBranch}`, its own
  agent team, branch and PR. Required for unattended delivery and for work unrelated to what is open.
- **`--attached`:** the current branch, PR and tree. **Choose it, instead of the default, when the
  ticket continues work this same session already has open on a PR**: one branch, one PR for
  continuous follow-up work outranks this skill's default. Attached on the default branch: stop.
- **One writer per checkout.** Two writers in one working tree sweep each other's changes into
  their commits. Each writer gets its own worktree; check `git diff --cached --stat` before every commit.
- **Arguments:** a ticket key (`PROJ-123`) with optional notes, or free text with no key; optional
  `--attached` and `--no-uat`. `--no-uat` still runs and reports the autonomous half in full and
  records a waiver for the human half; the ticket still stops at UAT.

## Process

**1. Resolve the ticket.**

- Key: `getJiraIssue`. The description is the spec; do not re-derive scope from the title. Done or
  already at UAT: stop. Non-engineering: stop, wrong tool.
- Free text: confirm the problem is real (just enough reading to locate it; no fixing yet), search
  for a duplicate with `searchJiraIssuesUsingJql` (found: stop and offer the existing key). Otherwise
  `createJiraIssue` in `{config: tracker.projectKey}`, `Bug` or `Story`, `contentFormat: "markdown"`,
  parent set to the owning epic, a 3-5 word ASCII title, and the provenance label set at creation, so
  the mark exists even if step 2 stops the run.

**2. Escalation gate (hard stop).** Quick-shaped means a sentence-sized change, about 3 files or
fewer, no new dependency, no schema or migration change, no research. Otherwise stop, say why, and
recommend `grv-phase-run`; leave the ticket where it was. Always phase-sized:

- An authorization or tenancy change touching a shared guard or a database policy: fixing the
  reported call site is not fixing the class, and a control must hold at every layer that enforces it.
- Money arithmetic, a status-vocabulary change, or seed-data authoring.
  Exception: a control deliberately enforced in one layer only may stay quick if you say so and prove
  it with the paired positive/negative control.

**3. Mark and start.** One `editJiraIssue` from a fresh read: provenance label, plus the track field
`{config: tracker.fields.track}` (optional; skipped when absent). Assign to yourself (`atlassianUserInfo`) if unassigned; never
reassign. Transition `{config: tracker.transitions.inProgress}` and confirm the returned status.

**4. Workspace.**

- Isolated: branch from `.planning/config.json` `git.quick_branch_template` with `{slug}` = key plus
  a short kebab summary; `git fetch origin` then
  `git worktree add -b <branch> "$(git rev-parse --show-toplevel)/../<repo>-<KEY>" origin/<default>`.
  A dirty leftover worktree at that path is reported, never silently reused.
- Attached: current branch, after confirming it is not the default branch.

**5. Delivery team.** Isolated: background `Agent` calls, each told the worktree path. Attached: in
session. One file: one implementer. Two or three files: an implementer plus a separate reviewer agent
with its own context, diffing against the relevant `AGENTS.md` review lens. Resolve models from
`.planning/config.json` (`model_profile`, `model_overrides`); never hardcode one. Run the project's
test, lint and type-check commands from its `AGENTS.md`. Commit normally: signed, hooks running. A
hook or signing failure is a blocker to report, never a reason for `--no-verify` or disabling signing.
Do not log progress with gsd-core quick-task tooling; tracking is the ticket and its PR link.

**6. PR and tracker.** `gh pr create`, title `fix(<KEY>): ...` / `feat(<KEY>): ...` /
`chore(<KEY>): ...`. Prose body, no checkboxes: what changed, the review lens applied, and
**Verification** in two parts: _verified autonomously_ (real test output, lint, type check, and for
authorization changes the paired control) and _needs a human on a preview_ (the workflow end to end
as the affected user, realistic scale, product judgement). Always open it as a draft (`--draft`),
with the failure output if anything is red; marking it ready is the human's act (conventions,
"Marking a PR ready"). Transition `{config: tracker.transitions.uat}`, confirm it landed, and
comment the same two-part split plus the PR link. With `--no-uat`, the comment records `uat: waived`,
the date, the operator who ran the delivery and a one-line reason **the human gave**; with no human
reason, do not waive.

**7. Report, never merge.** Key, mode, branch, PR URL, verification, and the worktree path
(isolated), then `Next (human): mark the PR ready` once the verification is green. Say that merging
is a human decision and that UAT means a person still has to exercise the change. Chat: a notify-only pointer per the conventions.

**8. Clean up.** Keep the worktree until the PR merges (review changes are made there). The ticket
stays at UAT after the merge; `grv-release-close` presents it for the human's Done verdict and prunes
the worktree and branch. This skill does neither.

**Errors.** Ticket done or non-engineering: stop, change nothing. Phase-shaped: stop at the gate.
Tests fail: draft PR with the output, never presented as done. Tracker or chat failure: log, continue.
