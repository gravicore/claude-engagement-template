---
name: grv-story-update
description: >
  Enrich one tracker Story with post-planning or post-commit detail: story points, original
  estimate, components, and a structured description that links the planning artifacts. Phase mode
  reads PLAN/CONTEXT/SPEC; quick mode reads the branch diff and PR. Previews every change and
  applies only on confirmation; never changes status, summary, parent, assignee or sprint.
  Triggers on: "update story", "enrich jira", "sync plan to jira", "update story points",
  "post-plan sync", "push plan to jira", "grv-story-update".
allowed-tools:
  - AskUserQuestion
  - Read
  - Edit
  - Bash
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__searchJiraIssuesUsingJql
  - mcp__atlassian__createJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__discover
  - mcp__atlassian__executeRead
---

# grv-story-update

Idempotent; safe to re-run after any planning pass. Read `.grv/sdlc.json` first; stop naming any
missing required key. Tracker write rules: `../../references/pr-and-review-conventions.md` (path
relative to this skill's directory).

**Field ids are per site.** Story points and track are custom fields whose ids differ between
Jira sites: `{config: tracker.fields.storyPoints}` and `{config: tracker.fields.track}` (both
optional). Absent: resolve with `discover` (field metadata for `{config: tracker.projectKey}`) and
show what you resolved in the preview; never write a guessed `customfield_*` id. Components map the
diff's paths through the path-prefix keys (ending `/`) of `{config: tracker.componentMap}`
(optional); with no map, leave components unset and never invent a name.

## Arguments

- `PROJ-123`: explicit Story key.
- `--phase N`: phase mode; key from the Phase N line of `.planning/ROADMAP.md`.
- None: detect from the branch. `gsd/p/{N}/...` is phase mode; `gsd/q/...` or anything else is
  quick mode with the branch name as slug.
- `--autonomous`: compute and print the preview table, write nothing.

## 1. Gather context

**Phase mode.** Read, skipping any that is absent: the phase `*PLAN.md`, `*-CONTEXT.md`,
`*-SPEC.md`, `*-UI-SPEC.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`. Extract
`task_count` (task checklist lines in PLAN.md), the goal, any explicit estimate. Stage is
`pre-discuss` (no CONTEXT, no PLAN), `post-discuss` (CONTEXT only) or `post-plan`.

**Quick mode.** `git log <default>...HEAD --oneline`, `git diff <default>...HEAD --stat`,
`gh pr view --json title,body,url,headRefName`. `total_lines` = insertions + deletions.

## 2. Compute estimates

Story points and original estimate are computed independently, by the tables and boosters in
`../../references/estimation.md` (phase mode: task count, or the sweep probe's site count when
larger; quick mode: changed lines, or an explicit estimate in the PR body). Round estimates only,
capped at `5d`. If neither a task count nor a site count exists, say so in Technical Notes.

## 3. Build the description

Link artifacts by path; never reprint requirement text or task lists. Phase mode, in markdown:
`### Context` (one plain sentence: problem and user impact, plus the path to the full context),
`### Requirements` (ids and path), `### Acceptance Criteria` (3-5 binary, present-tense,
independently testable bullets rewritten from the ROADMAP success criteria, including a zero or
error state; no "should"), `### Technical Notes` (post-plan only, 2-3 lines of non-obvious decisions
or risks; omit if nothing is non-obvious), `### Tasks` (path and count), `### Definition of Done`
(tests passing, PR reviewed and merged by a human, verified on the preview, plus migration applied
when the plan touches one), `### PR` when one exists, and a footer
`GSD phase {N} | Milestone {v} | SP {sp} | Est {est} | Stage {stage}`.

Quick mode: `**Summary:**` (1-3 sentences from commits and PR title), `**Changes:**` (top 10 files
from the diff stat), `**PR:**`, footer `GSD quick: {slug} | SP {sp}`.

## 4. Resolve or create the Story (quick mode only)

Search `project = <key> AND labels = "gsd-quick-{slug}"`. Found: use it. Not found: ask "Create
Story / Skip, I will link it / Enter existing key". Create with `createJiraIssue`, issue type Story,
`contentFormat: "markdown"`, a 3-5 word ASCII title stating the outcome (no skill or file names),
labels: provenance, `gsd-quick`, `gsd-quick-{slug}`.

## 5. Preview and confirm

Before touching the tracker, show Story key and current summary, mode, and a table of Story Points,
Original Estimate, Fix Version (phase mode: the milestone from REQUIREMENTS.md; quick: only if the PR
names one), Components, Description (updated or unchanged), PR link, and any field id resolved in
the preamble. Ask: Apply all / Apply all except description / Abort. Points and estimates are
advisory inputs to planning, which is why the human sees them before they land.

## 6. Apply

`editJiraIssue` with the confirmed fields; description with `contentFormat: "markdown"`. Add the
provenance label in the same write (read-modify-write; it needs no confirmation, it is provenance,
not enrichment). A `fixVersions`, `components` or `timetracking` error: warn, retry without that
field, continue. If every field fails, print the computed values as a table for manual entry.

## 7. Write back (phase mode, PLAN.md exists)

In the ROADMAP Phase Details block replace `**Plans**: TBD` with
`**Plans**: PLAN.md | SP: {sp} | Est: {est}`, then commit
`docs: update phase {N} estimate ({KEY} - {sp} SP)`.

## 8. Report

Story key, SP, estimate, fields updated, warnings.

## Constraints

Never change summary, status, parent, assignee or sprint; never transition. Those belong to the
team and to the delivery skills.
