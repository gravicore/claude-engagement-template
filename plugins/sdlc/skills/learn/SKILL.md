---
name: learn
description: >
  Two verbs. `extract <scope>` is autonomous: it turns evidence (a phase, a PR, a debug session, a
  git range, a conversation, a milestone, or refs handed over with `from`) into a dated ledger
  under `.planning/learnings/` using GSD's Decisions/Lessons/Patterns/Surprises schema plus
  Severity, Cause, Audience and Improvement tags, and never edits a governing file. `promote` is the
  human gate: it applies a recurrence-or-severity threshold, proposes a diff per candidate, routes
  agent items to AGENTS.md/CLAUDE.md/a SKILL.md/PROJECT.md and contributor or operator items to
  docs-sync, and writes only on an explicit Promote.
  Triggers on: "extract learnings", "learn from", "promote learnings", "learn extract",
  "learn promote", "learn".
allowed-tools:
  - Skill
  - Agent
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - WebFetch
  - AskUserQuestion
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__searchJiraIssuesUsingJql
  - mcp__atlassian__executeRead
  - mcp__slack__slack_search_public_and_private
  - mcp__slack__slack_read_thread
  - mcp__slack__slack_read_channel
---

# learn

Read `.sdlc/config.json` first; stop naming any missing required key. The split mirrors
`phase-complete`'s lanes: the autonomous half never prompts except to resolve its scope, and the
human half never writes silently. The subject is the **whole delivery process**, not only the code:
an agent's re-derivation, a slow human decision and a misplaced tool gate are three problems with
three different fixes, and folding them into one "lesson" hides all three.

## Ledger

File layout, item tags (Severity, Cause, Audience, Improvement, Requested by, Skill fit, Wait) and
the rule for each: `../../references/learn-ledger-schema.md` (path relative to this skill's
directory). The two that gate everything: a severity above `note` needs a receipt, and
`PROMOTED.md` is the authoritative promoted/dismissed record because gsd-core overwrites
`{N}-LEARNINGS.md` on re-run.

## extract

1. **Parse.** Default `session`. Scopes: `phase <N>`, `pr <#>`, `debug <slug>`, `range <a>..<b>`,
   `session`, `session <id>[,<id>]`, `session --search "<term>" [--since <date>]`,
   `session --since <date>`, `milestone <ver>`, `from <ref>...`. Compose with `+`; each side writes
   its own ledger. `phase` delegates to `Skill(skill="gsd-extract-learnings", args="{N}")`;
   `milestone` loops phase plus merged PRs no phase covers; `from` classifies each ref as path, URL,
   tracker key or quoted description (a description caps its items at `note` unless it names a
   receipt the skill can open).
2. **Resolve the scope.** Resolved on sight: never pause. `--search`/`--since` probe first: 1-8
   sessions is resolved, 0 is an error, more than 8 is ambiguous. Also ambiguous: intent with no
   scope kind, a ref that fans out to several scopes, a ref that fails classification. When
   ambiguous, run the cheap probes first, then ask with 2-4 literal, re-invocable scope strings, each
   with its size, one marked recommended (the narrowest scope containing the named event; add the
   sessions when the ask is about a correction), plus Other. A non-interactive caller never gets a
   prompt: stop with `Scope ambiguous and no human present; candidates: ...`.
3. **Guard phase scope.** Already graduated (inline marker or PROMOTED.md row): refuse unless
   `--force`, and say the re-run overwrites `{N}-LEARNINGS.md`.
4. **Collect.** Per scope. Past sessions: read only around correction-shaped events (a retraction,
   a repeated instruction, an interrupted run, "this is the second time", a rejected
   recommendation); those items are `human-correction` by construction, others cap at `note`. For
   any scope naming a ticket, PR or date range, also read (read-only) the tracker comments and the
   chat threads for those keys: requests and waits mostly live there. **Redact** every conversation
   and thread source: no secrets, connection strings or personal data; paraphrase when unsure.
5. **Extract.** Bare `session` runs inline (the live transcript exists only here); other scopes may
   use a subagent, classified to a role whose model and lens come from config (schema file,
   "Extraction roles"; never a hardcoded model). Read for all four causes, then a second pass for
   improvements. Check existing skills before writing `new skill`.
6. **Write** the ledger, even with zero items (`counts: 0`): absence of a complaint is not evidence.
7. **Commit** `docs(learnings): extract <scope>` (default branch or detached worktree: say uncommitted).
8. **Report** scope, sources, counts by category and severity, pending high-severity items, and the
   improvement tallies. `extract` never promotes.

## promote

1. **Args:** `--milestone <ver>`, `--since <date|ref>`, `--all` (show below-threshold), `--dry-run`.
2. **Scan** phase LEARNINGS files and ledgers; drop items already in PROMOTED.md or marked.
3. **Threshold.** Recurrence (2+ distinct extractions) or severity `shipped-defect`,
   `human-correction`, `control-bypass` alone. Improvements: a receipted request or a bottleneck of
   4+ working hours alone; a workflow item needs recurrence.
4. **Route.** No Audience tag: treat as `agent` and say so.
   - `agent`: this skill writes it. Scope test: still true with a different agent or none means
     `AGENTS.md`; true only because Claude Code is the tool means `CLAUDE.md`; one workflow's own
     step means that `SKILL.md`; a product decision means `.planning/PROJECT.md` Key Decisions.
   - `contributor` / `operator`: hand to `Skill(skill="sdlc:docs-sync",
args="--item \"{title}\" --audience {aud} --source {ledger}")`; never call `gsd-docs-update`
     directly. Code-derivable structure is not promoted as text: run `docs-sync --code-only`,
     then add the agent pointer.
   - Multi-audience: canonical write first, then one pointer per other audience (`--pointer-to` for
     docs readers, one line in the target file for agents).
   - Improvements by skill fit: an existing skill gets a process diff; `new skill` becomes a proposed
     tracker ticket (written only on Promote); `product` is listed for the product owner.
   - A `human`-caused item that fits no target is presented with the routing question open; never
     forced into a file that governs agents.
     Before proposing an append, grep the target and propose an **amend** instead when a rule exists,
     listing every index, TOC or pointer line that must change too: a corrected body behind a stale
     summary is still a stale rule.
5. **Gate.** Per candidate show the literal diff and receipts, then ask Promote / Defer / Dismiss /
   Defer all remaining. A diff touching a control's description (a ruleset, signing, an access
   policy) is prefixed `Security:` and needs the human to confirm they read the control's purpose
   first: a control's purpose outranks its indicator.
6. **Apply.** Promote (agent): edit, PROMOTED.md row, inline marker, one commit per target file.
   Promote (docs): mark with the destination docs-sync **reported**; if it returned the item
   unwritten, that is a Defer, with no row. Multi-audience: canonical row first, a failed pointer is
   reported as deferred without rolling back the body. Dismiss: marker plus row. Defer: nothing.
7. **Report** promoted (by lane and destination), deferred, dismissed, held below threshold, untagged
   items treated as agent, improvement routing. Zero candidates is reported explicitly.

## Error handling

gsd-extract-learnings errors: report verbatim, never synthesize from git history. PR or session id
not found: stop for that one, continue the rest, name it. A zero-match probe: report the filter;
widening is the human's call.
