# Controls and Governance

What must be true before agents write code in a regulated environment, and how each item is
evidenced. Regime names (SOC 2, GLBA, PCI DSS, HIPAA and similar) appear only as examples of what a
client may be subject to; this document does not determine which apply. Client security and
compliance decide that.

## 1. Principle: an instruction an agent can edit is advice

Every rule below is paired with an enforcement point outside the agent's write access, so that if
instructions are edited, compacted away or ignored, something external still says no. Changing the
external control must itself be a human-gated, recorded act. Agent credentials must not carry the
rights to alter the controls that bind them.

## 2. Two planes, named explicitly

| Plane         | What it governs                    | Enforced against               | Example controls                                                                                       | Failure mode                                                       |
| ------------- | ---------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------ |
| Build plane   | How the system is made and changed | Contributors, including agents | Rulesets, required checks, commit signing, code-owner review, secret handling in pipelines             | A change reaches an environment without the scrutiny it should get |
| Operate plane | How the running system behaves     | Users and tenants              | Access control and tenancy, dual approval on irreversible actions, audit trails, retention, encryption | A user does something they should not be able to                   |

Compliance is orthogonal to both: most regimes reach both planes. When writing "control" or
"compliance", state which plane and which regime. Neither plane is evidence for the other: a
well-gated pull request says nothing about runtime access control, and the reverse. This
instance and the skills are build-plane controls; the client's products carry their own operate-plane
controls, which the skills never replace.

## 3. Repository rulesets (build plane)

Required before any agent works in a repository:

1. Changes to the default branch only by pull request; direct push blocked.
2. Required status checks, listed in `.grv/sdlc.json` `repo.requiredChecks`, matching the ruleset.
3. Required review thread resolution, so unresolved feedback blocks merge.
4. Required commit signatures on every branch, with an empty bypass list. The purpose is to make
   authorship evidence rather than a claim; an author field alone is an unauthenticated string.
   State what a signature does and does not show: it ties a commit to a key, not to a human reading
   it. Check that the merge method in `repo.mergePolicy` is compatible with signing (a rebase merge
   re-creates commits and can fail the rule).
5. Code-owner review on the instance repository and on policy files.
6. Ruleset changes are made by a named human, re-exported to a reference file in the repository on a
   reviewed pull request, and visible in the platform audit log.

Availability of rulesets and signature enforcement on private repositories depends on the client's
GitHub plan: UNVERIFIED - confirm against current GitHub docs before Foundation.

## 4. Agent credential without admin rights

Agents run on a credential that can read and write code and tickets within scope but cannot
administer repositories, rulesets, branch protection, teams or secrets. Where sessions currently run
on a developer's own administrator credential, record that as an open risk with an owner and a
remediation date, because the rule is then self-enforced only. Preferred end state: a dedicated
machine identity or fine-grained token with no administration permission, which also makes agent
commits distinguishable from human ones. Use separate signing keys for agent identity and human
identity, or flag as an open decision if the environment forces them to be the same: never
silently attest that a human authored what an agent produced.

## 5. Human gates

Five acts are never performed by an agent on its own authority: merging a pull request; recording
UAT sign-off or acceptance; closing a ticket or transitioning it to a done state; publishing a
release; and changing a repository ruleset. Gathering evidence for any of them is allowed and is not the same act as approving them.
A checklist with nothing pending is not a signature. These gates are not configurable in
`.grv/sdlc.json`. External backing: the merge gate is the ruleset (required approvals, code-owner
review); the release gate is repository permissions on release creation; ticket closure and UAT
transitions should be restricted in the Jira workflow to human roles where the client's Jira
configuration allows it (UNVERIFIED - depends on the client's Jira permission scheme).

## 6. Secrets are never read by agents

Agents must not read environment files, key files, token files or connection strings by any means,
including shell commands. Scripts read secrets by name internally; an agent's check on a secret is a
length or presence probe only. Enforcement layers, strongest last:

1. Managed `permissions.deny` rules for the secret file patterns (verified on the permissions
   page: Read deny rules cover the built-in file tools, best-effort for Grep and Glob, and the
   file commands Claude Code recognizes in Bash such as `cat`, `head`, `tail` and `sed`; they do not
   cover a command that reads a file without naming it, a script that opens the file itself, or a
   Bash command written in another form).
2. Shell-level restriction through the sandbox filesystem settings: UNVERIFIED - confirm key names
   and coverage against the current sandboxing and settings documentation.
3. Agents run with no production credentials in their environment at all; scoped, short-lived,
   non-production credentials only. This is the control that still holds if the first two fail.
4. Secret scanning on the repository, with push protection if the plan offers it (UNVERIFIED - plan
   dependent).

Any secret an agent is shown is treated as exposed and rotated.

## 7. Data classification and AI vendor review

Classify every environment in writing: synthetic, internal, or production with regulated data
(personal, financial, health or similar). Agents work against synthetic data until the evidence pack
is accepted, and against production-class data only by explicit client decision recorded with a named
approver. Never put real personal or customer data in prompts, tickets, skill text or fixtures.

Before the pilot, client security reviews the AI vendor's terms and records the answers: what data is
sent (prompts, file contents, tool output), retention and deletion, whether inputs train models,
subprocessors and regions, incident notification, audit rights, and whether a zero-retention or
equivalent arrangement is available. These answers come from the vendor's current commercial terms
and security documentation; they are not asserted here (UNVERIFIED - obtain from the vendor). Also
review the Atlassian connector and any chat integration as separate data paths.

## 8. Provenance label

Every Jira ticket an agent writes to carries one permanent label (default `ai`, configured in
`tracker.labels.provenance`). It is applied on the agent's first write, added by read-modify-write so
no other label is lost, never removed, and means "at least one agent write happened", not a measure
of how much the agent did. Reads do not count. Backing control: a saved Jira filter and a periodic
audit that samples tickets with agent commits but no label (see `05`).

## 9. Evidencing each control for an audit

| Control                      | Evidence an auditor can inspect                                                      | Where it lives                                    |
| ---------------------------- | ------------------------------------------------------------------------------------ | ------------------------------------------------- |
| Rulesets and required checks | Exported ruleset file plus platform audit log of changes                             | Repository reference file; GitHub audit log       |
| Signed commits               | Sample of merged commits showing verified signatures; ruleset with empty bypass list | Commit history; ruleset export                    |
| Agent credential scope       | Credential permission listing; failed attempt to change a ruleset                    | Identity provider or GitHub settings; test record |
| Human gates                  | For a sample of tickets: named approver, timestamp, evidence link                    | Jira history; PR approvals                        |
| Managed settings             | The policy file or console export; `/status` capture from sample machines            | Policy repository; machine captures               |
| Secrets handling             | Deny rules in policy; scanner results; rotation records                              | Managed settings; scanner; secret manager logs    |
| Environment classification   | Signed classification table                                                          | `.grv/sdlc.json` and client register              |
| Vendor review                | Dated review record and the terms version reviewed                                   | Client risk register                              |
| Provenance label             | Query result and the sampling record                                                 | Jira filter; audit notes                          |

Keep the pack in one place, version it, and re-run the sampling on a fixed cadence agreed with the
client's compliance function. Evidence that exists only in someone's memory is not evidence.
