---
name: grv-milestone-init
description: >
  Turn a Jira Epic into a gsd-core milestone roadmap: the interactive requirements-and-roadmap
  intake that writes .planning/ROADMAP.md and REQUIREMENTS.md with the epic key embedded where
  every downstream skill expects it, then ships the intake as a PR. A thin wrapper over gsd-core's
  new-milestone so the operator never types a raw gsd command. Interactive on purpose:
  requirements are PO intent and are never derived unattended. Triggers on: "init milestone",
  "new milestone for", "start a milestone from the epic", "grv-milestone-init".
allowed-tools:
  - AskUserQuestion
  - Skill
  - Read
  - Edit
  - Bash
  - mcp__atlassian__getJiraIssue
---

# grv-milestone-init

`/grv-sdlc:grv-milestone-init PROJ-123` - the step between `grv-epic-writer` and
`grv-milestone-setup` / `grv-epic-run`. It exists so every step of the lifecycle is reachable through a `grv-*` skill.

**No `--autonomous` mode, by design.** gsd-core's intake is a set of question loops, and it should
be: an agent deriving requirements from an IDD Epic alone is the guessing the epic-writer exists to
prevent. Run it with the lead engineer (`{config: owners.leadEngineer}`) present.

## Arguments

- `<EPIC-KEY>` (required). Everything else passes through to `gsd:new-milestone` unchanged.

## Process

0. **Config.** Read `.grv/sdlc.json`; require `tracker.cloudId`, `tracker.projectKey`,
   `repo.defaultBranch`. Stop and name any missing key.
1. **Read the Epic.** `getJiraIssue`; it must be an Epic and not Done. Print its Intent, User Value,
   Success Criteria and Out of Scope first: the intake answers come from them, and putting them on
   screen is what stops the roadmap drifting from the Epic. Never edit the Epic here.
2. **Guard the tree.** Refuse on `{config: repo.defaultBranch}` (branch protection rejects the commits
   gsd-core makes). Refuse if `.planning/ROADMAP.md` already holds an unarchived in-progress
   milestone: finish or archive it first (`grv-milestone-complete`). Flat planning holds one live
   milestone.
3. **Run the intake.** `Skill(skill="gsd:new-milestone", args="<passthrough>")`. Answer nothing on the
   user's behalf.
4. **Embed the epic key where branch derivation reads it.** Confirm, and Edit if missing, that
   ROADMAP.md has a `**Jira epic:** <KEY>` line and that the milestone heading and its top-of-file
   bullet read `v{N} <KEY> <Name>`. gsd-core derives the branch slug from that heading text and has
   no resolver for custom template tokens (see `../../references/gsd-core-assumptions.md` item 7;
   path relative to this skill's directory), so the key must live in the heading itself. Doing it here means the very first branch anyone cuts
   already agrees with gsd-core's slug.
5. **Ship the intake as a PR.** `Skill(skill="gsd:ship")`, title
   `chore(<KEY>): milestone v{N} intake - <Name>`, then `gh pr ready --undo <n>`: it stays draft
   until a human readies it (`../../references/pr-and-review-conventions.md`, "Marking a PR ready"). `grv-epic-run` reads ROADMAP.md and REQUIREMENTS.md
   from the remote default branch, so intake output sitting only on this branch is invisible to it.
   **Merging this PR is a human act and a hard prerequisite for `grv-epic-run`**; report it as a
   blocker for that path, not optional cleanup. Interactive `grv-milestone-setup` does not wait for
   it: it runs next in this tree, on this branch, and its setup PR carries the intake with it.
6. **Report.**

```text
Milestone v{N} <KEY> <Name> - <P> phases, <R> requirements.
Intake PR: #<n> (not yet merged)

Next, one of:
  a. /grv-sdlc:grv-milestone-setup         interactive, this tree, now (no merge in between)
  b. (human) mark ready and merge the intake PR, then
     /grv-sdlc:grv-epic-run <KEY>          unattended, own worktree, reads the default branch
```

## Error handling

- Not an Epic, or Done: stop, change nothing.
- On the default branch or a live milestone already open: stop with the reason.
- `gsd:new-milestone` stops early: report where; what it wrote is on the branch; rerun to resume.
  Nothing here writes to Jira.
- `gsd:ship` fails: the intake is still committed; create the PR with `gh pr create --draft`. The
  merge gate still applies however the PR was opened.
