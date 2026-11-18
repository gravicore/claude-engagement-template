# Rollout Playbook

Six phases, each with entry criteria (what must be true to start) and exit criteria (what must be
true to move on). A phase that cannot meet its exit criteria is repeated, not skipped. Durations are
deliberately absent: they depend on the client's procurement and access cycles, and the pilot
supplies real numbers for planning Scale.

## Phase 1 - Readiness

Purpose: remove the blockers that otherwise surface mid-pilot, when they are expensive.

Entry: a named client sponsor and a named client platform lead; the consultancy has agreed scope in
writing.

Work:

1. Licensing. Confirm which Claude plan or API arrangement the client will use for developers, who
   buys it, and whether managed (organization-enforced) settings are available on that plan.
   UNVERIFIED - confirm against current docs: which delivery mechanisms for managed settings each
   plan includes. The managed-settings page lists server-managed settings (console), MDM and file
   delivery; plan eligibility must be checked with the vendor.
2. Data-handling terms. Client security reviews the AI vendor's commercial terms: retention,
   training use, subprocessors, regional processing, audit rights. See section 7 of
   `04-controls-and-governance.md`. This is the longest-lead item; start it first.
3. Access. Client GitHub organization (owner rights for the platform lead), Jira project and a
   service identity for the agent, repository and ticket access for the pilot team, Slack channel
   if used.
4. Toolchain inventory. For each pilot repository: language and build tooling, CI checks, branch and
   merge policy, local stack availability, preview environments, secret handling. This feeds
   `.sdlc/config.json` and shows early where the process will need a project-specific `AGENTS.md`.
5. Data classification of environments. Label every environment synthetic or production-like in
   writing. Agents work against synthetic data only until Foundation controls are evidenced.

Exit: terms reviewed and signed off by client security; access granted; inventory complete; the
pilot epic and pilot team chosen (see Pilot); environment classification recorded.

## Phase 2 - Foundation

Purpose: stand up the instance and the controls that bind agents before any agent writes code.

Entry: Readiness exit met.

Work: create the instance in the client's organization and distribute the marketplace
(`02-client-org-setup.md`); apply the controls in `04-controls-and-governance.md` sections 3 to 8
(rulesets, signing, agent credential without admin rights, secret handling, provenance label); fill
`.sdlc/config.json` for the pilot repository; install gsd-core globally on pilot machines; connect the
Jira integration.

Exit: the control evidence pack (see section 9 of `04`) exists and a client reviewer who did not
build it has read it; a deliberate test shows an unsigned push and a direct push to the default
branch are both rejected; a developer on a clean machine installs the plugin from the marketplace
by following the written steps only.

## Phase 3 - Pilot

Purpose: prove the process on one real epic with one team, paired with the consultancy.

Entry: Foundation exit met; pilot team has completed the engineer track labs (`03`, Session 1 to 3).

Work: the consultancy lead engineer and the pilot team run one real, modest-risk epic through the
full lifecycle: epic, milestone, phase planning, delivery, UAT, release, learnings. The consultancy
pairs on every gate for the first phase, then observes. Every deviation, workaround and
misunderstanding is logged; each becomes a fix to a skill, to `AGENTS.md`, or to training.

Exit: one epic released to the client's lowest-risk real environment; zero human-gate bypasses
(`05`); the learnings step produced at least one reviewed change to the instance; baselines for the
`05` metrics recorded; the pilot team lead states in writing whether they would continue.

## Phase 4 - Train

Purpose: move from one team to cohorts without the consultancy in every room.

Entry: Pilot exit met; trainers identified (train-the-trainer path, `03`).

Work: run role-based cohorts using the sandbox-repo labs. Trainers from the client teach with the
consultancy observing. Fix curriculum gaps found in the first cohort before the second starts.

Exit: each cohort member has passed the competency check for their track; client trainers have
taught a full cohort unobserved.

## Phase 5 - Scale

Purpose: add repositories and teams without diluting the controls.

Entry: Train exit met; an instance owner on the client side with capacity to review pull requests.

Work: onboard repositories in small batches. Each gets its own `.sdlc/config.json`, its own project
`AGENTS.md` for technology rules, and the same ruleset and signing controls. Decide per repository
whether it needs a preview environment and a local verification stack.

Exit: each onboarded repository passes the Foundation checks; the metrics in `05` are collected for
all repositories on one schedule; no repository runs with a control relaxed.

## Phase 6 - Operate

Purpose: hand the instance to the client so the consultancy is an upstream contributor, not a
dependency.

Entry: Scale exit met for the agreed repositories.

Work: transfer instance ownership (CODEOWNERS, ruleset administration, managed settings) to the
client platform lead; agree the contribution model (consultancy proposes by pull request, client
reviews and merges); agree a version cadence for the instance and for gsd-core (re-test the
assumptions each skill makes about the engine on every engine update, and on every marketplace
release); schedule a periodic review of controls and metrics.

Exit: the client has merged a change to the instance without the consultancy; the version cadence
has run once end to end.

## RACI

R = does the work, A = accountable (one per row), C = consulted, I = informed.

| Activity                                       | Client sponsor | Client platform lead | Client security/compliance | Consultancy lead engineer | Pilot team |
| ---------------------------------------------- | -------------- | -------------------- | -------------------------- | ------------------------- | ---------- |
| Licensing and plan decision                    | A              | R                    | C                          | C                         | I          |
| AI vendor data-handling review                 | I              | C                    | A/R                        | C                         | I          |
| Instantiate instance, marketplace distribution | I              | A/R                  | C                          | R                         | I          |
| Rulesets, signing, agent credential            | I              | A/R                  | C                          | R                         | I          |
| Managed settings policy                        | I              | A/R                  | C                          | R                         | I          |
| Control evidence pack                          | I              | R                    | A                          | R                         | I          |
| `.sdlc/config.json` and project `AGENTS.md`    | I              | C                    | I                          | R                         | A          |
| Pilot epic delivery                            | I              | C                    | I                          | R                         | A          |
| Merge, UAT sign-off, ticket closure, release   | I              | C                    | C                          | C                         | A          |
| Training delivery                              | I              | R                    | C                          | A/R                       | R          |
| Metrics collection and review                  | A              | R                    | C                          | R                         | C          |
| Instance ownership after handover              | I              | A/R                  | C                          | C                         | I          |

Note that the last "Merge, UAT sign-off" row is accountable to the pilot team's named humans, never
to an agent and never to the consultancy: the human gates stay with the client's people.
