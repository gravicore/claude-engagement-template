# UAT Evidence: Pre-pass and Advisory Read

Detail for `grv-phase-complete` Lane B steps 5a and 5b. Both run every time Lane B is entered,
`--autonomous` included, so an unattended run leaves evidence and a stated recommendation instead
of a blank checklist. Neither ever substitutes for the human's sign-off: they narrow and recommend,
they never decide.

## 5a. Automated pre-pass

Split the verification report's human items into two kinds.

- **Concrete itemized assertions** (a selector, a computed value, a step-by-step behaviour): run
  the project's live verification against `{config: verification.localStack}` or the preview and
  record one of:
  - `VERIFIED`, with evidence paths;
  - `TRIED-AND-FAILED`, with what failed;
  - `NOT-ATTEMPTED`, with why.

  A claim that does not hold is a gap, not "still needs a human": route it to the gap loop (step
  3b) under the iteration cap. "The environment cannot do this" is a claim to test; record a real
  attempt as TRIED-AND-FAILED, never as NOT-ATTEMPTED.

- **Composite or backstop judgments** (marked `verification: backstop`, or whose `why_human` says
  the item is reserved for human judgment): never auto-check. Mark them
  `NOT-ATTEMPTED - reserved for human judgment`. An automated check of a judgment item would let a
  machine answer the question the human gate exists to ask.

Recording rules:

- Write each result into `{phase}-UAT.md` as `pre_checked:` beside `result: [pending]`. Never write
  over `result:`. A VERIFIED fact is evidence for the sign-off, not the sign-off.
- Any evidence file whose name contains `-UAT` gets frontmatter `status: complete`,
  `kind: uat-evidence`, `verdict_in: {padded}-UAT.md`. Without it the milestone audit counts the
  file as an open UAT session.
- Keep `## Gaps` to real open gaps; fixed items go under another heading, or the audit reads them
  as open.

## 5b. Advisory read

For each reserved item and each item asking for a product decision:

- look at the surface yourself and spot-check its named sub-claims;
- cite existing evidence for what you do not re-walk;
- write `agent_advisory_read:` with an explicit recommendation ("accept" or "trim"), not a
  description of the trade-off.

Never write it as `pre_checked:` or `result:`. A confident opinion is input to the human's call,
never the call: the recommendation exists so the human starts from a stated position they can
reject, not from a blank list.

## What an autonomous run leaves behind

With no human present and no human-supplied waiver, the run commits the UAT file (pre-checks and
advisory reads, every `result:` still `[pending]`) and leaves the verification report at
`human_needed` with `uat: pending`. `uat: pending` is a state ("no human verdict yet"), not a
verdict. The phase is awaiting human UAT until a human resumes `grv-phase-complete` interactively
and answers.

## Closing the verify gate (`grv-phase-complete` step 7)

- **Security review first.** If the project enforces security review and `{padded}-SECURITY.md` is
  absent, run `gsd-secure-phase {N}` before `gsd:verify-work`; verify-work's completion will not
  flip the report without it, and running it first keeps the audit from surfacing after sign-off.
- **verify-work's answers come from a human.** In an interactive run they are the human's own
  answers given in this session. Under a human-supplied waiver each item is answered as waived per
  the recorded waiver fields, never as passed. With neither, verify-work is not called.
- **Never flip `status:` by hand.** verify-work's completion runs gsd-core's transition (ROADMAP,
  REQUIREMENTS, STATE, PROJECT); a hand flip with `frontmatter set` skips all of it and nothing
  reports the gap. Never append via quick-task tooling.
- **Commit message:** `docs(phase-{N}): phase verification report - {passed|failed}, {n/m} criteria`
  (`passed` only when the status is exactly `passed`; `n/m` from the verifier's score).
- **End-state check.** If gsd-core refuses the phase-completion write, follow assumption 15 in
  `gsd-core-assumptions.md` (this phase's rows only, then the rest of the transition by hand; never
  `--ws`). Either way confirm the ROADMAP progress row reads Complete, every REQUIREMENTS row for the
  phase reads Complete, and PROJECT.md is updated. A refusal is easy to see and can still leave only
  a checkbox ticked; the check is what stops that.
