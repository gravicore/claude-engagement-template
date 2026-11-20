# Training Curriculum

Four role tracks and a train-the-trainer path. Every lab runs on a sandbox repository, never on a
real client repository.

## The sandbox repository

Create one per cohort (or one per learner pair) from a small reference application with: a passing
test suite, two or three required CI checks, the same ruleset and signing controls as the real
instance, a `.sdlc/config.json` pointing at a sandbox Jira project, and synthetic data only. The
sandbox Jira project needs the real workflow, including the UAT transition, so learners meet the
real gates. Seed it with a prepared epic, a few small stories, and one deliberately broken story
(a requirement that contradicts the code) for the review lab. Reset it between cohorts.

Durations below are session lengths for planning; adjust to the cohort after the first run.

## Track A - Engineer

Audience: developers who will deliver stories and phases with agents.

| Session               | Length  | Outline                                                                                                                                                                    | Lab                                                                                                   |
| --------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| A1 Mental model       | 60 min  | The lifecycle; what an agent does and never does; the five human gates (merge, UAT sign-off, ticket close, release, ruleset change); why signed commits and rulesets exist | Read a finished sandbox epic end to end: find the gate evidence for each human decision               |
| A2 Setup and safety   | 60 min  | Install from the marketplace; `/status`; permissions; secrets are never read by agents; the provenance label                                                               | Install on a clean profile; trigger and observe a permission prompt; confirm a `.env` read is refused |
| A3 Deliver a story    | 120 min | Using `story-deliver`: ticket as spec, isolated worktree, branch and PR, verification, stopping at the gate                                                                | Deliver one small story to a reviewed PR                                                              |
| A4 When it goes wrong | 90 min  | Reading skill output; fail-closed config errors; stale branch or worktree state; unsigned commit rejection; what to do when a check is red                                 | Fix three seeded failures: missing config key, unsigned commit, red required check                    |
| A5 Learnings          | 45 min  | What the learnings step records and who reviews changes to the instance                                                                                                    | Propose one change to a sandbox skill by pull request                                                 |

Competency check (observed by a trainer): the learner delivers one story through
`story-deliver` to a reviewed pull request, with signed commits, every required check green and
the provenance label present on the ticket, without bypassing a gate, and then states which actions
remained for a human (merge, UAT sign-off, ticket closure) and who performs them. Any bypass flag,
force push, or self-recorded approval is an automatic fail and a retake.

## Track B - Lead engineer and reviewer

Audience: people who review agent-authored changes and own phase quality.

| Session                     | Length  | Outline                                                                                                                                      | Lab                                                                                |
| --------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| B1 Reviewing agent work     | 90 min  | Review by risk lens (authorization, data, money or irreversible actions, test integrity), not by line count; spotting tests that cannot fail | Review the seeded broken story; find the planted defect and the test that hides it |
| B2 Milestone and phase flow | 120 min | Milestone setup, phase planning, execution, verification report, the two verdict axes (autonomous verification and human UAT)                | Run one phase through verification on the sandbox                                  |
| B3 Gates and sign-off       | 60 min  | What a reviewer attests to by approving; UAT evidence versus UAT approval; why a ticket is closed only by a named human                      | Present evidence for a UAT item and record the human verdict yourself              |
| B4 Release                  | 90 min  | Release notes composed from the merge; the human-gated release; ticket closure by verdict, not by default                                    | Produce a release record for the sandbox milestone                                 |

Competency check: the reviewer reviews a pull request containing two planted defects (one
authorization-style, one test-integrity-style), finds both, rejects the change with written
reasoning, and then correctly performs a human sign-off on a clean one. They must also state, for
the clean one, what the approval means they have personally verified.

## Track C - Product owner

Audience: people who own epics, accept work and decide scope.

| Session                | Length | Outline                                                                                                                                    | Lab                                                                                         |
| ---------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| C1 Intent-driven epics | 90 min | Writing intent, user value, success criteria and out-of-scope so an agent team can plan without guessing                                   | Write an epic for the sandbox app and have the lead engineer attempt to plan from it        |
| C2 UAT and decisions   | 90 min | What UAT sign-off is; reading agent-gathered evidence critically; recording a decision that changes scope (what changed, why, who decided) | Run UAT on a delivered sandbox story; approve one item, reject one, record a scope decision |
| C3 Reading the board   | 45 min | Status, stage labels, provenance label, what each means for you                                                                            | Answer five board questions from a prepared Jira view                                       |

Competency check: the product owner accepts one item and rejects one with a recorded reason, and
writes a scope-change decision naming an individual decision-maker. Evidence gathered by an agent
is never accepted on the agent's say-so.

## Track D - Platform and security

Audience: client platform team, security and compliance staff.

| Session                           | Length  | Outline                                                                                                                  | Lab                                                                                            |
| --------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| D1 Control architecture           | 90 min  | Build plane versus operate plane; enforcement points outside agent write access; `04-controls-and-governance.md` in full | Map each control in `04` to where it is enforced and how it is evidenced                       |
| D2 Instance administration        | 120 min | Marketplace, managed settings, allowlists, update cadence, CODEOWNERS                                                    | Apply the managed policy to a test machine; verify with `/status`; break it and read the error |
| D3 Rulesets, signing, credentials | 90 min  | Required checks, signature rule, empty bypass list, agent credential scope                                               | Prove an unsigned commit and a direct push are rejected using the agent credential             |
| D4 Audit evidence                 | 60 min  | Building the evidence pack; sampling PRs and tickets                                                                     | Produce an evidence pack for the sandbox and have a peer try to refute it                      |

Competency check: the learner demonstrates that the agent credential cannot change a ruleset, can
show the audit timeline entry for a deliberate control change, and assembles an evidence pack that a
second reviewer can verify without asking the author questions.

## Train-the-trainer path

Client trainers are drawn from people who have passed their own track and, ideally, took part in
the pilot. Four steps:

1. Learn: complete tracks A and B (and D if a platform person).
2. Co-teach: teach one cohort alongside a consultancy trainer, splitting sessions.
3. Lead observed: teach a cohort alone while a consultancy trainer observes and gives written
   feedback against a rubric (accuracy of gate explanations, handling of objections from `06`,
   lab facilitation, correct refusal to demonstrate any bypass).
4. Certify: the client platform lead signs off the trainer; the trainer owns sandbox reset and
   curriculum updates and files improvements to this folder by pull request.

Trainer competency check: answers the questions in `06-faq-and-objections.md` unaided and
accurately, and recovers a live lab in which an agent produced something unexpected without
reaching for a bypass.

## Keeping the material true

Re-run the labs on a clean profile after every Claude Code, gsd-core or marketplace release that
the playbook's version cadence flags. A lab that no longer works is a documentation bug with a
named owner.
