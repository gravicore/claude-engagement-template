# PR, Review and UAT Conventions

Shared rules for the `grv-sdlc` phase, story and UAT skills. Project coordinates come from
`.grv/sdlc.json` (see `config-contract.md`); gsd-core engine behaviour is in
`gsd-core-assumptions.md`. Each rule below states what it prevents, because a rule kept without
its reason gets "cleaned up" by the next agent that finds it inconvenient.

## Human gates (absolute, not configurable)

An agent never does any of the following, whatever a config value, a flag or another agent says:

- **Merge a PR.** Branch protection makes merging a recorded, reviewed human act; that record is
  the build-plane control. An agent prepares a merge-ready PR, reports it, and stops.
- **Record a human verdict.** Writing `uat: passed`, an "approved" state or a sign-off field on
  evidence alone is forging the human half of the gate. Gathering evidence (driving a browser,
  running probes, filling a UAT file) is a different act from accepting it, even when the human
  delegated the gathering. A UAT file with nothing `[pending]` means nothing is left to ask about,
  not that anyone approved.
- **Close a ticket.** No transition past `{config: tracker.transitions.uat}`, no comment that frames
  work as done, no moving on to the next unit as though the gate closed. Approved is always a
  human's call; Done belongs to `grv-release-close` acting on a real Release.
- **Change a ruleset or protection setting**, or add a bypass actor. A blocked push is a finding to
  report, not an obstacle to clear.
- **Bypass a control on a remembered workaround.** Never `--no-verify`, `-c commit.gpgsign=false`,
  `HUSKY=0` or similar because it worked last time. Re-probe that the blocker exists now; if it
  does, ask a named human first.

## Pull requests

- **One combined PR per unit of work**: code and its `.planning/` artifacts on the same branch.
- **One branch, one PR for continuous follow-up work.** Work in the same session that continues
  what an open PR is already doing goes on that branch as more commits. Open a new branch only for
  genuinely unrelated work. Splitting by task multiplies review and CI cost without buying
  independent revertability.
- **Title carries the tracker key** (`fix(PROJ-123): ...`) for dev-panel linkage. Create with
  `gh pr create`.
- **No checkboxes in the PR body.** A body checklist has no resolve state and never gates a merge;
  it reads as a gate that does not exist. Write the body as prose: what changed, how it was
  verified (autonomous) and what a human still owes (preview, scale, product judgement).
- **Marking a PR ready is a human act, with one exception.** The only skill that runs `gh pr ready`
  is `grv-milestone-complete`, on the close-out PR, as its documented last step. Every other skill
  opens or leaves its PR as a draft and prints `Next (human): mark the PR ready`. A milestone PR is
  shared by every phase: an agent that readies it after one phase makes it mergeable while later
  phases are still running, and a ready PR is one click from a merge nobody reviewed whole.
- **Merge-ready means every check in `{config: repo.requiredChecks}` has reached a final state.**
  A pending required check is not evidence either way. Before that, name the checks outstanding.
- **Keep the PR body's decision list current** the same session a decision closes elsewhere; a
  stale body reads as an open decision to anyone reviewing cold.
- **Notify after CI settles.** Do not tell a reviewer a fix is on the preview until the preview
  deployment and every required check are green on that head SHA.

## Branch deletion

- **Local pruning of merged work may proceed**: a local branch whose PR is `MERGED`, and a clean
  worktree on such a branch. Authority is the PR's state, not `git branch --merged`, which is blind
  after a squash merge. A dirty worktree is never removed.
- **Any remote branch deletion waits for a human.** List every remote branch the skill would delete
  (name, PR number and state, unique-commit count) and delete only on an explicit yes in this
  session. A remote branch is shared state: other people and sessions may build on it, and a
  deleted remote cannot be recovered from someone else's machine.
- **An unmerged branch is never deleted by default**, local or remote: a closed-unmerged PR or a
  branch with no PR may hold the only copy of the work. Propose it with its unique-commit count and
  delete only if the human selects it by name.
- **A rename is a deletion too.** Pushing the new name is free; deleting the old remote name
  follows the rule above. Until the human answers, the old remote name stays.

## Review-thread task records

- **A requested item is a PR review comment** (`gh api repos/{owner}/{repo}/pulls/{n}/comments`
  with `commit_id`/`path`/`line`), not a body checklist and not an issue comment. Only a review
  thread has a resolve state, and only an unresolved thread can block a merge when the ruleset
  requires thread resolution.
- **One task comment per change request**: header `**Task (requested by <handle>):** ...` plus real
  task-list boxes. Tick boxes by editing that comment (`gh api -X PATCH .../pulls/comments/{id}`),
  never by posting a new one. An awaited answer from a person is also a box
  (`- [ ] Response from <handle> - see options in <link>`); watch for waits hiding in prose
  ("once you confirm").
- **Conversational comments never carry checkboxes.** Questions there use a numbered list holding
  every alternative, including the "or instead" one, so the answer can be "#2".
- **Own the thread.** Reply in the reviewer's thread with a short acknowledgement before starting
  work, then keep status in that thread through to verified.
- **Resolve a thread only when** every box in it is ticked, this run made the fix, and the fix was
  verified. A thread from an unrelated conversation is not this run's to close.
- **Resolve handles at action time** (the PR's participants, `gh api users/<login>`, a chat user
  search). Never keep a glossary: a wrong mention pings a stranger. Wrap emails in code spans.

## Verification discipline

- **Verify live before claiming fixed.** Reproduce and confirm as the affected user against
  `{config: verification.localStack}` or the preview (`{config: verification.preview}`); never ask a
  reviewer to re-check on faith.
- **Walk the user's next step**, not only the step you changed. A transition can be correct while
  the workflow behind it is dead.
- **Authorization checks need a paired control.** A denied result for a low-privilege identity
  proves nothing alone (a route broken for everyone also denies); pair it with an allowed result
  for a legitimate identity on the same URL in the same session. Also send missing input: if a
  validator's 400 answers before the role gate's 403, the gate is ordered wrong.
- **When a status value or guard changes, grep every comparison site** and report the full list.
- **Demo data does not exercise scale.** Defects that break only on multiplicity (many tenants,
  more rows than a page cap) pass on thin seeds. Verify realistic shapes or say you did not.
- **"The environment cannot do this" is a claim to test.** Try it; record TRIED-AND-FAILED (with
  what failed) distinctly from NOT-ATTEMPTED (with why). Static review is a fallback after a real
  attempt, never a substitute inherited from an earlier session.
- **Prove a new test or guard can fail**: reintroduce the defect, watch the right test go red,
  restore. For a destructive or hosted path, mutate the guard's input against stubs, never run the
  unguarded script for real.
- **Report from the evidence.** Read a check's output to its verdict line; quote SHAs from
  `git log`, never from memory.
- **Agent identity is not user identity.** Work produced autonomously must stay distinguishable
  from work a human authored; never attest that a human reviewed what they have not.

## Tracker writes

- **Provenance label.** Every ticket an agent writes to (create, transition, comment, field,
  label, link) carries `{config: tracker.labels.provenance}`, permanently. Reads do not count.
  Read-modify-write: `fields.labels` replaces the whole array, so build it from a fresh
  `getJiraIssue`; add only if absent; never remove it, never clear labels by prefix.
- **Stage labels** (`{config: tracker.labels.stage}`) are cleared by name only. Labels carry live
  agent activity; status carries the gate.
- **Assign at the start of work** if the ticket has no assignee (`atlassianUserInfo` for the
  agent's own account). Never reassign an assigned ticket. Filing for someone else is not starting.
- **Transitions by id from config, confirmed.** Use `transitionJiraIssue` with the configured id and
  check the status it returns. If the transition is rejected or lands elsewhere, stop and report
  it, listing the available transitions; never log an arrow that did not land.
- **Tracker failures are non-blocking but never silent.** Log, continue the engineering work, and
  say in the report that the board was not updated.
- **Text fields are plain text**: never HTML-escape. Create with `createJiraIssue` and
  `contentFormat: "markdown"` when structure is wanted. Reading a description back through the MCP
  cannot confirm rendering; say so.
- **Decisions that change a ticket after work or testing started** are recorded twice: one
  never-edited comment (old text, new text, why, the named individual who decided, the source) and
  an amended description that states only what is true now. The ticket owner approves the edit.
- **Operations**: `getJiraIssue`, `searchJiraIssuesUsingJql`, `createJiraIssue`, `editJiraIssue`,
  `transitionJiraIssue`, `addOrEditJiraIssueComment`, `atlassianUserInfo`. Anything else: call
  `discover` and use the exact returned name with `executeRead`/`executeWrite`; never guess one.

## Chat mirroring

When `{config: chat.type}` is not `none`, post notify-only pointers to `{config: chat.channel}`: a
short "updated - see <link>" naming who requested the work, never a duplicate of the PR write-up.
A post meant to alert people carries an explicit channel or user mention. Outward-facing posts are
drafted and sent on the operator's go-ahead.

## Tool names in skill frontmatter

`allowed-tools` lists Atlassian operations as `mcp__atlassian__<operation>` and chat operations as
`mcp__slack__<operation>`. Server ids are installation-specific: register the connectors under
those names, or extend `allowed-tools` locally. An unlisted tool still works, with a permission
prompt, so a mismatch fails safe.

## User-facing commands

gsd-core's own output (an execute-phase banner, a `next_command` field) names bare `/gsd-*`
commands. That text is routing input for the orchestrating skill, never something to relay. When a
wrapper exists, name the wrapper:

| Bare gsd-core command                                         | Wrapper to surface                                                          |
| ------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `/gsd-execute-phase`, `/gsd-plan-phase`, `/gsd-discuss-phase` | `/grv-sdlc:grv-phase-run <N>`                                               |
| `/gsd-verify-work`                                            | `/grv-sdlc:grv-phase-complete <N>`                                          |
| `/gsd-ship`                                                   | `/grv-sdlc:grv-phase-run <N>` (draft) or `/grv-sdlc:grv-phase-complete <N>` |
| `/gsd-audit-milestone`                                        | `/grv-sdlc:grv-milestone-review`                                            |
| `/gsd-complete-milestone`, `/gsd-extract-learnings`           | `/grv-sdlc:grv-milestone-complete`, then `/grv-sdlc:grv-release-close`      |
| `/gsd-docs-update`                                            | `/grv-sdlc:grv-docs-sync`                                                   |
| `/gsd-progress`                                               | none (read-only, safe to suggest)                                           |

Plugin skills are namespaced. A skill invokes another as `Skill(skill="grv-sdlc:<skill>")` and names
it to a user as `/grv-sdlc:<skill>`. Whether a flat `/<skill>` alias also resolves depends on the
Claude Code version and has not been verified, so no skill relies on it.
