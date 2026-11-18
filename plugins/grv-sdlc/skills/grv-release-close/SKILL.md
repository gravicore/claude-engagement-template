---
name: grv-release-close
description: >
  Everything after a release's last merge, for a milestone or a patch. Composes release notes from
  the merge, publishes the GitHub Release (human-gated), posts the chat pointer, closes the Jira
  tickets the release actually shipped on explicit per-ticket human selection, reconciles the
  Open at Release list, prunes local branches and worktrees, and for a milestone closes the Epic as
  the terminal write. Changes no repo file. Reads the merged commits and the code on the default
  branch, never SHAs quoted in ticket comments. Triggers on: "release close", "close the release",
  "publish the release", "release notes", "ship the release", "close out the UAT tickets",
  "post-release cleanup", "prune merged branches", "grv-release-close".
allowed-tools:
  - AskUserQuestion
  - Read
  - Write
  - Bash
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__searchJiraIssuesUsingJql
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__addOrEditJiraIssueComment
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__atlassianUserInfo
  - mcp__slack__slack_search_channels
  - mcp__slack__slack_send_message
---

# grv-release-close

`/grv-sdlc:grv-release-close <tag>` after the last merge (`grv-milestone-complete`'s close-out PR, or a patch
PR on its own). **It changes no repo file**: a file change here needs a new PR and restarts the
close-out. It writes only to GitHub Releases, chat, Jira, a PR body and the local workspace; scratch
files live in the scratchpad. A finding that needs a file change becomes a new change request.

Arguments: `<tag>`; `--pr <n>` (the last merged PR); `--dry-run` (reads, notes draft, verdict table,
proposed PR-body diff; no writes); `--hygiene-only`; `--no-hygiene`.

Read `.grv/sdlc.json`: `repo.*`, `tracker.cloudId`, `tracker.transitions.done` / `.inProgress`,
`tracker.labels.provenance`, `tracker.releaseGateEpic`, `chat.*`, `environments[]`, and the optional
`{config: release.targetEnvironment}`. `ENVIRONMENT` is that named `environments[]` entry when the key
is present (stop if it names no entry); when absent, the entry the merge deploys to (`promotion:
auto`), asking if that is ambiguous. Order: release before any Done (Done points at it), local
hygiene before the human gate, remote deletions and PR-body correction before Jira, ticket Dones
before the Epic's. **The last Done is the last write; no
step is ever added after it.**

## Process

0. **Gate.** `gh pr view <n>`: not `MERGED` -> stop (for a milestone, `grv-milestone-complete` still owns
   the open close-out PR). Record the full 40-character `MERGE_SHA`, `PREV` (previous Release tag) and
   mode: `milestone` if `.planning/milestones/<tag>-ROADMAP.md` exists at `MERGE_SHA` (read the epic key
   from it), else `patch`. An existing Release for `<tag>`: reuse it and skip 1-3; one targeting anything
   but `MERGE_SHA` is a finding - report and stop. `PR_NUMBERS` is **every PR merged since `PREV`**
   (from `(#<n>)` in first-parent subjects of `PREV..MERGE_SHA`), because the release PR merged before
   the close-out PR. A commit in range with no PR is a finding.
1. **Compose notes from the merge** (scratchpad file). They record what shipped, as of now: no open
   items, follow-ups or future intent. Title Case headings; Jira keys wherever they exist. Sections:
   **title line** (`<version> - <Name> (<EPIC>)`, environment, release PR and its merge SHA, close-out
   PR); **What Shipped** (one user-facing line per requirement or ticket); **Delivery Improvements**
   derived from `git diff PREV..MERGE_SHA` on AGENTS.md / CLAUDE.md (rules added or changed, stated as
   the rule) and the skills tree (one clause per skill, one line for a sweeping change); omitted for a
   patch with none; **Risk Accepted** (UAT waivers with reason, date and who;
   accepted SECURITY.md risks; design-gate override files, counted, zero included). There is no
   verification override to list: a phase without a `passed` report never reaches a release. Show the draft.
2. **Publish - human-gated.** gsd-core tagging is off by design: a release marker is a change-management
   record, as deliberate as the merge, and a Release carries notes a bare tag cannot. Milestone mode:
   first confirm only the close-out PR landed between the two merges; if another PR did, name it in What
   Shipped. On an explicit yes in this session: `gh release create <tag> --notes-file <f> --target
<MERGE_SHA>` (full SHA; never `--target <branch>`, or the tag moves). Declined: stop; nothing closes
   against a Release that does not exist.
3. **Chat pointer** (if `chat.type` is not `none`): resolve `{config: chat.channel}` by search at action
   time; post `<version> shipped to <ENVIRONMENT> - <release link>`, a pointer, never a copy of the notes.
   Confirm first.
4. **Shipped ticket set.** From each PR's title, commit headlines and delivered-work headings: keys used
   as a conventional-commit scope or PR title key. A key mentioned as context is not delivery; read the
   sentence.
5. **Classify** with one JQL `key in (...)`: Done -> listed, untouched; UAT -> candidate; Approved ->
   candidate, flagged (a human's pre-release clearance, never folded in silently); earlier statuses ->
   mismatch, not a Done candidate; Epics -> excluded (milestone Epic handled in 11).
6. **Evidence per candidate - read the code, not the comments.** Each acceptance criterion is shipped /
   not shipped / not checkable, judged only from the merged commit headlines, the code at `MERGE_SHA`
   and artifacts on disk. Never trust a SHA quoted in a ticket comment: squash-merge makes every one
   fail an ancestry check even when the change is fully merged. Ticket verdict: fully shipped, partial
   (never a Done candidate; proposed corrective comment and a move back to In Progress), or unclear
   (criterion quoted, human decides).
7. **Workspace hygiene (local only)**, per `../../references/pr-and-review-conventions.md`, "Branch
   deletion" (path relative to this skill's directory). Authority is PR state, not `git branch
--merged` (useless after squash). Per local branch: MERGED -> delete locally; CLOSED unmerged, or
   no PR -> keep, listed with its unique-commit count as a deletion candidate for step 8; OPEN ->
   keep. Remove clean worktrees on a deleted branch; never a dirty one. **No remote branch is deleted
   here.** Run each destructive command alone; if one is refused, report the exact command.
8. **Human gate - per-ticket verdicts.** One table: key, status, evidence, proposed action. Milestone
   mode adds the Epic's children step 4 missed; a tracker-style child with an unanswered item is not a
   Done candidate (re-file it or leave it open; ask), and the Epic is the last row, proposed only when
   every child is Done or selected. A second table lists branch deletions: each remote branch of a
   MERGED PR still present, and each unmerged candidate from step 7 (local or remote, with its
   unique-commit count). Then AskUserQuestion, multi-select, **no default**: an unselected ticket is
   not written and an unselected branch is not deleted. Delete only the selected branches, before
   step 9. Non-interactive session: stop here and report both tables. There is no `--yes`; recording a
   human's acceptance, closing a ticket and deleting shared or unmerged work are never done on a
   human's behalf.
9. **Reconcile the open-items record.** Diff the close-out PR's `Open at Release` list against the
   verdicts; show the corrected body; apply with `gh pr edit` only on a yes. A correction to an older
   Release's notes appends a dated `## Corrections` line rather than rewriting what people read.
10. **Jira, one ticket at a time** (parallel external writes get refused). Per selected ticket:
    provenance label (read-modify-write); a markdown comment naming ENVIRONMENT (and, if
    `tracker.releaseGateEpic` is set, that live production is gated by it), the Release URL, PR and
    `MERGE_SHA`, what shipped, and **who accepted, in session, on what date**; then transition by id
    `{config: tracker.transitions.done}` (or `.inProgress` for a partial) and confirm the returned
    status. A failed write stops the sequence; report what landed and the unsent comments.
11. **Milestone mode only - the Epic, terminal write.** Selected children not yet closed, then the Epic,
    each with the environment comment and provenance label. Never move an Approved child without
    confirmation. Nothing writes after this.
12. **Report** (read-only): Release URL, environment, SHA, PRs, chat post; each ticket's old -> new status
    or why it stayed; notes corrections; workspace removed and kept; Epic status or, in patch mode, each
    parent Epic's remaining non-Done children (never transition an Epic outside milestone mode); any
    refused command, verbatim.

Never merge; never set Approved; every Release, chat post, release edit and transition is confirmed in
the current session, and approval in one run never carries to the next.
