# Enablement Guide

This folder is the playbook for rolling the `sdlc` skills out to a client's engineering
organization. It is written for the people who run the rollout (consultancy and client), not for
the skill authors; authoring rules live in `docs/contributing/`.

Terms used throughout: "the client" is the organization that owns the instance, "the consultancy"
is the firm that contributes to it by pull request, and "the instance" is the client's copy of this
template repository.

## What is being rolled out

The instance is a Claude Code plugin marketplace. Its `sdlc` plugin carries delivery-lifecycle
skills (epic, milestone, phase, UAT, release, learnings) that drive the open-source gsd-core engine
and a Jira project. The process has hard human gates: an agent never merges, never records UAT
sign-off, never closes a ticket, never publishes a release and never changes a ruleset without a
named human. Everything in
this folder exists to make those gates real in the client's environment, not just written down.

Project coordinates (tracker project, repository, environments, owners) live in one file per
consuming repository, `.sdlc/config.json`, described in
`plugins/sdlc/references/config-contract.md`. No skill hardcodes a client value.

## Documents

| File                            | Purpose                                                                                                                    | Length          |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `01-rollout-playbook.md`        | Six phases with entry and exit criteria, plus a RACI table                                                                 | Read first      |
| `02-client-org-setup.md`        | Instantiating the repo, distributing the marketplace, managed settings, Atlassian connector, gsd-core, `.sdlc/config.json` | Hands-on        |
| `03-training-curriculum.md`     | Role tracks, labs on a sandbox repo, competency checks, train-the-trainer                                                  | Hands-on        |
| `04-controls-and-governance.md` | What must be true before agents write code in a regulated environment, and how to evidence it                              | Risk owners     |
| `05-adoption-metrics.md`        | Six signals, how to collect each, what good looks like in 90 days                                                          | Sponsors, leads |
| `06-faq-and-objections.md`      | Straight answers to the questions engineers and risk owners ask                                                            | Everyone        |

## Reading order by role

| Role                             | Read in this order                                     | Why                                                                    |
| -------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------- |
| Client sponsor                   | 06, 01, 05, 04 (sections 1, 5 and 9 only)              | Decide scope and accountability, then see how success is measured      |
| Client platform lead             | 01, 02, 04, 05, 03 (platform track)                    | Owns the instance, settings and controls                               |
| Client security or compliance    | 04, 06, 02 (managed settings, secrets), 01 (Readiness) | Needs the control list and the audit evidence before approving a pilot |
| Consultancy lead engineer        | 01, 02, 03, 04, 05, 06                                 | Runs the rollout end to end                                            |
| Pilot team engineer              | 06, 03 (engineer track), 02 (developer install only)   | Needs to start delivering, not to administer                           |
| Product owner                    | 06, 03 (product owner track), 05                       | Owns epics, UAT decisions and acceptance                               |
| Trainer (train-the-trainer path) | 03 in full, then 06                                    | Must be able to answer the objections in 06 unaided                    |

## Ground rules that apply to every document

1. Nothing here is a substitute for the client's own legal, security and procurement review. Where a
   document names a regime (for example SOC 2 or GLBA) it is an example of the kind of obligation,
   not a statement that the client is subject to it.
2. Claude Code behavior is stated only where it was checked against the official documentation.
   Anything not checked is marked inline as "UNVERIFIED - confirm against current docs". Product
   behavior changes quickly; re-verify before each rollout phase.
3. No benchmark numbers are given. Baselines come from the pilot (see `05-adoption-metrics.md`).
4. A control that an agent can edit is advice, not a control. Each rule in `04` is paired with an
   enforcement point outside agent write access.
5. Human gates are not configurable. If a client wants an agent to merge or close tickets, that is a
   different product and a different risk decision, not a setting in this one.

## Keeping this folder current

The consultancy owns these documents during Pilot and Train; ownership moves to the client platform
lead at handover (see Operate in `01-rollout-playbook.md`). Changes go through a pull request to the
instance like any other file. When Claude Code, gsd-core or the Atlassian connector changes
behavior, update the affected statement and its verification note in the same pull request.

## Verification status of Claude Code statements

`02-client-org-setup.md` and `04-controls-and-governance.md` state Claude Code behavior. Those
statements were checked on 2026-11-18 against the official documentation and carry that date.
Statements that could not be checked are marked inline with "UNVERIFIED - confirm against current
docs". Before Foundation starts, the platform lead should clear every such marker, either by
confirming it and removing the marker, or by recording the decision that follows from the answer.

The marketplace name, the install commands and the managed-settings keys are the items most likely
to change between Claude Code releases. Re-run the Foundation smoke test (end of
`02-client-org-setup.md`) after each Claude Code update that reaches the pilot machines.

## First week checklist in prose

Day one: the sponsor and platform lead read the documents listed for their role and agree who the
named humans are for each gate. Day two: security starts the vendor data-handling review, since it
has the longest lead time. Days three to five: the platform lead creates the instance, the
consultancy lead engineer drafts the pilot `.sdlc/config.json`, and both agree the pilot epic. Nothing
in the first week involves an agent writing code in a client repository.

## Who to ask

Questions about the process and the skills go to the consultancy lead engineer during Pilot and
Train, and to the client platform lead after handover. Questions about vendor terms go to client
security and compliance, who obtain the answer from the vendor in writing. Questions about
sponsorship, scope and priorities go to the client sponsor. If a question has no owner, that is a
gap in the RACI table in `01-rollout-playbook.md`; fix the table.
