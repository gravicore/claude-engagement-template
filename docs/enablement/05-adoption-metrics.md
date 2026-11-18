# Adoption Metrics

Six signals. The purpose is to learn whether the process is working and whether the gates hold, not
to rank teams or to count agent output. No benchmark numbers are given: any figure from another
organization would be invented for this one. Baselines come from the pilot; targets are set by the
client sponsor after the pilot, and reviewed rather than imposed.

General rules: collect each metric the same way for every repository; record the definition used
next to every number; never use these to evaluate individuals; treat a sudden improvement in any
metric as a reason to audit the measurement first.

## The signals

### 1. Lead time, epic to release

What it shows: how long committed scope takes to reach a release, including waiting for humans.

Definition: elapsed time from the epic moving to its first in-flight status to the release being
published for the milestone it belongs to. Report the median and the spread, never the mean alone,
and split working time from waiting time at each human gate (waiting for review, UAT, release).

Collect: Jira status-change history for the epic (via a JQL export or the issue changelog) and the
GitHub release timestamp. Joining key: the epic key in the milestone and release record.

Good in the first 90 days: a recorded baseline from the pilot epic, and a visible breakdown showing
where time is spent. A shorter total is not the goal on its own; a stable or improving figure with
zero gate bypasses is. If lead time falls while bypasses rise, the process is failing.

### 2. First-pass verification rate

What it shows: how often a phase's autonomous verification passes without a fix loop.

Definition: phases whose first verification report has a passing status, divided by phases verified,
over a period. Record the number of fix iterations per phase alongside it.

Collect: the verification report committed in each phase directory (its status field and the count
of iterations in history), counted by a small script over the repository.

Good: a baseline from the pilot and a trend that is explained. A very high rate early on may mean
the checks are weak; sample a few passes by hand to confirm the verifier is looking at real behavior.

### 3. Human-gate bypass count

What it shows: whether the controls hold. This is a safety signal, not a performance signal.

Definition: the number of times any of the following occurred without a named human acting in
session: a merge by an agent identity, a UAT or acceptance verdict recorded by an agent, a ticket
closed or moved to a done state by an agent, a release published by an agent, a ruleset change by an
agent identity, a commit made with signing disabled, or a pre-commit or CI hook skipped.

Collect: GitHub audit log and PR merge actor; Jira history for transitions by the agent identity or
service account; commit verification status across merged commits; release author; scheduled search
of agent session transcripts for bypass flags, where the client retains them.

Good: zero, every period. Any non-zero value is reviewed as an incident, the cause is fixed in the
control (not just the instance), and the review is recorded. Do not trade this down to a target
other than zero.

### 4. Review findings per phase

What it shows: the quality of what reaches human review and where the process under-checks.

Definition: findings raised in review for a phase, by severity as defined in the review template,
and by lens (authorization, data, irreversible actions, test integrity, other). Report counts per
phase and the share found by humans after the autonomous checks passed.

Collect: the review report committed with each phase, plus PR review comments tagged by severity.
Keep the severity vocabulary closed, or counts cannot be compared across phases.

Good: a baseline and a trend. Zero findings on a phase with real changes is suspicious, not good.
A rising share of findings that autonomous checks missed points to a gap in verification, which
becomes a change to a skill or to `AGENTS.md` through the learnings step.

### 5. Defects escaping to UAT

What it shows: what neither automated verification nor code review caught.

Definition: defects raised during UAT for a phase or story that trace to the delivered change
(excluding changed requirements), counted per phase and classified by what check should have caught
them.

Collect: Jira bugs linked to the story or phase, created while it was in UAT, with a classification
label or field applied at triage. UAT findings recorded as comments on the same ticket count too, so
agree one place to record them.

Good: a baseline from the pilot and, for each escape, an entry in learnings and a decision about a
new check. The measure of success is that the same class of defect does not escape twice.

### 6. Provenance label coverage

What it shows: whether agent involvement is recorded on the board, which makes the other metrics
auditable.

Definition: of tickets with at least one agent write (a transition, comment, edit) or an agent
commit referencing the key, the percentage that carry the provenance label. The target for this
ratio is 100 percent, because the label is permanent and mandatory.

Collect: a JQL filter on the label for the numerator; for the denominator, tickets whose keys appear
as scopes in agent-authored commit messages or PR titles, plus tickets whose history shows writes by
the agent identity. Reconcile weekly during the first 90 days.

Good: 100 percent, with each miss explained. Tickets closed before the rollout are not backfilled, so
exclude them by date and say so.

## Reporting cadence

Weekly for the pilot team lead during Pilot; monthly to the sponsor afterward. One page: the six
signals, definitions used, any bypass incident and its fix, and the two most important learnings.

## What not to measure

Lines of code, number of agent sessions, tokens consumed as a productivity proxy, tickets closed per
person, or percent of code written by agents. These reward volume and invite gaming; they are
unrelated to whether the gates hold or the product is better.
