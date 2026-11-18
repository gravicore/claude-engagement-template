---
name: phase-complete
description: >
  Take an executed phase to Complete in two lanes. Lane A (Verify) is autonomous and mandatory:
  read gsd-core's verification status, repair a missing or stale report, close gaps (max 3
  iterations) and land a committed `status: passed` report. Lane B (UAT) is the human gate,
  entered only from `human_needed`: an automated pre-pass and an advisory read narrow the work,
  but only a named human's answer in-session records `uat: passed`. `--no-uat` skips Lane B only,
  with a dated named waiver. Then clears the stage label and moves the Story to UAT.
  Triggers on: "complete phase", "phase complete", "verify fix", "fix gaps", "draft verify loop",
  "phase-complete".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Bash
  - Read
  - Write
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__discover
  - mcp__atlassian__executeRead
---

# phase-complete

Read `.sdlc/config.json` first; stop naming any missing required key. Shared rules:
`../../references/pr-and-review-conventions.md` (path relative to this skill's directory). The
gsd-core behaviours relied on (the `gsd_run` shim, status values, the unfiltered self-heal,
`verify-work` having no create path) are in `../../references/gsd-core-assumptions.md`.

**Two axes.** `status:` (gsd-core's; `human_needed` means "machine passed, human pending") must
reach `passed` on its own merit. `uat:` (`not_required | pending | passed | waived`) is the human
verdict, a per-field `gsd_run frontmatter set` write.

## Arguments

- Phase number (required). `--uat-waiver-reason "<text>"`: the human's reason, supplied up front.
- `--no-uat`: skip Lane B only, with a waiver. Never skips Lane A; refused above the blast-radius floor.
- `--autonomous`: never prompt. `--no-uat` then requires `--uat-waiver-reason` (an agent never
  authors a risk acceptance). `human_needed` without a waiver ends at "awaiting human UAT" (5c);
  nothing in this mode writes a `uat:` verdict or calls `gsd:verify-work`.

## Lane A - Verify

**2. Read status.** `gsd_run verification status "$PHASE_DIR"` and parse the JSON. Never grep the
file: a grep cannot see `missing` and reads `stale` as `passed`. Route:

- `passed`: say so, stop. `stale`: treat as `missing`.
- `missing`: first check every `*-PLAN.md` has a `*-SUMMARY.md`; a checkpoint-only (human-action)
  plan whose evidence exists gets its SUMMARY written from that evidence, naming any departure, or
  the self-heal tries to execute it. Then `Skill(skill="gsd:execute-phase", args="{N}")` with **no
  filter flag** (the self-heal that authors the report), and re-read.
- `gaps_found`: step 3 at 3b. `human_needed`: Lane B (step 5).

**3. Gap loop, max 3 iterations.** 3a re-read status and route as above (`passed` goes to step 4).
3b `Skill(skill="gsd:plan-phase", args="{N} --gaps")`. 3c
`Skill(skill="gsd:execute-phase", args="{N} --gaps-only")`; a filtered run closes gaps but never
authors a report, so a following `missing` goes to the repair arm. Increment; past 3, go to step 6.

**4. Lane A clean.** Run step 7, then print the clean banner (iterations, `status: passed`, `uat:`
value) and `Next (human): mark the PR ready, then /sdlc:phase-review-fix {N}`. Never run
`gh pr ready`: phases share one milestone PR (conventions, "Marking a PR ready").

## Lane B - UAT

**5a. Automated pre-pass** and **5b. Advisory read** run every time, autonomous included, per
`../../references/uat-evidence.md`: concrete assertions checked live as `pre_checked:` beside an
untouched `result: [pending]` (a failing claim is a gap, 3b under the cap); judgment items never
auto-checked, given an `agent_advisory_read:` recommendation. Neither is the sign-off.

**5c. Paths.**

- **`--no-uat`.** Refuse if any plan's frontmatter declares `blast_radius: high` (a change to a
  shared default is not the risk class a waiver was meant for); report the file and stop. Otherwise
  take the reason from the flag or ask the human; autonomous with no reason: refuse and fall to the
  awaiting path. Write `uat: waived`, `uat_waived_at` (UTC date), `uat_waived_by` (the launching
  operator's `git config user.email`: the waiver is theirs, not the agent's), `uat_waiver_reason`.
  Continue to step 7.
- **Autonomous, no waiver: awaiting human UAT.** Set `uat: pending` if it is not already (a state,
  not a verdict). Commit the UAT file and evidence from 5a/5b alone:
  `docs(phase-{N}): UAT evidence and advisory read - awaiting human UAT`. Do **not** run step 7:
  its 7b calls `gsd:verify-work`, and answering it with no human present forges the verdict. Run
  step 8 (the UAT transition announces readiness for a human; it is not sign-off). Print the
  annotated checkpoints headed `HUMAN UAT PENDING - phase {N} awaiting human UAT (--autonomous)`,
  then `Next (human): /sdlc:phase-complete {N}` run interactively. Return.
- **Interactive.** Present every item with its annotation (`[pre-checked: VERIFIED - <paths>]`,
  `[pre-checked: TRIED-AND-FAILED - <reason>]`, or `(reserved - agent read: <summary>)`); omit none.
  Ask the human explicitly and wait for their answer in this session. An empty pending queue, a
  complete evidence file, or a prior delegation to test is not that answer. Human confirms all:
  `uat: passed`, then step 7. Human reports an issue: a fresh gap, back to 3b under the cap.

**6. Max iterations.** Print the remaining gaps; suggest `gsd:debug`. Stop; skip 7 and 8.

## Close-out

**7. Close the GSD verify gate.** Reached only after step 4, a human's in-session answer, or a
human-supplied waiver; never from the autonomous awaiting path. Rules for each sub-step are in
`../../references/uat-evidence.md`, "Closing the verify gate".

- 7a Re-read. `passed`: 7c. `missing`/`stale`: unfiltered repair. `gaps_found`: 3b. `human_needed`: 7b.
- 7b Security review first if enforced (`Skill(skill="gsd-secure-phase", args="{N}")`), then
  `Skill(skill="gsd:verify-work", args="{N}")` with the human's own answers (or waived per the
  recorded waiver, never passed). Never flip `status:` by hand: that skips gsd-core's transition.
- 7c Commit a changed report, ROADMAP.md or STATE.md; run the end-state check (assumption 15 if
  gsd-core refused the write). `passed` runs step 8; anything else goes back to its arm.

**8. Close the tracker side** (after `passed`, or from the autonomous awaiting path). Resolve the
Story key as `phase-run` does; none means log and return.

- 8a Clear stage labels by name; ensure the provenance label (the last write to a phase Story).
- 8b Transition `{config: tracker.transitions.uat}`, confirm the returned status; never past UAT.
- 8c Promote open `{N}-DIVERGENCES.md` rows naming a later phase or no ticket key to the register with
  `gsd_run windows append --kind deviation` (assumption 16); never hand-edit it. No PR side effect.

## Error handling

Stop with raw output when `verification status` errors (never grep instead), a repair run is still
`missing` (never substitute `verify-work`), `plan --gaps` writes nothing, `--gaps-only` fails, or
step 7 fails. Step 8 failing is non-blocking: say plainly the board or register was not updated.
