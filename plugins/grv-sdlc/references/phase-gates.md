# Phase Gates: Design Gate and Plan-Quality Gate

Detail for `grv-phase-run` steps 5 and 8. The skill states when each gate fires and what it does on
failure; this file holds the full criteria and the reason for each.

## Design gate (step 5)

Fires only when the ROADMAP Phase {N} section has `**UI hint**: yes` and the phase has no
SUMMARY.md yet. It sits before the stage that consumes design findings, because a gate after
planning discovers a shortfall only once the findings are spent.

- **Pass:** the project's staged-design record (location per the project's `AGENTS.md`) has a
  current entry for phase {N} covering every screen the phase needs. Log the coverage figure.
- **Partial coverage is a soft block, never a pass.** A missing or unparseable record is a block
  (fail closed). Splitting execution (some screens designed, some guessed) or approximating the gap
  by analogy are both ways of building undesigned screens; stage the missing design instead.
- **The notice.** A loud fenced block naming the phase, the coverage figure or "no staged design",
  the undrawn screens, and: `To proceed anyway, type exactly: override {N}`.
- **Only the exact string `override {N}` is accepted**, never yes/no or a generic phrase: a typed
  phase number proves the operator read which phase they are overriding. Anything else stops the
  skill with labels unchanged and says to stage the design and re-run. A second mismatch means the
  operator did not intend the override.
- **The trace.** On override, ask a one-line reason, then write
  `{phase_dir}/{padded}-DESIGN-OVERRIDE.md` with: ISO date, phase, Story key, operator
  (`git config user.name`), the acknowledgement verbatim, the reason, the coverage at override time,
  and the line `Executed without a full-coverage staged design.` `grv-release-close` counts these
  files, zero included, in the Release's Risk Accepted section: routine overrides are evidence the
  gate needs hardening.
- **Autonomous runs halt** (`design-gate`). The override is a human act; an agent never writes the
  trace.

## Plan-quality gate (step 8)

Checked only for a plan authored in this session. Four properties:

1. **Tracer first** for UI-hint phases: plan `{N}-01` implements one representative site, verified
   live (the project's run per `{config: verification.localStack}` or the preview), and is the sole
   occupant of its wave; sweeps follow in a later wave. A wrong pattern caught on one site is cheap;
   caught after a sweep it is hundreds of sites.
2. **Scope counts are re-runnable**: any "N sites in M files" claim cites a committed probe script,
   and closure re-runs it and separately measures the semantic property. A grep can count correctly
   and still miss a differently spelled equivalent.
3. **A falsifier on every success criterion**: the property, the measurement, and how the
   measurement could read true while the property is false. Empty or restated means the plan
   checker missed it.
4. **Red/green for new guards and gates**: the verify block names the mutation that makes the check
   fail, and SUMMARY.md must record the red output. A guard never seen failing has demonstrated
   nothing.

On failure the skill stops with `run gsd:plan-phase {N} --gaps to address {finding}`; under
`--autonomous` it retries once with the finding named, re-checks, then halts `plan-quality`. Never a
loop.
