---
name: milestone-planner
description: >
  Take every pending phase of the active milestone from discuss through planning in one command.
  Discuss runs sequentially with the user present; planning runs in dependency-ordered waves -
  parallel within a wave, sequential across waves - so a phase can read the plans of the phase it
  depends on. --fast skips research; --phases N,M,K targets a subset. Triggers on: "plan milestone",
  "plan all phases", "milestone planner", "milestone-planner".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Agent
  - Read
  - Bash
---

# milestone-planner

Discuss all pending phases one by one, then plan them in dependency-ordered waves.

## Arguments

- `--fast` pass `--skip-research` to each plan-phase.
- `--phases N,M,K` only these phases (default: every pending phase in ROADMAP.md).
- `--skip-discuss` skip discuss where CONTEXT.md exists.
- `--autonomous` the `epic-run` path: skip the ">3 phases" confirmation and imply `--skip-discuss`.
  **Discuss itself stays interactive** for any phase still lacking CONTEXT.md. gsd-core's
  `discuss-phase --auto` picks every answer and always chains into plan-phase, bypassing the per-stage
  gates (`../../references/gsd-core-assumptions.md` item 6, path relative to this skill's directory). Autonomous means "no orchestration prompts",
  never "answer the PO's questions for them".

## Process

### 1. Detect pending phases

From `.planning/ROADMAP.md` and `.planning/STATE.md`: phases with no PLAN.md yet (or `--phases`). None:
"All phases already planned." and exit. More than 3 and not `--autonomous`: confirm (proceed / adjust
with `--phases`); under `--autonomous` log the list instead.

### 2. Discuss sequentially

For each phase in order, unless `--skip-discuss` and CONTEXT.md exists:
`Skill(skill="gsd:discuss-phase", args="<N>")`. Wait for it before the next one.

### 3. Compute dependency waves - never fan out every phase at once

Milestone phases are frequently a chain: one settles a pattern, the next promotes it, the next
consumes it. Planning them simultaneously costs three things: duplicated research and pattern-mapping
per planner over a shared change surface; blind seams, because phase N+1's planner cannot read phase
N's plans that do not exist yet; and concurrent writers to `.planning/STATE.md`, whose writers have
destroyed data before.

- Parse each target phase's `**Depends on**:` line. Keep only references to phases **in the target
  set**; dependencies on shipped phases are satisfied.
- Topologically sort: wave 1 has no in-set dependency; wave k depends only on earlier waves.
- **A missing `Depends on` line means "depends on every lower-numbered phase in the target set".**
  This is the common path, not an edge case: plan-phase is what writes a phase's detail block, so an
  unplanned phase often exists only as a one-line bullet. The fallback is deliberately pessimistic:
  sequencing two independent phases costs wall-clock; parallelising two coupled ones costs
  correctness.
- Compute every wave from ROADMAP.md as it stands **before** the first planner spawns; planners write
  those sections as they go, so a later read shows their output, not your input.
- A cycle: stop and report it; never guess an order.

Print the plan (`Wave 1: 4, 6 (independent)` / `Wave 2: 5 (depends on 4)` ...) before spawning.

### 4. Run each wave

Flags: `--skip-discuss` always, plus `--skip-research` if `--fast`. For each wave, spawn one Agent per
phase in a single message and wait for all of them:

```text
Run /gsd:plan-phase <N> --skip-discuss <FLAGS> and return "## PLANNING COMPLETE" or
"## PLANNING FAILED" with the phase number. Phases <earlier waves> are already planned - read their
PLAN.md files first; this phase depends on them. Do not create or switch branches.
```

If the wave has more than one phase, add: "Do not write .planning/STATE.md; the orchestrator records
the session after the wave." **Any failure in a wave stops the run**: later waves depend on it. Report
which wave stopped and why.

### 5. Report

Per phase: PLANNED with plan count, or FAILED with reason. Next: `/sdlc:phase-run <N>` for one
phase or `/sdlc:milestone-run` for all pending phases (both self-skip discuss and plan where artifacts exist).
Never suggest a bare `gsd:*` command to the user when an `sdlc:*` wrapper exists.
