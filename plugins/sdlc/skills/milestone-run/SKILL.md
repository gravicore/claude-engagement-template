---
name: milestone-run
description: >
  Run every pending phase of the active milestone end to end with Jira tracking, sequentially:
  phase-run then phase-complete per phase (discuss, plan, execute, draft PR, autonomous
  verify; discuss and plan self-skip where artifacts exist). Pauses on a blocker, or with
  --autonomous halts and reports instead of prompting and passes --autonomous down so no child
  prompts either. Never merges. Triggers on: "run milestone", "milestone run", "milestone-run".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Read
  - Bash
---

# milestone-run

## Arguments

- `--phases N,M,K` target these phases. `--from N` skip pending phases before N.
- `--autonomous` never prompt; a blocker halts the run and reports. Passed down to `phase-run`
  and `phase-complete`.
- **No `--no-uat` here, deliberately.** A launch-time waiver applied to every phase would attest, in
  the operator's name, to phases whose code does not exist yet when the reason is written. A UAT
  waiver is per phase, recorded by a named human when that phase reaches its gate:
  `/sdlc:phase-complete <N> --no-uat --uat-waiver-reason "<text>"`, run separately. Refuse
  the flag if passed, naming that command.

## Autonomous mode

For a milestone already discussed and planned: execute to UAT without anyone at the keyboard.

- **A blocker halts the run.** Never prompt, never skip the phase and continue: phases are usually a
  chain, so later phases would execute against a precondition that does not hold.
- **Execution stays sequential, deliberately.** Under milestone branching every phase commits to one
  shared branch; two phases executing at once means two agents committing to the same branch, which
  races even when their files are disjoint. Parallelism lives inside a phase (execute-phase runs plans
  in waves). Use each phase's `**Depends on**:` line to **assert the run order** (every in-set
  dependency runs first; halt naming the pair if not), never to fan out.
- **Human UAT never blocks the run and is never recorded by it.** `--autonomous` runs Lane A
  (verify) per phase; a phase at `human_needed` ends "awaiting human UAT" (`uat: pending`, evidence
  committed, Story at UAT) and the run **continues to the next phase**: Lane B is a verdict on phase
  N, not a precondition for N+1's code, and nothing merges from a draft PR. Accepted risk: a UAT
  finding on N can invalidate N+1 work, so the final report lists every pending item.
- Under `epic-run` this runs inside that run's worktree; planning artifacts are read from the
  current branch.

## Process

### 0. Assert setup is complete

Read `.sdlc/config.json` (`tracker.projectKey`). Every phase line in `.planning/ROADMAP.md` must carry a
backtick Story key (`` `<projectKey>-<n>` ``). Any missing: stop - "Run /sdlc:milestone-setup
first (and, interactively, have a human merge the setup PR)". A pending phase without PLAN.md is only a
warning: `phase-run` plans before executing.

### 1. Detect pending phases

Phases with no SUMMARY.md, filtered by `--phases` / `--from`. None: "All phases complete." More than 3
and interactive: confirm; under `--autonomous`, log the list.

### 2. Run each phase in order

```text
Skill(skill="sdlc:phase-run", args="<N>[ --autonomous]")
Skill(skill="sdlc:phase-complete", args="<N>[ --autonomous]")
```

The second call closes the phase's verify gate. Without it a phase ends at gsd-core status Executed,
not Complete: completion keys on a `status: passed` VERIFICATION.md that only `phase-complete`
Lane A produces. Skip it if phase-run halted. A Lane A failure (gap-loop cap) is a blocker like any
other; a phase awaiting human UAT is not.

**On a blocker:** with `--autonomous`, print `MILESTONE RUN HALTED - Phase <N>` with the blocker, the
completed phases (keys and status) and the phases not started (and what each waited on), then stop.
Interactive: ask "resolve and continue / skip this phase / stop here" and respect the answer.

### 3. Report

Table per phase: gsd status, `uat:` (pending / waived / passed), Jira status. Then:

```text
Next (human): /sdlc:phase-complete <N> for any uat: pending (or, with a named reason,
--no-uat --uat-waiver-reason "<text>"); mark the PR ready; /sdlc:phase-review-fix <N> per
phase; /sdlc:milestone-review <version>; merge; /sdlc:milestone-complete <version>
on the close-out PR; merge; /sdlc:release-close <version>.
```

Marking ready, merging, UAT sign-off, Approved, the Release and Done are human acts, listed and never
performed. Never relay a bare `gsd:*` command from child output as the user's next step.
