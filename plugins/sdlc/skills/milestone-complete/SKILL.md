---
name: milestone-complete
description: >
  Close out a shipped milestone on its close-out PR, before a human merges it - the half of a
  release that changes repo files. Gate on every phase being verified, extract learnings and feed
  them back into the instruction files, refresh human-facing docs through docs-sync, archive the
  milestone, list what is open at release in the PR, post the epic's decision roll-up, and ready the
  PR. Everything after the merge is release-close. Never merges. Triggers on: "close out
  milestone", "complete milestone", "milestone close-out", "milestone-complete".
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

# milestone-complete

## Two PRs, and nothing changes the repo after the last merge

The **release PR** carries the features and merges first. The **close-out PR** carries everything
after: release records, production follow-up fixes, learnings and instruction-file changes, the docs
refresh, the gsd-core archive and the `Open at Release` list. This skill runs on the close-out PR
before it merges and makes every repo change. `release-close` runs after the merge and changes no
file. With every file change before the last merge, the close-out cannot spawn another PR; a defect
found after release-close is a new change request. A release step that depends on someone remembering
does not happen, which is why this is a skill.

## Arguments

`<version>` (required); `--pr <n>` (default: the open PR from the current branch, else from the
milestone branch); `--dry-run` (instruction-diff proposal and open-items list only; no commit, push or
Jira write). PR `MERGED`: stop - the repo half is done; next is `/sdlc:release-close <version>`.

## Process

Read `.sdlc/config.json`. Use the `gsd_run` shim from `../../references/gsd-core-assumptions.md` (path
relative to this skill's directory).

- **Step 0 - Gate: shipped and verified.** For each phase of the milestone, `gsd_run verification status
  <dir> --pick status` (never a grep on `^status:`: a phase with no report prints nothing and drops
  out of the list silently, which is how an unverified phase ships recorded as complete). Then check
  the planning files agree: a `passed` phase whose ROADMAP progress row or REQUIREMENTS traceability
  rows still read open is a bookkeeping gap - complete its transition first, or the archive freezes
  the stale row. **Two axes, and only one can be waived.** `status:` must be `passed` for every
  phase: `missing`, `stale`, `gaps_found` or `human_needed` means the milestone is **not shipped**;
  stop and route the phase to `/sdlc:phase-complete <N>`. No risk acceptance substitutes for
  a missing verification artifact: an unverified phase recorded as shipped is the failure this gate
  exists to catch. `uat:` must be `passed` or `not_required`, or `waived` with `uat_waived_at`,
  `uat_waived_by` (a named human) and `uat_waiver_reason`. A phase deferred to deploy time
  (`uat_deferred_to`) must now show `uat: passed` or such a waiver: the deferral covered the merge,
  not the close-out. Print waived phases so they reach the Release's Risk Accepted section.
- **Step 0.5 - Be on the close-out branch before anything writes.** Archive and instruction edits cannot land
  on `{config: repo.defaultBranch}`. Use the already-open close-out PR; never open a second. Only if
  none exists, cut one from the merged state with `git.quick_branch_template` from
  `.planning/config.json` and open it as draft (`chore(<KEY>): <version> close-out`). Production
  follow-up fixes found during the run go on this branch.
- **Step 1 - Extract learnings:** `Skill(skill="sdlc:learn", args="extract milestone <version>")`.
  This is the input to step 2; never hand-write instruction changes from memory.
- **Step 2 - Feed them back - the step that compounds.** Propose concrete edits: `AGENTS.md` for anything true
  regardless of tooling (most learnings); `CLAUDE.md` only for what exists because Claude Code is the
  tool. Prefer rules that name the defect that earned them; a rule with no scar is easy to ignore.
  Show the diff and write only on approval: these files govern every future session.
- **Step 2.5 - Refresh human docs, one hop:** `Skill(skill="sdlc:docs-sync")` (`--audit` under
  `--dry-run`). Never call gsd-core's docs updater directly: two entry points to one regeneration is
  how routing drifts. Answer the items it will not write unattended here, with the human present.
  Open rows go to step 4.
- **Step 2.6 - Track checkpoint.** The learn track has no fixed size and can swallow the session while the
  complete track sits unstarted. If steps 1-2.5 produced anything beyond ledgers and instruction diffs
  (a new skill, config change, filed ticket), print `Complete track: step 3 onward not started` and
  ask whether to keep deepening or continue. A decision, not a drift.
- **Step 3 - Archive.** `gsd-complete-milestone <version>`. It archives every directory under
  `.planning/phases/` (assumptions item 10): dry-run first, park any phase that belongs to another
  milestone, move it back immediately after. Keep the large move diff on its own commit.
- **Step 4 - Open at Release list** (for the PR body; never for the Release itself, which records only what
  shipped): defects shipped deliberately, with ticket links; `Docs gaps left open: <count>` (always,
  zero included) with each title; every result of
  `parent = <EPIC_KEY> AND status not in (Done, Approved)`, by key and summary, plus any cross-epic
  deferral known from the session. Omitting shipped defects would make the record a brochure.
- **Step 4.5 - Decision roll-up on the epic.** One "Decisions this milestone" comment: every decision that
  changed what the epic asked for, as old / new / why / who decided (a named individual for every
  row; ask before posting if a name is missing) / source, linking mid-milestone decision comments
  rather than restating them. Rewrite stale acceptance lines to what shipped (no strike-through) with
  `{config: owners.productOwner}`'s approval. Nothing changed: post that it changed nothing, so the
  absence is recorded. Provenance label, read-modify-write. Confirm before posting.
- **Step 4.6 - Cleanup.** `gsd-cleanup`.
- **Step 4.7 - Confirm gsd-core reads it closed.** `gsd_run query audit-open --json` (zero, or every item
  acknowledged), archived phases' status, `git status --porcelain` empty. Fix anything here: after the
  merge there is no second chance without a new PR.
- **Step 4.8 - Ready the PR - the skill ends here.** Push; write the body (Open at Release list, summary of
  instruction and docs changes); `gh pr ready`. This is the one place in the plugin an agent readies a
  PR: the close-out PR, after every file change has landed (conventions, "Marking a PR ready").
  Merge-ready means every `{config: repo.requiredChecks}` entry settled green on the pushed head.
  Report and stop: **merging is a human decision**; afterwards the next step is
  `/sdlc:release-close <version>`.

Never move a file-writing step after 4.8. The Release, chat pointer and every Done belong to
`release-close`.
