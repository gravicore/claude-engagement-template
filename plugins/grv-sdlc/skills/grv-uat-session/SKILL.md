---
name: grv-uat-session
description: >
  Bootstrap a human UAT session for a phase PR in its own read-only, detached worktree: verify the
  preview's data and which identity unlocks which surface, spot-check admin gates with paired
  positive/negative controls, arm a PR-comment and CI monitor, open a browser as the right identity,
  and post the ready-for-testing notice. Suspected bugs are adjudicated and handed to
  grv-story-deliver; this skill never fixes code and never records the UAT verdict.
  Triggers on: "uat session", "start uat", "set up uat", "grv-uat-session".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Read
  - Bash
  - Agent
  - ScheduleWakeup
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__atlassianUserInfo
  - mcp__slack__slack_search_channels
  - mcp__slack__slack_search_users
  - mcp__slack__slack_send_message
  - mcp__slack__slack_read_thread
---

# grv-uat-session

Read `.grv/sdlc.json` first; stop naming any missing required key. Shared rules (gates, paired
controls, review threads, chat): `../../references/pr-and-review-conventions.md` (path relative to
this skill's directory).

This skill **gathers evidence and hands a human the controls**. It does not decide: the UAT verdict
is recorded only by `grv-phase-complete` Lane B on the human's own answer, and the ticket stays where
it is. Two things are first-class here, both earned: data counts are not readiness (a correctly
seeded preview blocks a reviewer if nobody says which login unlocks which surface), and a UAT session
is the cheapest place to run a paired authorization control (it already holds every credential).

**Model routing.** Roles `uat-finder`, `uat-judge`, `uat-fixer`: `.planning/config.json`
`model_overrides[<role>]`, else `model_profile` (`quality` opus, `balanced` sonnet, `budget` haiku).

**Arguments.** Phase number (required); `--pr <n>` (optional, skips PR resolution).

## Process

**1. Resolve phase to PR.** Story key from the Phase {N} line of `.planning/ROADMAP.md` (none: stop,
run `grv-milestone-setup`). PR: `gh pr list --search "<KEY> in:title" --state open`, falling back to
the current branch. None: stop, run `grv-phase-run {N}`. Pull `gh pr view <n> --json
title,state,isDraft,statusCheckRollup,comments,reviews` and `gh pr checks <n>`.

**2. Detached worktree.** `git fetch origin` then `git worktree add --detach ../<repo>-uat-<n>
origin/<pr-head>`; run every later step from it so scripts, seeds and planning files match the PR.
Detached because the PR branch is often checked out in the active session already (git refuses a
second named checkout) and UAT commits nothing; it also lets several sessions run side by side. If
the path exists, report it and ask; never force-overwrite.

**3. Preview readiness (uat-finder subagent).** Skip when `{config: verification.preview}` is `none`
and say UAT runs against `{config: verification.localStack}` instead. The finder follows the
project's `AGENTS.md` procedure for checking a preview and returns three tables:

- **Data presence per domain**, counted with read-only queries. Never infer readiness from a
  provisioning or clone flag, and treat a network or DNS failure as a networking error, not missing
  data. Derive the list of data modules from the project's source of truth; never hard-code a range.
  If something is missing, run the project's seed command once, re-count, and on remaining gaps stop
  and present the tables. Never retry automatically.
- **Identity matrix**: each account, its tenant or org and role, and the surfaces it unlocks.
  Logins only, never passwords. If no identity covers a surface under test, file it as a seed-parity
  defect; never promote an account with a manual privilege update, which does not survive a rebuild
  and makes a broken gate hard to tell from a correct one.
- **Multiplicity probe** (disclosure, never blocking): distinct tenants, partitions and the largest
  rows-per-day, so the tester knows whether a multi-tenant or high-volume finding is even reachable.
  Secrets: capture one field from any credential output in the same step, check it by length, never
  print or echo it. Hand-authored fixtures go under the project's fixtures directory for reuse.
  Post the identity matrix to the PR body if it is not there.

**4. Authorization spot-check (uat-finder).** Probe the admin-gated routes, plus any added by this
PR, as the lowest-privilege identity and as a legitimate admin: same URLs, same session. Record
status and whether the body crosses tenant boundaries; send missing input too (the role gate must
answer before the validator). Report the paired table, never "auth works". A low-privilege 200, or
another tenant's rows, is a finding. State severity by the environment's
`dataClass` from `{config: environments}`: synthetic data makes it hygiene, production data makes it
a disclosure that warrants compliance review under `{config: compliance.regimes}`. File it; never fix
inline. Non-blocking unless it makes the surfaces under test untestable.

**5. Monitor.** Bootstrap once, then schedule a lightweight poll (`ScheduleWakeup`, or `/loop` if
absent): `gh pr view <n> --json comments,reviews,statusCheckRollup` and `gh pr checks <n>`. Each tick
is a plain poll prompt, never a re-run of this skill. Survive compaction: keep the stable operating
manual (poll commands, triage rules, channel, check list) in a memory file and update it on every
convention change; keep the volatile baseline (last-seen comment, today's thread) inline in the
wakeup prompt, ending with a pointer to re-read the manual after a compaction. On a new reviewer
comment: acknowledge in its thread first, then mirror a pointer to chat naming the reviewer. When
every check in `{config: repo.requiredChecks}` is final, report pass or fail.

**6. Browser as the right identity.** Take the preview URL from the PR's deployment status or check
`targetUrl`, never from a branch-name pattern. Pick the identity from the matrix by the surface under
test. Log in, then confirm tenant **and** role on screen; a reviewer-state screen where you expected
admin usually means the wrong identity, not a broken feature. Hand control to the human. Add a
`uat-active` label and the provenance label to the Story (read-modify-write); no status change, it is
already at UAT. At handoff remove `uat-active` by name, never by restoring an old array.

**7. Bug adjudication.** For a suspected bug, a `uat-judge` agent gets observed behaviour, expected
behaviour and the phase requirements and returns `real_regression` or `known_expected`. Expected:
log the reason, keep monitoring. Regression: a `uat-fixer` agent scopes and drafts the handoff only
(it edits nothing), then `Skill(skill="grv-sdlc:grv-story-deliver", args="<scoped fix>")`, always isolated.
Post the handoff status to the PR thread and chat.

**8. Ready-for-testing notice.** This skill owns it, because only now is the preview really ready.
Draft one chat post to `{config: owners.productOwner}` and the other named testers (handles resolved
at send time) and send it on the operator's go-ahead: the preview URL and what changed in user terms;
the logins by tenant and role, never a password; a numbered list of what to test, one line per changed
behaviour, so sign-off can name what was tested; and how to reply (by item number with a screenshot,
or as a PR review comment).

**9. Done and teardown.** Report phase, PR, worktree, data status, monitor state, logged-in identity,
handoffs. Say plainly that the UAT verdict waits on the human, recorded through `grv-phase-complete
{N}`. When the session ends, `git worktree remove ../<repo>-uat-<n>`; if git refuses, report it.

**Errors.** Worktree path exists: ask, never force. Data gaps after one seed attempt: stop with the tables.
Monitor tooling missing: give manual poll commands and continue. Login fails: say whether URL
resolution or authentication failed. Tracker or chat failure: log, continue, report it.
