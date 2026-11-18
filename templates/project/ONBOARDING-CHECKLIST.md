# Repo Readiness Checklist

The lead engineer works through this list and signs it before the first agent-delivered phase.
Each item names the evidence that satisfies it. An item that cannot be met yet is not skipped:
record it under "Recorded gaps" with an owner and a ticket, and say there what the gap allows
until it closes. Most items are build-plane controls (how changes are made); items 9 to 11 also
touch the operate plane (how the running system behaves).

## Repository controls

1. **Required status checks are defined and enforced.** The default-branch ruleset requires each
   check named in `repo.requiredChecks`, and the names match the CI job names exactly. Evidence:
   the ruleset export committed under `.github/rulesets/`, and one PR showing every check as
   required. Advisory checks and scanners are listed as advisory in `AGENTS.md`.
2. **Direct pushes to the default branch are blocked** and every change arrives by pull request
   with at least one human approval. Evidence: the same ruleset export.
3. **Commit signing is required on all branches, with an empty bypass list.** Not only on the
   default branch. Evidence: a signing ruleset export targeting all refs, and an unsigned test
   push that was rejected.
4. **Review-thread resolution is required** on the default branch, so a requested change posted
   as a review comment blocks the merge until resolved. Evidence: the ruleset export.
5. **Ruleset changes are change-to-change protected.** A human makes or directs every ruleset
   change, the export is committed on a reviewed PR, and the allowed merge method matches
   `repo.mergePolicy`. Evidence: the committed exports match what the host reports today.
6. **The agent credential has no repository administration rights and a distinguishable
   identity.** Agent commits and tracker writes are attributable to the agent, not to a person.
   If agents run on a human's credentials for now, record the gap in `AGENTS.md` in the
   known-gap wording provided there, and list it below.

## Tracker

7. **Transitions are mapped by id.** `tracker.transitions.selected`, `.inProgress`, `.uat` and
   `.done` hold transition ids read from the tracker's API for this project's workflow, and each
   was exercised once on a scratch ticket. The workflow has a UAT status and distinguishes
   Approved (a human clears work for release) from Done (the work released).
8. **Labels exist.** The provenance label (`tracker.labels.provenance`) and the four stage labels
   are created, and a saved filter on the provenance label returns the scratch ticket. The
   release-gate epic (`tracker.releaseGateEpic`) exists, or is recorded as `null` with the reason.

## Environments and secrets

9. **Every environment is classified.** Each entry in `environments` has a data class and a
   promotion mode, the `AGENTS.md` environment table matches it, and an environment that does not
   exist yet is listed as such. Any environment holding real data is named explicitly.
10. **Secrets handling is in place.** Secret-bearing files are gitignored, secret scanning runs
    in CI, agent permissions deny reading env files, and scripts read keys by name. Credentials
    for a hosted environment live outside any file a framework auto-loads. Evidence: the ignore
    rules, the scanner job, and the agent permission settings.
11. **Destructive paths are guarded.** Any script that resets, wipes or reseeds a hosted
    environment refuses targets outside an allow-list and requires a typed acknowledgement of the
    target. Evidence: the script's guard and its test, run against stubs.

## Review and verification

12. **Review coverage is named.** `AGENTS.md` states who or what reviews phase work and work that
    arrives outside a phase. Advisory AI review is not counted as coverage.
13. **Verification tiers are real.** The commands in `AGENTS.md` run on a clean clone,
    `verification.localStack` brings the stack up (or is `null`), and `verification.preview`
    matches what a PR actually gets. A local tier that differs from CI is recorded as such.
14. **The engine and plugin are installed.** gsd-core is installed globally at or above
    `engine.gsdCoreMinVersion`, not vendored, and the `sdlc` plugin is installed from the
    engagement marketplace. `.sdlc/config.json` validates against the plugin's schema.
15. **Instruction files are complete.** No `FILL:` marker remains in `AGENTS.md` or `CLAUDE.md`,
    and the named owners in `owners` are individuals who know they are named.

## Recorded gaps

List each unmet item: number, what is missing, what it allows meanwhile, owner, ticket.

1. (none recorded)

## Sign-off

Signed by the lead engineer named in `owners.leadEngineer`. An agent prepares the evidence for
this checklist; it does not sign it.

- Name:
- Date (ISO 8601):
- Commit this was verified against:
