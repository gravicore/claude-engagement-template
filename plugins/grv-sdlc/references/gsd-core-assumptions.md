# gsd-core Behaviours the grv-sdlc Skills Depend On

`grv-sdlc` never patches or vendors gsd-core. It consumes the global install and wraps it. The
coupling is to gsd-core's **behaviour**, and that coupling is invisible until an update breaks it.
Where possible the skills consume gsd-core's own published recommendation (for example the
`next_command` field of `verification status`) instead of reimplementing its routing, which is the
most update-resilient posture available.

**Re-test every item below on every gsd-core version bump**, and record the version it was
re-verified on in the consuming repo (`{config: engine.gsdCoreMinVersion}` is the floor the skills
were last verified against). A behaviour that changed is a skill change, not a footnote.

## Install and the `gsd_run` shim

- gsd-core is installed globally (`npx @opengsd/gsd-core@latest --claude --global`) and resolves at
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs`. Every developer machine needs it;
  it is the prerequisite for every `gsd:*` / `gsd-*` command.
- Do not commit an eject of gsd-core into the consuming repo. A stale vendored copy silently
  overrides the global install.
- Every skill that shells out to gsd-tools defines the same two-line shim. Keep every copy
  identical:

```bash
GSD_TOOLS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/gsd-core/bin/gsd-tools.cjs"
gsd_run() { node "$GSD_TOOLS" "$@"; }
```

The skills deliberately do not use gsd-core's full resolver block: its first probes look for a
repo-local `gsd-core/` or `.claude/gsd-core/`, which are ejects this plugin forbids, so those
branches could only ever fire on a stray directory.

## Load-bearing behaviours

1. **`verification status <phase-dir>`** returns `{status, next_action, next_command}`. `missing` is a
   first-class value, distinct from `human_needed`, `gaps_found` and `stale`. `--pick status` yields
   the bare value, and a leading `query` is stripped (`query verification status` equals
   `verification status`). Skills read this JSON, never `grep '^status:'`: a phase with no report
   prints nothing to grep and drops out of a listing silently. **A tool error is not a status**; any
   value outside `passed | human_needed | gaps_found | stale | missing` means the environment is
   broken (for example an untrusted tool-manager config printing an error) and must be fixed first.
2. **Unfiltered `execute-phase` self-heals**: when every plan has a SUMMARY.md and no VERIFICATION.md
   exists, it skips wave execution and resumes at the verification gates. This is the only path that
   authors a VERIFICATION.md (via `gsd-verifier`).
3. **A filtered run (`--gaps-only`, `--wave`) exits before those gates** and can never produce a
   report. A skill relying on a filtered run to close a verify gate is broken.
4. **`gsd:verify-work`** writes `{phase}-UAT.md` and only flips an existing `human_needed` to
   `passed`. It has no create path; against a missing report it is a silent no-op.
5. **`frontmatter set FILE --field F --value V`** is a per-field write that preserves other keys
   (the positional form is rejected). This is what lets the skills add their own `uat:` and
   `uat_deferred_*` keys to a gsd-core artifact. Most fragile assumption: if a future verifier
   rewrites that frontmatter wholesale, `uat:` vanishes silently. The failure direction is safe (a
   lost waiver makes the milestone gate stricter), but check it.
6. **`discuss-phase --auto` always chains into plan-phase**, which bypasses the per-stage gates the
   phase skills enforce. Discuss therefore always runs with a human present; no skill passes `--auto`.
7. **Milestone branch slug derivation.** gsd-core's commit-time branch alignment derives `{slug}` by
   parsing the roadmap's milestone heading text (lowercase, non-alphanumeric runs to one hyphen,
   trimmed, 60-character cap). It has no resolver for custom template tokens, so a tracker key must
   be part of the heading text itself (`### <marker> v{N} {EPIC-KEY} {Name}`), never a template
   token. When early commits land before the roadmap section exists, gsd-core creates or switches to
   a wrongly slugged branch; the skills re-check the branch after every committing step.
8. **`gsd:pr-branch` is a no-op under `branching_strategy: milestone`**: it builds a filtered branch
   that `gsd:ship` never consumes. Skills skip it in that mode.
9. **Codebase drift gate** (`verify codebase-drift`, run by execute-phase) keys on
   `.planning/codebase/STRUCTURE.md` and silently self-disables when that file is absent. Once it
   exists the gate reads `last_mapped_commit` from its frontmatter; an unstamped map reports the whole
   repo as drift. A lost stamp is noisy; a lost STRUCTURE.md is silent, and that is the regression to
   watch for.
10. **`milestone complete <version>` archives every directory under `.planning/phases/`**, not only the
    milestone's own. It refuses to mutate without `--confirm` and accepts `--dry-run`: run the dry run
    first and read `would_archive.phases`. Workaround for a parked phase that belongs to another
    milestone: move it out of `.planning/phases/` (for example to `.planning/phases-parked/`), run the
    command, move it straight back before any further step.
11. **`query audit-open`** validates every `*-VERIFICATION.md` status against
    `passed | gaps_found | human_needed` and errors on anything else; one stray value blocks the
    close-out.
12. **`gsd-audit-milestone` report name** has been observed as `v{version}-v{version}-MILESTONE-AUDIT.md`
    while `gsd-complete-milestone` looks for `v{version}-MILESTONE-AUDIT.md`. Glob for
    `*MILESTONE-AUDIT.md`; never construct the name.
13. **STATE.md writers.** Some gsd-tools writers of `.planning/STATE.md` have dropped frontmatter
    blocks, reordered keys and truncated unquoted values at a space followed by `#` (YAML reads it as
    a comment) while reporting success. After any tool writes STATE.md, confirm the diff is what you
    expected; quote such values. Never run several planners that may all write STATE.md at once.
14. A gsd-core `--global` install may also install hooks into user-level settings; expect them after
    an update.
15. **`phase.complete` and workstream mode.** While any directory exists under `.planning/workstreams/`,
    gsd-core treats the project as being in workstream mode and `phase.complete` refuses to write the
    root ROADMAP.md and STATE.md. Never pass `--ws` unless the consuming repo has adopted workstreams.
    If the guard fires, hand-edit that phase's rows, cross-checked against gsd-tools' read-only
    progress queries, then continue the transition from its post-processing step.
16. **`gsd-tools windows append --kind deviation --phase N [--file F] [--line L] --description D`** is
    the append-only writer for the cross-phase register `.planning/WINDOWS.md` (`--kind`, `--phase`
    and `--description` required; `deviation` is one of its allowed kinds). Entries close with
    `windows fixed <id>` or `windows waive <id> "<reason>"`. `gsd:ship` blocks while `open_count` is
    above zero **only when the broken-windows ship hook is active** (`workflow.windows_enforce`), and
    then fails closed on an unreadable ledger; with no ledger, `open_count` is 0 and the gate passes.
    Never hand-edit WINDOWS.md to clear the count: the ledger re-validates its own counts. Verified
    against the local gsd-core 1.19.0 install (2026-11-18): `bin/lib/broken-windows.cjs`, the
    `windows` router in `bin/gsd-tools.cjs` and the ship hook in `workflows/ship.md`.

## Re-test procedure

On a version bump, for each item: run the smallest probe that shows the behaviour on a scratch copy
(never on live planning files), note held / changed, and update the affected skill in the same PR as
the version floor.
