---
name: grv-epic-run
description: >
  Run an entire epic autonomously - milestone setup, then every phase from plan to a draft PR - in
  its own isolated git worktree, without the operator typing a raw gsd command. Setup and all phases
  stay on one worktree/branch; no mid-run merge. Never prompts mid-run: every human gate (a
  blocking checkpoint, UAT sign-off, Approved, merge, Release) halts the run, writes a ledger row and
  hands back to a human. Calls only grv-* skills. Triggers on: "run epic", "epic run", "deliver the
  whole epic", "grv-epic-run".
allowed-tools:
  - Read
  - Write
  - Bash
  - Agent
  - Skill
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__atlassianUserInfo
---

# grv-epic-run

`/grv-sdlc:grv-epic-run PROJ-123`: worktree -> `grv-milestone-setup --autonomous` -> `grv-milestone-run
--autonomous` -> report. One command; the operator comes back to a draft PR or to a ledger row saying
exactly where a human is needed. Each orchestrator calls only the level below it; this one never calls
a `gsd:*` skill. It adds what no lower level owns: the worktree, a pre-flight across every phase, and
the run ledger. (Story lane vs milestone lane: `grv-story-deliver` is one ticket, one isolated PR; this
skill is one worktree, one branch, one PR, phases in dependency order.)

## Arguments

- `<EPIC-KEY>` (required): an Epic, not Done.
- `--from N` resume from phase N in the existing worktree; every stage whose artifact exists self-skips.
- `--foreground` run stage B inline instead of in a background agent. `--attached` skip the worktree
  (escape hatch only; isolation is the point).
- **No `--no-uat` here, deliberately.** A launch-time waiver would attest, in the operator's name, to
  phases that do not exist yet when the reason is written. Waiving stays per phase, made when the phase
  exists: `/grv-sdlc:grv-phase-complete <N> --no-uat --uat-waiver-reason "<text>"`, run separately.

## Preconditions (human work, before this command)

1. The Epic exists (`grv-epic-writer`).
2. ROADMAP.md (with `**Jira epic:** <KEY>`) and REQUIREMENTS.md are on the remote default branch,
   via the merged `/grv-sdlc:grv-milestone-init <KEY>` intake PR. Requirements are PO intent; never derived here.
3. Every phase has CONTEXT.md, or the operator is present for stage A. Discuss is the one human-present
   step kept; stage B never discusses, and a phase reaching it without CONTEXT.md halts.

## Process

0. **Config and Epic.** Read `.grv/sdlc.json` (`tracker.*`, `repo.defaultBranch`,
   `tracker.labels.stage.halted`). `getJiraIssue`: must be an Epic, not Done.
1. **Worktree.** Derive a provisional branch name from the milestone heading on the remote default
   branch through `git.milestone_branch_template` (as `grv-milestone-setup` step 1). Worktree at
   `.claude/worktrees/epic-<key-lowercase>` (must be gitignored). A dirty existing worktree: stop and
   name it. Existing branch (resume): check it out without `-b`. Every later step runs inside it.
2. **Pre-flight, read-only; any failure prints all failing checks and stops with no ledger.**
   gsd-core installed (`../../references/gsd-core-assumptions.md`, path relative to this skill's
   directory); roadmap has the epic key and REQUIREMENTS.md exists (else "run
   /grv-sdlc:grv-milestone-init <KEY> first"); any gate the consuming repo
   defines for `grv-phase-run` that can be checked up front is checked for every phase now, so it
   fails before phase 1 rather than at phase k (never overridden here: an override is a typed human
   act). **Another open milestone branch: warn, do not refuse** - both will rewrite STATE.md and
   conflict at merge, a visible conflict a human resolves; record it in the ledger.
3. **Ledger.** `.planning/epic-runs/<KEY>-RUN.md` (on `--from`, append `## Resume <date>`): ISO start,
   operator, flags verbatim, worktree, branch, warnings, then one row per phase as it ends:
   `| N | KEY | Complete or HALT <gate> | uat: pending/passed/waived/n/a | Jira status | note |`.
   `passed`/`waived` appear only when a human ran `grv-phase-complete` separately. Committed with the
   run, so a halted run leaves its reason in the repo. Mark the Epic: provenance label
   (read-modify-write) and transition to `{config: tracker.transitions.inProgress}` by id if not
   already, confirming the returned status. Never past In Progress.
4. **Stage A - setup, human present.** `Skill(skill="grv-sdlc:grv-milestone-setup", args="--autonomous")`. A
   `HALT` line or a declined discuss: ledger row, stop. Then re-run the **branch-drift check, read-only**,
   recomputing the expected name from the worktree's _current_ ROADMAP.md (setup may legitimately
   rename the branch when it embeds the epic key). Mismatch: `HALT branch-drift`; never rename here -
   that would hide a defect in setup's own guard.
5. **Stage B - execute, unattended.** `Skill(skill="grv-sdlc:grv-milestone-run", args="--autonomous[ --from N]")`,
   by default in one background Agent whose first act is `cd` into the worktree and whose only job is
   to invoke that skill and return its banner. If the agent reports it cannot use `Skill` or `Agent`
   (subagent tool allowlists can silently lack them), re-run with `--foreground`; never work around it
   inside the agent. Re-run the drift check after it returns.
6. **Report - never merge, never mark ready.** Append final ledger rows, confirm the PR is draft,
   commit the ledger (`docs(<KEY>): epic run ledger`), print phases with gsd status, `uat:` and Jira
   status, any halt and the resume command, and the human next steps (`grv-phase-complete` for pending
   UAT, mark ready, `grv-phase-review-fix`, `grv-milestone-review`, merge, `grv-milestone-complete`,
   merge, `grv-release-close`). No chat or PO messages mid-run; the operator decides who hears.

## Halt contract

The skill that hits a gate sets the Story's `{config: tracker.labels.stage.halted}` label (status stays
In Progress); a ledger row reads `HALT <gate> Phase N: <reason>`; the PR stays draft; later phases are
not started; the report names the resume command.

| Gate                                                    | The run does                               | Never                                       |
| ------------------------------------------------------- | ------------------------------------------ | ------------------------------------------- |
| No roadmap section                                      | halt, point at `grv-milestone-init`        | author it                                   |
| Unresolvable grooming discrepancy                       | halt; corrections stay on the branch       | ask on the PO's behalf, guess, sync past it |
| Branch drift                                            | halt                                       | rename from here                            |
| No CONTEXT.md                                           | halt                                       | discuss unattended or with `--auto`         |
| Blocking-human checkpoint, or a repo-defined phase gate | halt, quote it                             | answer or override it                       |
| Plan-quality gate / gap-loop cap                        | one bounded retry, then halt               | loop or skip the phase                      |
| Lane B `human_needed`                                   | awaiting human UAT, Story at UAT, continue | call verify-work, write a verdict or waiver |
| Ready / review-fix / Approved / merge / Release / Done  | not part of the run                        | any of them                                 |

Jira failures are non-blocking: log, report, continue. Leave the worktree until the PR merges (review
fixes happen there).
