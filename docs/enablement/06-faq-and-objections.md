# FAQ and Objections

Honest answers. Where something depends on the client's environment or on a vendor, the answer says
so rather than guessing.

## Control and accountability

**Does the agent merge?**
No. Merging is a human decision, enforced by the repository ruleset (required approvals, required
checks, thread resolution), not by the agent's good manners. The agent prepares a merge-ready pull
request and stops. It also does not offer to merge. The same applies to recording UAT sign-off,
closing tickets and publishing releases.

**Who is accountable when an agent-authored change causes an incident?**
The same people who are accountable for a human-authored change that reached the same point: the
reviewer who approved the merge, the product owner who accepted it in UAT, and the owner of the
service. An agent is a tool, not a party. That is why approval must be a human reading the change,
and why a reviewer should refuse to approve what they have not understood. Agent involvement is
recorded (provenance label, distinguishable commit identity where possible) so accountability is
traceable, not diluted.

**Can an agent bypass a check if it is in a hurry?**
Not the external ones. Instructions to agents can be edited, so the real controls sit outside agent
write access: rulesets, signature rules with no bypass list, an agent credential without admin
rights, managed settings. Bypass flags (skipping hooks, disabling signing) are never standing
permission; a past workaround is not approval to repeat it. If the external controls are not in
place, `04-controls-and-governance.md` says to treat that as an open risk, not as covered.

**Why do humans have to approve things the agent already tested?**
Because testing is evidence, not acceptance. An agent can drive a browser and gather proof for UAT;
whether the product is acceptable is a decision that needs a person with authority and context.

## Data and vendors

**What leaves our network?**
Content that the agent reads or generates in a session (prompts, file contents, command output,
ticket text) is sent to the AI vendor for processing, and ticket content flows to and from Jira
through the connector. The exact retention, training and regional terms are the vendor's, and must
be obtained from their current commercial terms and reviewed by the client before the pilot: they are
not stated here (UNVERIFIED - obtain from the vendor). The mitigations within the client's control:
synthetic data in agent environments, no secrets or production credentials in the agent's
environment, managed settings that limit what can be read, and network controls where required.

**Will our code be used to train models?**
This depends on the plan and terms the client signs, not on this repository. Ask the vendor in
writing and record the answer in the vendor review. Do not assume either way.

**Can agents see customer data?**
Only if it is in their reach. The rollout starts agents on synthetic data. If a client later wants
production-class data in scope, that is an explicit, recorded decision by a named approver after the
control evidence is accepted.

## Engineering

**What if gsd-core changes?**
The skills depend on gsd-core's behavior, which is invisible until an update breaks it. The
instance records the minimum engine version the skills were verified on
(`engine.gsdCoreMinVersion`), and the version cadence in Operate includes re-testing the skills'
assumptions on every engine update before developers take it. The engine is not vendored into
repositories; each machine installs it globally, so an update is a deliberate act. If upstream
makes an incompatible change, the options are pin, adapt the skills by pull request, or stay on the
old version until adapted. The engine is open source; how long it will be maintained is outside the
consultancy's control, and the client should treat that as a dependency risk.

**Can we fork the skills?**
Yes: the instance is the client's own repository, and customization is expected. Two cautions.
Project-specific technology rules belong in the repository's `AGENTS.md`, not in a skill, which
keeps the skills reusable. And the human gates are not configurable; a fork that removes them is a
different process, and the consultancy's guidance and the training no longer describe it. Check the
licenses of the template and the engine before redistributing (UNVERIFIED - confirm license terms
with the consultancy and the engine's repository).

**Does this lock us in to the consultancy?**
It should not. The instance lives in the client's org, ownership transfers at Operate, and the
consultancy contributes by pull request like any other contributor. The Operate exit criterion is
that the client merged a change without the consultancy.

**Does it only work with Jira and GitHub?**
Today the tracker is Jira, and the repository host is GitHub. Other trackers would need new or
changed skills. Chat and documentation integrations are optional (`none` is a valid value).

**Our stack is not what the examples use.**
The skills are technology-neutral by design; stack rules live in `AGENTS.md`. The Toolchain
inventory in Readiness is where mismatches are found. Expect to write a good `AGENTS.md` per
repository: it is the highest-leverage file you will maintain.

## People

**Will this replace engineers?**
This rollout is about delivering with small senior teams and strong gates, not about reducing
headcount, and nothing in it claims a productivity figure. Be wary of anyone who offers one before a
pilot has produced baselines.

**What does a junior engineer do differently?**
Review discipline matters more, not less: a junior who approves what they cannot explain weakens the
gate. Pair juniors with reviewers during Pilot and use the review lab in Track B.

**It is slower at first.**
Often true, and expected: the first epic includes learning the gates. Measure lead time with the
waiting-for-human portion separated (`05`) before drawing conclusions.

## Operational

**What happens when Claude Code itself updates?**
Behavior of settings and plugin features changes between versions; some documented settings require
minimum versions. Pin or stage updates for the pilot, re-verify the statements in
`02-client-org-setup.md`, and keep the verification date on them.

**Where do we report a problem with the template?**
As an issue or pull request on the instance. If it is a defect in the upstream template, the
consultancy carries it upstream; the client's instance does not need to wait.
