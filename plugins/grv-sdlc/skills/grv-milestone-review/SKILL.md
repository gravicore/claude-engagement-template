---
name: grv-milestone-review
description: >
  Milestone-level readiness review of the release PR, before it is marked ready and merged. Looks
  across every phase at once: a verification sweep (one allowed exception, a human-recorded
  deploy-time deferral), gsd-core's own milestone audit (wrapped, never reimplemented), review
  coverage for work that arrived outside a phase, the epic brought current before the PO tests the
  deployed build, and the PR's checks, threads, post-merge plan and PO test list. Writes a READY /
  NOT READY verdict into the PR body. Never merges, never marks the PR ready. Triggers on:
  "milestone review", "review the milestone", "release readiness", "is the milestone ready to
  merge", "grv-milestone-review".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Read
  - Edit
  - Write
  - Bash
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__searchJiraIssuesUsingJql
  - mcp__atlassian__addOrEditJiraIssueComment
  - mcp__atlassian__atlassianUserInfo
---

# grv-milestone-review

`/grv-sdlc:grv-milestone-review <version>` on the release PR. A milestone ships through two PRs: the release PR
(features; merges first so the PO can test the deployed build) and the close-out PR
(`grv-milestone-complete`). Every other check is per phase or after the merge; a gap found after the
merge is already in front of the PO. This is the one look across all phases before it.

Order: `grv-milestone-run` -> **this skill** -> human marks ready and merges -> PO tests ->
`grv-milestone-complete` -> human merges -> `grv-release-close`.

## Arguments

`<version>` (required); `--pr <n>` (default: the open PR from the milestone branch); `--dry-run` (every
read and the audit, print the verdict, write nothing).

## Process

Every step runs and reports; only step 0 stops early. The verdict lists every blocker at once. Use the
`gsd_run` shim from `../../references/gsd-core-assumptions.md` (path relative to this skill's directory). Read `.grv/sdlc.json` (`repo.*`,
`repo.requiredChecks`, `tracker.*`, `owners.*`, `environments[]`).

0. **Resolve the PR.** `gh pr view`; check out its head. `MERGED`: stop - a review after the merge is a
   process finding, not a review; next is `grv-milestone-complete`. Record the epic key and **the
   milestone's phases from its ROADMAP section** (never every directory under `.planning/phases/`: a
   parked phase from another epic is not this milestone's to pass or fail).
1. **Verification sweep.** Per phase: `gsd_run verification status <dir> --pick status` and the `uat`
   frontmatter. A value outside the known vocabulary is a tool error: fix the environment and re-run.
   - `passed` + `uat` passed / waived (with its three fields) / not_required: ok.
   - `passed` + `uat: pending`, or `human_needed`: blocker unless a deploy-time deferral covers it.
   - `gaps_found` / `stale` / `missing`: blocker, route `/grv-sdlc:grv-phase-complete <N>`. No risk
     acceptance clears it: a phase with no verification artifact is not shipped.
   - **Deploy-time deferral, the one exception**, for acceptance that can only be shown after deploy:
     `uat_deferred_to`, `uat_deferred_reason`, `uat_deferred_by` in VERIFICATION.md. A deferral needs
     a report to live in (a `missing` phase is still a blocker: verify what can be verified first).
     The values are the lead engineer's call, asked in this session and written with
     `gsd_run frontmatter set`; an agent never sets a deferral on its own judgement. A phase whose plans
     all declare `blast_radius: high` cannot be deferred.
2. **gsd-core milestone audit, one hop.** `Skill(skill="gsd-audit-milestone", args="<version>")`; find
   the report by glob (`*MILESTONE-AUDIT.md`). `passed`: ok. `gaps_found`: sort each gap -
   (a) covered by a step-1 deferral: expected, list it beside the deferral; (b) **bookkeeping** (work
   verified but records disagree: missing `requirements-completed`, unticked requirement, stale
   progress row) - fix on this branch, they are planning files, then re-run the audit; (c) **product
   gap** (nothing verified it): blocker, routed back through `/grv-sdlc:grv-phase-run`, never hand-fixed here.
   `tech_debt`: listed for the human to accept or ticket; a declined item becomes a blocker. Say that
   the integration checker reads statically and does not replace live verification.
3. **Review coverage.** Every phase has a `*-REVIEW.md` (else blocker, route the code-review command);
   every phase with a threat model has a `*-SECURITY.md` with no open threats. **Commits outside a
   phase** (not scoped to a phase, plan id or the phase Story, not named in a SUMMARY.md, touching more
   than `.planning/`): each needs a review dated after it that names the commit, its ticket or each
   product file. A review that predates the fix did not see it. Unreviewed product code is a blocker;
   offer a review of exactly those files using the lenses the consuming repo's AGENTS.md names.
4. **Epic current for the PO's test.** Read the epic and every decision recorded during the milestone
   (CONTEXT.md D-numbers, REQUIREMENTS.md Key Decisions, existing decision comments). For each decision
   that changes what the description asks for: propose one never-edited decision comment (old / new /
   why / who decided, a named individual / source) and the amended description lines. Post only on an
   explicit yes, with `{config: owners.productOwner}` approving the description. Provenance label,
   read-modify-write. No change: say so in the PR body; never post an empty comment.
5. **The PR itself.** Every check in `{config: repo.requiredChecks}` has reached a final state and
   passed (pending is "not yet", never ready); no unresolved review thread (list each); title carries
   the epic key; body has no checkboxes. **Post-merge plan:** every deploy-time step (data migration,
   runbook, flag per environment, seed) found in plans and CONTEXT.md has a named owner and a written
   procedure, else blocker. **PO test list** from UAT items and deferrals, ready to paste.
6. **Verdict.** Replace a `## Milestone Review` section in the PR body: `Verdict: READY` or
   `NOT READY (<n> blockers)`, date, head SHA; phase table; deferrals with reason and who decided; audit
   status and path; review coverage; epic; checks, threads, post-merge plan, PO list; every blocker
   with its route. Commit the audit file and any deferral frontmatter alone
   (`docs(<KEY>): <version> milestone review`), check `git diff --cached --stat`, push. The push
   restarts CI: re-read the checks after they settle before reporting READY.

READY means a human may mark the PR ready and merge; this skill does neither. Every blocker routes to
the skill or person that owns it; a hand fix here would be exactly the unreviewed outside-phase work
step 3 exists to catch. Outward writes (epic, PR body) are confirmed in session; `--dry-run` writes none.
