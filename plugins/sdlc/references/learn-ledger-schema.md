# Learnings Ledger Schema

The file layout and item tags `learn` writes and reads. `extract` writes this shape; `promote`
parses it. The body schema never varies by source, so one reader parses every ledger.

## Files

- `.planning/learnings/YYYY-MM-DD-<scope>-<slug>.md`, one file per non-phase extraction. A single
  appended file would merge-conflict across isolated worktrees. Phase scope writes gsd-core's own
  `{N}-LEARNINGS.md` instead.
- `.planning/learnings/PROMOTED.md`, append-only `| date | item | source | target | commit |`, is the
  **authoritative** promoted/dismissed record: gsd-core overwrites `{N}-LEARNINGS.md` on re-run, so
  an inline marker alone vanishes. Still stamp `**Graduated:** {target}:{date}` or
  `**Dismissed:** {date}: {reason}` inline for interop. Never write STATE.md's graduation backlog.
- Frontmatter: `scope:` (re-invocable), `invocation:` (what was typed, if different), `sources:`,
  `counts:`.

## Items

Each item is `### Title`, gsd-core's Decisions/Lessons/Patterns/Surprises fields, `**Source:**`,
and these tags:

```text
**Severity:**  shipped-defect | human-correction | control-bypass | reverted | cost-only | note
**Cause:**     ai | human | process | tooling | ambiguous
**Audience:**  agent | contributor | operator    (comma-separated; first listed is canonical)
**Improvement:** workflow | bottleneck | request   (optional)
**Requested by:** <named person> (<role>), <date>, <receipt>   (required for request)
**Skill fit:** <existing skill> | new skill | product         (required with Improvement)
**Wait:** <N working hours>                                    (required for bottleneck)
```

## Tag rules

- **Severity needs a receipt** (commit SHA, PR comment URL, ticket key, session event) above `note`;
  without one, downgrade. A generated codebase map (`.planning/codebase/*`) is never a receipt: it is
  rewritten on every remap and can assert constraints that do not exist.
- **Cause** names whose behaviour produced the cost: `ai` (re-derived, forgot, defended a wrong claim,
  offered a menu instead of a recommendation), `human` (a changing decision, a slow review, a
  preference never captured), `process` (a gate in the wrong place, a handoff with no artifact),
  `tooling` (a limitation outside this project), `ambiguous` (say which). It routes; it never blames.
- **Audience** names whose behaviour changes: `agent` (a rule to follow), `contributor` (the why
  behind it), `operator` (a runbook for people who do not clone the repo). Different bodies for two
  readers means two items; the same body for both means one item whose first audience owns the text
  and whose others get a one-line pointer, never a copy. Canonical home by what can verify it:
  code-derivable structure is `contributor` (the generated architecture doc); controls and
  invariants are `agent` (`AGENTS.md`); procedures are `operator` (the wiki).
- **Improvement** records what the delivery system could do better: `workflow` (a manual, repeated
  step a skill could own), `bottleneck` (a wait, in working hours, naming what was waited on; mark a
  deliberate hold as deliberate), `request` (anyone asked for something, even if answered by hand).
  Skill fit `product` goes to the product backlog, never into a skill.
- **Working hours** follow the team's stated hours in `AGENTS.md`; if none are stated, report
  wall-clock and say so.

## Extraction roles

`extract` classifies each scope item to a role and resolves that role's model from
`.planning/config.json` (never hardcoded), passing the role's lens (the relevant `AGENTS.md`
section) in the subagent prompt:

| Role                 | Scope items                                    |
| -------------------- | ---------------------------------------------- |
| `learn-security`     | authorization, tenancy or money-path decisions |
| `learn-architecture` | long autonomous or milestone runs              |
| `learn-design`       | UI and design work                             |
| `learn-quick`        | short administrative sessions                  |
| `learn-standard`     | everything else                                |

A subagent gets the filter, redaction and severity rules verbatim. It reads for all four causes,
then makes a second pass for improvements: what was asked, where work waited, what was done by hand.
