---
name: milestone-sync
description: >
  Sync a gsd-core milestone to Jira: validate the Epic, create or update one Story per phase (goal,
  requirements, estimate, acceptance), link Stories to the Epic and to each other in a Blocks
  chain, move new Stories from Backlog to Selected, and write the Jira keys back into ROADMAP.md.
  Idempotent. Triggers on: "sync milestone to Jira", "sync phases to Jira", "create Stories",
  "push phases to Jira", "create Jira Stories from roadmap", "milestone sync", "milestone-sync".
allowed-tools:
  - AskUserQuestion
  - Read
  - Edit
  - Bash
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__searchJiraIssuesUsingJql
  - mcp__atlassian__createJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__discover
  - mcp__atlassian__executeRead
  - mcp__atlassian__executeWrite
  - mcp__atlassian__atlassianUserInfo
---

# milestone-sync

One Story per roadmap phase under the milestone's Epic. Re-running updates, never duplicates. Called
by `milestone-setup` step 3; also standalone for phases added later.

## Arguments

- `--phase N` / `--phases N-M` limit the sync (default: phases with no key yet). `--force` update
  phases that already have keys.

## Config

Read `.sdlc/config.json`. Required: `tracker.cloudId`, `tracker.projectKey`, `tracker.labels.provenance`,
`tracker.transitions.selected`. Optional, each skipped when absent and never guessed:
`{config: tracker.fields.storyPoints}`, `{config: tracker.fields.track}`,
`{config: tracker.componentMap}`, `{config: tracker.linkTypes.blocks}`, `{config: tracker.siteUrl}`.

## Estimates

- Story points and original estimate: the "Before planning" rules in
  `../../references/estimation.md` (path relative to this skill's directory), computed
  independently. Points are set only if `{config: tracker.fields.storyPoints}` is present.
- Components: map each requirement-id prefix through the keys of `{config: tracker.componentMap}`
  that end in `-` (no code exists yet, so path keys do not apply). An unmapped prefix gets no
  component and a one-line warning; never invent a component name. If `components` errors, retry
  without it.

## Process

1. **Read artifacts.** From `.planning/ROADMAP.md`: every phase line (number, title, any embedded key)
   and its `### Phase N:` block (Goal, Requirements, Success Criteria, Depends on, UI hint,
   Constraint). From `.planning/REQUIREMENTS.md`: `jira_epic` frontmatter and full requirement text.
   Constraint resolves from a `**Target environment:**` line, else the phase's own Constraint, else
   none (omit the section; never an empty placeholder).
2. **Validate and classify.** `getJiraIssue` the epic; not found or not an Epic: stop. Per phase: key
   in ROADMAP and no `--force` -> SKIP; key and `--force` -> UPDATE; no key -> JQL
   `project = <projectKey> AND labels = "gsd-phase-<N>" AND parent = <epic>`; found -> UPDATE, else CREATE.
3. **Preview** the operation table (phase, action, summary, counts) and confirm: proceed / skip some /
   abort. Nothing touches Jira before this.
4. **Execute in phase order.**
   - CREATE: `createJiraIssue`, type Story, parent the epic, summary `Phase <N>: <title>` copied
     verbatim (never HTML-escaped), `contentFormat: "markdown"`, labels
     `[<provenance>, "gsd-phase-<N>"]` plus `ux` for a UI phase, estimate and configured fields.
     Description: `### Intent` (goal), `### Requirements` (`- **ID:** text`), `### Acceptance Criteria`
     (one bullet per criterion), optional `### Constraint`, footer `GSD phase: <N> | Milestone: <v>`.
     No fix version: the Epic is the milestone boundary.
   - UPDATE: `editJiraIssue` description and labels only, never summary, status or parent (the team
     may have changed them). Labels are read-modify-write from the fetched issue: existing list plus
     `gsd-phase-<N>`, `ux` if applicable, and the provenance label if absent. Rebuilding the list from
     the CREATE template deletes labels the team added by hand.
   - A failure on one phase is logged and the rest continue.
5. **Blocks chain.** For each `Depends on: Phase M`, Story M blocks Story N, using the link type
   `{config: tracker.linkTypes.blocks}`. Absent: read the site's link types and use the one named
   exactly `Blocks`; none: skip the chain and say so. Use the issue-link operation (`discover` its
   exact name, run via `executeWrite`; never guess). Read one link back to confirm the direction (the
   blocker's outward description reads "blocks"). Unknown key: warn and skip. Duplicate link errors
   are non-fatal.
6. **Selected.** For each created/updated Story whose status is the initial backlog status (status
   category `new`), transition by id `{config: tracker.transitions.selected}` and read the returned
   status to confirm it. Any other status: leave it. Failures are non-fatal.
7. **Write back.** Insert the key as a backtick token after the bold phase title on its ROADMAP line
   (leave existing keys alone) and add or update a `Jira` column in the Progress table. Commit
   `docs: annotate ROADMAP.md with Jira story keys (<keys>)`. If the write-back fails, print the
   mapping as a table.
8. **Summary.** Per phase: key, result, and a browse link built from `{config: tracker.siteUrl}`
   (omitted when absent). The Blocks chain line only when a link was created.
   Unmapped-component warnings. Failures with their errors.

## Constraints

- Never modify the Epic (that is `epic-writer`), never set assignee, sprint, priority or due date.
- The only transition is Backlog to Selected, by id. Never delete or close Stories.
- Do not set a legacy Epic Link field; `parent` populates it.
