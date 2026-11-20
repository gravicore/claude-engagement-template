> **Scope of this file.** AGENTS.md is the complete, self-contained account of this project:
> stack, structure, conventions, review discipline, security invariants, environments, process.
> Any agent or human contributor can work from this file alone; it never depends on, and never
> points to, a particular tool's configuration. Instructions that exist only because of a specific
> agent tool (its commands, skills, config directory, model wiring) belong in that tool's own
> file, which is free to include this one. When adding a rule, ask: "would this still be true with
> a different agent, or none?" If yes, it goes here; if no, it goes in the tool's file.
>
> **How rules are written.** One tight rule, then a one-line "Why" naming the failure it prevents.
> A rule without a why gets deleted at the first inconvenience. Replace every FILL comment block
> before the first agent-delivered phase. Remove a starter rule only by decision, recorded in the
> commit that removes it. Project coordinates (tracker, repository, environments, owners) live in
> `.sdlc/config.json`, not in this prose.

# Human Gates

Five acts always wait for a named human, whatever any config, skill or instruction says: merging
a pull request, recording UAT sign-off or approval, closing a ticket, publishing a release, and
changing a repository ruleset. An agent gathers the evidence, presents it and stops; gathering
evidence for a gate is not passing it, even when the gathering was delegated. Why: a checklist
with nothing pending is not a signature.

# Commands

<!-- FILL: one line per command a contributor needs, exact and copy-pasteable: dev server, build,
lint, type check, unit tests, the local-stack command (matches verification.localStack in
.sdlc/config.json), and what the pre-commit hook runs. State ports and required tools. -->

# Stack and Structure

<!-- FILL: framework and language versions, datastore, auth provider, hosting, path aliases.
Then a short map of the top-level directories and what each owns. If a framework version
differs from what an agent's training data assumes, say so first and point at the docs. -->

## Technology rules

<!-- FILL: stack-specific footguns, each written as rule + why, each earned by a real defect.
Framework, database, styling and infrastructure rules go here and nowhere else. Add one the
second time a class of mistake recurs. -->

Starter rules that hold on most stacks. Confirm each against yours, then keep or delete it:

- **An unpaginated read is silently capped somewhere.** Never pull rows and compute in
  application code without paging or pushing the predicate into the query; state the cap per
  environment. Why: totals and existence checks go wrong past the cap with no error.
- **A conditional write that matches nothing usually reports success.** Read back what changed
  and report current state on a zero-row match. Why: a transition answers 200 and changes nothing.
- **A failed read never renders as "no rows".** Surface an explicit unavailable state; an export
  answers an error with no file. Why: an empty table and an outage look identical to the user.
- **Know how your transport serializes money.** If decimals arrive as strings, coerce before
  arithmetic and do the arithmetic in integer minor units. Why: row cells render correctly while
  every total is wrong, so visual QA cannot catch it.
- **Never swallow errors broadly.** Catch the one expected case and re-raise the rest, in code,
  scripts and seed data alike. Why: a catch-all that logs a notice makes failure look like success.

## Request-path cost

**The cost of serving a request must be a function of the request, never of the tenant's
lifetime history.** Three shapes are prohibited on any request path: (A) a datastore call inside
a loop whose count is the number of rows in the result; (B) a read-everything-in-pages loop with
no predicate narrowing it to the request's scope (paging fixes truncation, not cost); (C) a user
filter applied in application code after an unscoped fetch. Push the loop into one aggregate
that runs with the caller's own rights, or carry the filter in the query. Verify structurally
first (name the bound of every await-in-loop and the predicate of every paged loop); the
round-trip count must be identical between a small fixture and a growth fixture. A bounded,
chunked loop gets a named exemption citing its bound, never a blanket one. Why: this defect
passes every test on demo data and is found by a human noticing a page feels slow.

# Code Style

<!-- FILL: naming, import order, file layout, documentation comments, and the single approved
path for each cross-cutting concern (form validation, file export, logging, data access). -->

# Testing

<!-- FILL: framework, where tests live, how to run one file, what the shared setup provides,
and which tier (unit, data layer, local stack, preview) catches which class of defect, with the
cost of each. Name any local tier that is not CI-equivalent (a different runtime pin, a stubbed
service). Push-and-wait is the slowest way to learn what a local check knows in seconds. -->

## Test integrity

- **Import the real exported function or handler. Never re-implement its logic in the test.**
  Why: a logic-mirror test drifts and then asserts the old behavior, staying green after the fix.
- **A mock must honour every predicate the assertion depends on.** A filter that is a pass-through
  no-op makes the test blind to a dropped tenant or status filter. A mock in front of a
  constraint returns the same error the real constraint would. Why: a write path shipped
  completely dead behind a mock that never inspected its input.
- **Prove a new test can fail.** Reintroduce the bug, confirm the right test goes red, restore,
  and state that you did. Why: a test written against already-correct code demonstrates nothing.
- **Never prove a guard on a destructive or hosted path red by running it for real.** Run the
  mutated copy against recording stubs with no network, or mutate the guard's input. Why: a
  guard removed to prove its test red lets the script reach the target it guards.
- **A known open gap is encoded as an expectation, not a failure, and an empty fixture is
  INCONCLUSIVE, never PASS.** A gap tied to a ticket reports KNOWN-GAP; if it starts passing it
  reports FIXED and asks for the exemption to be removed. Why: the suite then records what is
  still owed, and silence is never read as coverage.
- **Scope a live query through a stable ancestor** when a page mounts several instances of one
  component. Why: a generic selector matches the wrong instance and reports a false result.

# Code Review

- **Every commit gets reviewed, especially work that never went through a phase.** Phase work
  carries review by construction; ad hoc and UAT-born commits do not. Review such a batch
  explicitly before its PR is marked ready. Why: the unreviewed tail of one release carried
  authorization holes and arithmetic errors that the reviewed half of the same PR did not.
- **Advisory AI review is not review coverage. Never count it.** Neither is a green CI suite or
  a satisfied product owner. Why: none exercises authorization, arithmetic at scale or tests.
- **Scale a review to the risk surface, not the line count.** Authorization and tenancy, data
  access rules and migrations, money arithmetic, and test integrity are separate lenses and get
  separate passes. Why: one generalist pass finds style issues and misses the class defects.
- **A review finding born in a phase's own code rides that phase's Story**; file a separate
  ticket only for a defect that predates the phase or belongs to other work. Why: a ticket per
  finding buries the board.

<!-- FILL: who or what provides review coverage today (named people or a named automated gate),
and which scanners are advisory rather than required. -->

# Verification Discipline

- **Walk the affected user's next step, not just the step you changed.** Verification stops at a
  completed workflow. Why: a transition can be correct while the feature after it is dead.
- **When a status value or guard changes, find every comparison site and report the full list.**
  Why: fixing the two reported sites strands the workflow one step later.
- **Demo data does not exercise scale.** Verify against multiplicity (several tenants, more rows
  than a page, more than one of everything), or state plainly that you did not. Why: every money
  defect found in review broke only on multiplicity.
- **"The environment can't do this" is a claim to test, not a reason to substitute static
  review.** Try, and say what failed. Distinguish an environment limit from an agent tool-allowlist
  gap. Why: an inherited environment claim propagates across phases as if it were evidence.
- **Verify the rendered or computed result, not the source string.** A class, flag or config
  value you wrote is not one that took effect; assert the output. Why: tooling silently drops or
  overrides what it does not recognise, with every gate green.
- **A count from a text search can be right and still support a false conclusion.** Ask what
  other spelling produces the same effect, count the raw construct as well as the wrapper and
  usages as well as declarations, and spot-check that counted code is reachable. Why: the gap
  between those numbers is the work the count missed.
- **A silent fallback hides a broken build.** When a feature degrades gracefully on missing
  input, confirm on a real deployment that the input is present. Why: a build misconfiguration
  then looks like expected absence of data.
- **A negative authorization result needs a paired positive control, same URL, same session**,
  and the gate must answer before the validator. Why: a 403 is equally consistent with a route
  that is broken for everyone; a malformed request must not reach further than a valid one.
- **For tracked work, check the artifact-backed gate first.** A live click-through supplements
  the phase's verification status; it never replaces it. Why: an improvised spot check misses a
  phase that has been waiting on a human since before the merge.
- **Report from the evidence, not from memory.** Read a check's output to its verdict line,
  quote identifiers from the tool that produced them, answer vendor-setting questions from
  current docs or a probe. Why: a remembered pass and a guessed identifier both read as fact.
- **Before handing an environment to a tester, measure it.** Count rows per data domain, confirm
  each role can read what it should, and read seeded workflow data back through the app as each
  role. Why: a provisioning flag or a green status says nothing about whether data landed.

# Security Invariants

- **A role claim is tenant-local, not global authority.** Every admin-gated route and data rule
  checks tenant type, and where relevant tenant id, as well as role. Prefer a guard that returns
  a discriminated scope so a forgotten tenant filter is a type error. Why: guards that read only
  the role are the most repeated authorization defect.
- **Fix the class, not the call site.** When you fix an authorization bug, ask which other layer
  and which other resources share the pattern, say what you checked, and verify at two levels:
  through the application and by a direct call to the layer underneath. Why: a hole patched at
  the route stays open through the data API while everyone believes it closed.
- **A critical control holds at the application layer and the data layer.** Money movement,
  separation of duties and tenancy are enforced in both. Why: any client credential that can
  reach the data API bypasses route code, so route-only enforcement is a UI convention.
- **Say which layer enforces a control when you claim it is enforced**, and name any identity
  that bypasses it. Why: auditors test the claim as written.
- **Application code that restates an authorization scope is diffed against the authoritative
  rule, field by field.** Why: a hand-rebuilt filter drops one anchor and leaks another tenant.
- **Never widen a status vocabulary without revisiting every rule that keys on status**, and
  enforce sequencing where the previous state is visible. Why: a new status becomes settable
  by anyone, with no audit record.
- **A broad write rule is often also a read rule, and a rule that reads data the caller can
  write is self-grantable.** When fixing one, check what it let the wrong role read. New
  callable surface is default-deny with explicit grants. Why: both shapes exposed other tenants'
  data behind a rule everyone read as write-only.
- **Invite and onboarding routes are a tenant boundary.** Re-verify their scoping whenever they
  are touched. Why: they are exercised rarely and reviewed as plumbing.
- **Agents never read a secret-bearing file, by any means.** Scripts read keys by name
  internally; a check on a secret is a length-only or names-only probe; capture the one field
  needed in the step that extracts it and never echo it. This covers throwaway local credentials
  too. Why: the habit carries over to a hosted key, and hand-rolled redaction misses real fields.
- **Pre-auth error messages expose two outcomes and no internals; post-auth messages are
  specific and actionable.** Before authentication, distinguish only "credentials rejected" from
  "could not complete", identically for unknown user and wrong password; never name a component,
  its state or a provider's raw error. After authentication, name what failed and what to do.
  Why: friendly pre-auth detail hands a stranger an operator's diagnosis.

<!-- FILL: project-specific invariants (which controls are money-moving or otherwise critical,
which identities bypass data rules, tenant model). One line each, with the enforcing layer. -->

# Control Planes

Every control sits on one of two planes. Name the plane whenever you write "control".

- **Build plane:** how the system is made and changed, enforced by the toolchain against
  contributors (code owners, branch protection, required checks, signing, pipeline secrets).
  Failure mode: a change reaches an environment without the scrutiny it was supposed to get.
- **Operate plane:** how the running system behaves, enforced by the software against its users
  and tenants (tenancy, dual approval, audit rows, retention, production access). Failure mode:
  a user does something they should not be able to do.
- **Compliance is not a plane; it is orthogonal to both.** Most regimes reach both (SOC 2 covers
  change management and production access alike; GLBA reaches runtime safeguards and secure
  development). Give two coordinates for every compliance claim: which plane, which regime. Why:
  inferring a plane from a regime name puts the control in the wrong place.
- **Neither plane is evidence for the other.** A reviewed, signed PR says nothing about whether
  tenancy is correct. Why: the two get traded off in audit answers.
- **A build-plane role is assigned by the review expertise a change requires, never by the
  runtime risk of the code.** Why: routing by business process cannot be applied from a file path.
- **An instruction an agent can edit is advice, not a control.** Pair every rule that matters
  with an enforcement point outside agent write access, and say so when none exists. Why: when
  instructions are edited, compacted away or ignored, something external must still say no.

# Environments

Say which environment you mean before judging risk. "Production" alone is ambiguous.

<!-- FILL: one row per environment in .sdlc/config.json: name, URL, data class (synthetic or
production), who may promote to it, how it is seeded. State which does not exist yet. -->

- **Synthetic and live are different risk regimes.** The same defect is sandbox hygiene in one
  and a reportable event in the other. Why: "we shipped it to prod" blurs the two.
- **A standing release-gate epic (`tracker.releaseGateEpic`) stands between synthetic
  environments and live production.** Nothing is promoted until its children are Done; a known
  defect may ride to a synthetic environment only if recorded. Why: readiness otherwise lives in
  memory.
- **A destructive operation on a hosted environment is a human act in a scheduled window.** Its
  script refuses any target not on an allow-list, requires a typed acknowledgement equal to the
  target's identifier (never a boolean, never exported), and the allow-list never gains live
  production. Why: a standing bypass turns one mistyped variable into data loss.

# Git and Worktree State

- **Verify branch state; never assume it.** Before claiming a push is visible or building on a
  branch, fetch and read the actual ref. Why: more than one local view of the repo exists
  whenever a worktree or autonomous run is in play, and the stale one looks current.
- **One writer per checkout.** Each agent or human gets its own worktree; check the staged diff
  before every commit. Why: two writers sweep each other's uncommitted changes into their commits.
- **Each commit leaves the repo verifiable; documentation follows the code it describes.** Why:
  a reviewer validates the tree at that commit.
- **Hook and signing bypass flags are per-instance, never standing.** Re-verify the blocker
  exists now and ask before bypassing. Why: a remembered workaround hollows out the control for
  everyone, and agents produce most commits.
- **Hand-numbered identifiers collide under parallel work.** Gate migrations and similar
  sequences with a filename check in CI. Why: it fails late and looks like an infrastructure fault.

# Pull Requests

- **Merging is a human decision.** An agent prepares a merge-ready PR and stops; it never merges
  and never offers to. Why: the recorded human review is the build-plane control.
- **Merge-ready means every required check has reached a final state**, not that some passed.
  Name the checks still outstanding when reporting earlier. Required checks are listed in
  `repo.requiredChecks`. Why: a pending check is not evidence either way.
- **One combined PR.** Planning artifacts ship with the code they describe, and follow-up work
  in one continuous session stays on the branch and PR already open unless it is truly
  unrelated. Branch names and creation belong to the delivery engine's config. Why: splitting by
  task multiplies review and CI without buying independent revert.
- **PR titles carry the tracker key. No checkboxes in a PR body.** Write the body as prose and
  bullets, and update its open-decisions list the session a decision closes. Why: a body
  checklist has no resolve state and reads as a gate it is not.
- **A requested item is a review-thread comment.** Where thread resolution is required, post
  one task comment per change request, edit it to tick sub-items, and resolve it only when the
  work is verified. A blocking wait on a person is a task line too. Conversational comments use
  numbered options, never checkboxes. Why: only an unresolved thread actually blocks a merge.
- **Own the thread and verify live before claiming fixed.** Acknowledge first, post status in
  the same thread through to verified, and never ask a reviewer to re-check on faith. Why:
  silence until done reads as nothing happening.
- **"We already decided this" is a claim to check against the record.** Search the person's
  earlier statements and the artifacts that encode the outcome before answering; raise a
  decision that lives only in comments to a requirement. Why: grooming carries the old default on.
- **Chat mirrors are notify-only.** A short pointer to the PR naming the requester, with an
  explicit channel mention when the purpose is to notify. Resolve handles at action time; never
  keep a glossary. Why: duplicated write-ups drift, and a wrong mention pings a stranger.
- **Commit signing is required on every branch, with no bypass role.** The repository ruleset
  must enforce it; do not assume it does. Do not promise a merge will pass on a branch carrying
  unsigned history; check the ruleset. Why: an author field is an unauthenticated string, and
  gating only the default branch makes signing a merge-time surprise.

  <!-- FILL: name the ruleset that enforces signing on every branch and confirm its bypass list
  is empty, or record the gap (for example a plan that cannot enforce it) as a named, owned risk
  with a remediation date. Until this is filled, treat signing as a requirement not yet enforced. -->

- **Ruleset changes are human-gated and never an agent act.** An agent never creates, modifies,
  disables or adds a bypass to a ruleset; a blocked push is a finding to report. Every change is
  made or directed by a human, re-exported on a reviewed PR and visible in the audit timeline.
  Admin bypass is for infrastructure failure, with the reason recorded, never to override review
  findings. Why: the ruleset is the enforcement point that remains when instructions fail.
- **Agent identity is distinct from human identity.** Autonomous work is distinguishable from
  human-authored work in commits, attestations and the tracker; agent credentials do not carry
  rights to alter the controls that bind them. Why: otherwise an agent attests, in a person's
  name, to work that person has not read.
- **A scanner's "new" alert may be an old one re-attributed.** Compare against the default
  branch before treating it as a blocker. Why: that deserves a ticket, not a scramble.

<!-- FILL: name the agent credential and its scope. If agents run on a human's credentials,
record the gap in these words instead: "Known gap, on the record: agent sessions run on a
human's admin-scoped credentials, so the ruleset and identity rules above are self-enforced.
Real enforcement needs a dedicated agent credential without repository administration rights.
Until it exists, the external control constrains what agents push, not what they could
administratively undo." Also record the emergency-override procedure and where it is logged. -->

# Tracker Conventions

Coordinates and transition ids come from `.sdlc/config.json`. Text fields are plain text: never
HTML-escape them, and say so when rendering cannot be verified through the API.

- **Ticket titles are headlines.** Three to five words stating the outcome; ASCII punctuation;
  no mechanism, file names or versions. Structural prefixes (phase, discipline) are deliberate
  exceptions; a bug may describe the defect. Why: every branch and PR inherits the title.
- **Status is the coarse gate; labels carry live agent activity.** A skill adds a stage label
  when its agent starts an activity and removes it, by name, when done. Why: the board shows
  the gate and what is happening without inventing statuses.
- **UAT is the single human-approval gate, referenced by transition id
  (`tracker.transitions.uat`), never by display name.** There is no separate code-review status.
  Why: display names change and differ per site; two approval gates split one decision.
- **Approved and Done are not interchangeable.** Approved is a human clearing work for release
  and is never a skill's transition. Done asserts the work released to a named environment. Why:
  both show as complete on a board, and conflating them closes tickets that never shipped.
- **The agent-provenance label (`tracker.labels.provenance`) is permanent.** Every ticket an
  agent writes to carries it from the first write: read labels, append, write back the full set.
  It is a floor, not a claim about extent, and nothing ever removes it. Reads are not touches.
  Why: stage labels vanish when work completes; one query must answer "what did an agent touch".
- **Assignee is set the moment work starts**, and never reassigned if already set. Why: an
  unassigned ticket with work underway reads as untracked.
- **A decision that changes scope or acceptance after work or testing has begun is recorded
  twice.** An immutable comment states what changed (old and new text), why, when, the source,
  and who decided, naming an individual, never a team or role alone. The description is then
  amended to read cleanly as the current spec, approved by the ticket's owner. A reversal is a
  new comment, never an edit. Why: an edit alone keeps no reason; a comment alone leaves testers
  failing correct work against a stale spec.
- **Closing a ticket.** Done is written only when a release exists and the work is reachable in
  it; the transition names the environment and the release; it is the terminal write of a
  close-out, with nothing after it. Why: a later failed step leaves tickets claiming a release.

# Delivery Workflow

The process is written down as executable workflow definitions (the `sdlc` skills). Read the
relevant one before doing that kind of work; they are the process of record whether or not your
tooling can invoke them. Check them before designing a manual scheme for parallel or isolated
work: isolated worktree delivery already exists. In lifecycle order:

| Workflow             | What it does                                                                                                                                                                                       |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `epic-writer`        | Interviews the product owner to produce an intent-driven Epic: intent, user value, success criteria, out of scope. No implementation detail                                                        |
| `milestone-init`     | Turns an Epic into a milestone roadmap and requirements through an interactive intake; requirements are product-owner intent and are never derived unattended                                      |
| `milestone-setup`    | One-time kickoff: milestone branch, epic groomed against the codebase, a Story per phase, every phase planned, a setup PR. The setup PR merges before phase work begins                            |
| `milestone-sync`     | Creates or updates one Story per phase, links them to the Epic and each other, moves them to Selected, writes keys back into the roadmap                                                           |
| `milestone-planner`  | Discuss (sequential, interactive) then plan (dependency-ordered waves) for every pending phase                                                                                                     |
| `milestone-run`      | Runs all pending phases in order, phase-run then phase-complete, pausing or halting on a blocker                                                                                                   |
| `epic-run`           | Runs a whole epic unattended in one isolated worktree, setup through a draft PR per phase; every human gate halts the run and hands back                                                           |
| `phase-run`          | Primary entry point: one phase from zero to draft PR (discuss, plan, execute, ship draft), skipping stages whose artifacts exist                                                                   |
| `phase-complete`     | Takes an executed phase to Complete: an autonomous Verify lane (mandatory, produces the verification artifact), then the human UAT lane (skipped only by a dated waiver); moves the Story to UAT   |
| `phase-review-fix`   | Post-ready loop: collect AI, human and UAT findings; fix, re-verify, re-review until clean                                                                                                         |
| `story-deliver`      | Delivers one ticket as a change in its own worktree, branch and PR; the ticket description is the spec; escalates to phase planning when too big; never merges                                     |
| `story-update`       | Enriches a Story with post-planning detail (points, estimate, description) from plan artifacts or git state                                                                                        |
| `uat-session`        | Bootstraps a UAT session on a PR's preview: verifies data and identity coverage, spot-checks gates with paired controls, watches comments and CI; never fixes code inline                          |
| `milestone-review`   | Readiness review of the release PR across all phases: verification sweep, milestone audit, review coverage for out-of-phase commits, epic brought current; writes READY or NOT READY, never merges |
| `milestone-complete` | The repo half of a close-out, on the open close-out PR before its merge: learnings, instruction-file updates, docs refresh, archive, the Open at Release list                                      |
| `release-close`      | Everything after a release's last merge, changing no file: notes, the human-gated release, chat pointer, shipped tickets Done on per-ticket human selection, workspace pruned, Epic Done last      |
| `learn`              | `extract` turns evidence into a dated learnings ledger and never edits a governing file; `promote` is the human gate that proposes diffs to instruction files                                      |
| `docs-sync`          | One entry point to make the docs true again: code-derived docs regenerated and fact-checked, operator and contributor docs routed to their homes                                                   |

# Gates That Cannot Literally Hard-Block

A requirement can be worded as absolute while the thing enforcing it is a skill the agent itself
runs. A soft warning overclaims; a hard block with no exit stalls legitimate work. Use this:

1. A loud, specific notice naming exactly what is missing.
2. A typed acknowledgement of the exact subject (`override 12`), never a bare yes and never a
   generic string. Anything else stops the skill.
3. A persisted trace file in the phase directory recording date, operator, the typed text
   verbatim and a one-line reason.

The release close-out counts the trace files and reports the number, zero included, as risk
accepted. Record the requirement as mitigated, not literally satisfied. Why: routine overrides
are evidence the gate needs hardening, and that evidence has to be countable.

# Releases

- **A milestone ships through two PRs, and nothing changes a repo file after the second
  merges.** The release PR carries the features and merges first so the target environment can
  be tested. The close-out PR carries everything after: follow-up fixes, learnings,
  instruction-file changes, docs, archive, the Open at Release list. After it merges only
  non-file acts remain. A later defect is a new change with its own PR. Why: a close-out that
  edits files after the last merge needs yet another PR, indefinitely.
- **The release is an explicit, human-confirmed act; the delivery engine does not tag.** Why: a
  release marker records which version reached which environment and should be as deliberate as
  the merge; a step that depends on someone remembering does not happen.
- **Release notes are canonical in the release**, composed from what merged, after the merge.
  Chat gets a pointer. Notes record what was done and name anything risk-accepted; known-open
  items are recorded in the close-out PR with ticket links, never dropped. Why: a record that
  omits shipped defects is a marketing document.
- **Learnings are extracted every release and feed the instruction files.** Anything that would
  change how the next milestone runs lands here (or in the tool's file) as a rule with a why.
  Why: skipping this step is how the same defect class recurs.
- **A phase with no verification artifact, or awaiting human UAT with no dated waiver, means the
  milestone is not shipped.** The autonomous verdict must pass on its own merit; the human
  verdict may be waived only with date, person and reason, and the waiver appears in the notes
  as risk accepted. Require each artifact to be named. Why: a gate that lists what it finds
  waves through a phase that has nothing to find.

# Known Tech Debt

<!-- FILL: one line per accepted shortcut: what it is, what it blocks or hides, the ticket that
removes it. Include disabled or advisory checks and anything suppressed in CI. An item with no
ticket is a decision nobody has made yet; say so. -->
