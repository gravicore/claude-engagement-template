---
name: grv-phase-review-fix
description: >
  Post-ready review-fix loop for a phase PR: collect AI review findings, human reviewer threads and
  open UAT items, then fix, re-verify and re-review until clean (max 3 iterations), resolving only
  the review threads this loop verifiably closed. Hands back a merge-ready PR; never merges.
  Triggers on: "review fix", "fix review comments", "address review", "grv-phase-review-fix".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Read
  - Edit
  - Bash
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__addOrEditJiraIssueComment
  - mcp__atlassian__discover
---

# grv-phase-review-fix

Runs after a human has marked the phase PR ready (`grv-phase-complete` closed Lane A). It never
changes the PR's draft or ready state itself. Read `.grv/sdlc.json` first; stop naming any missing
required key. Shared rules, including review-thread records and thread ownership:
`../../references/pr-and-review-conventions.md` (path relative to this skill's directory). gsd-core
behaviour and the `gsd_run` shim: `../../references/gsd-core-assumptions.md`.

## Arguments

- Phase number (required).

## Process

**1. Resolve the Story** from the Phase {N} line in `.planning/ROADMAP.md`; none: stop.

**2. Mark and transition.** Add the provenance label if absent (read-modify-write); this loop's
other writes are a transition and comments, which leave no durable mark on their own. Transition to
`{config: tracker.transitions.uat}` unless already there; confirm the returned status, and if it
did not land, warn naming the available transitions. Tracker failures do not stop the loop.

**3. Collect findings** into one fix list:

- **AI review:** read the phase's `REVIEWS.md` if present; otherwise offer
  `Skill(skill="gsd:review", args="--phase {N}")`.
- **Human reviewers:** read the PR's unresolved review threads and conversation
  (`gh pr view <n> --json reviews,comments` and the review-threads GraphQL query), then ask the
  operator for anything said elsewhere. For each new reviewer item, post a short acknowledgement in
  its thread before acting, and record it as a review-thread task if it is not one already.
- **UAT:** `gsd_run verification status "$PHASE_DIR" --pick status`. `missing` or `stale` is itself
  an outstanding item: route it through the unfiltered repair in 4c before anything else. For
  `human_needed`, list the open items and ask whether each is signed off; record any sign-off
  through `grv-phase-complete`'s Lane B, never by writing the verdict here.

No outstanding items: go to 4e. A zero-finding review file does not mean the PR's threads are resolved.

**4. Fix loop, max 3 iterations.**

- 4a `Skill(skill="gsd:plan-phase", args="{N} --gaps --reviews")`.
- 4b `Skill(skill="gsd:execute-phase", args="{N} --gaps-only")`.
- 4c Re-verify with `verification status`. `passed`: 4d. `gaps_found`: next iteration.
  `human_needed`: present the items and wait for the human. `missing`/`stale`: never
  `gsd:verify-work` (no create path, a silent no-op); run `gsd:execute-phase {N}` unfiltered, which
  self-heals to the verification gates, then re-read.
- 4d `Skill(skill="gsd:review", args="--phase {N}")`. All resolved: 4e. New findings: next iteration.
- Past 3 iterations: step 5.
- Verify each fix live as the affected user (`{config: verification.localStack}` or the preview)
  before reporting it fixed in its thread, and only after the required checks settle on the new head.

**4e. Resolve completed threads.** Unresolved threads block the merge when the ruleset requires
thread resolution, whatever the review files say. List unresolved threads:

```bash
gh api graphql -f query='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){reviewThreads(first:100){nodes{id isResolved comments(first:50){nodes{body}}}}}}}' \
  -f o="<repo.owner>" -f r="<repo.name>" -F n=<PR> \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved==false)'
```

Resolve a thread (`resolveReviewThread` mutation) only when it has zero unchecked `- [ ]` boxes,
this loop made its fix, and you verified that fix. A thread whose box awaits a person's answer stays
open. Never resolve a thread from an unrelated conversation. Update the PR body's decision list if
a decision closed this run.

**5. Max iterations.** List the unresolved items from the review file, the report and open threads.
Say: resolve manually, then re-run `grv-phase-review-fix {N}`. Stop.

**6. Done.** Report the Story key, the PR, threads resolved and still open, and the state of every
check in `{config: repo.requiredChecks}`. Call it merge-ready only when every required check is
final and green and no blocking thread is open; otherwise name what is outstanding. Merging is the
human's call. After the merge: `grv-milestone-review` on the release PR when the milestone's phases
are done, then `grv-milestone-complete` and `grv-release-close`.

## Error handling

- Tracker failure: log, continue, name it in the report.
- `plan --gaps --reviews` writes no plans: stop; the remaining findings need a human.
- Execute fails: stop the loop, show the output.
- No review file and the operator declines `gsd:review`: proceed with human and UAT inputs only.
