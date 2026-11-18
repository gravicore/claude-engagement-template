---
name: grv-docs-sync
description: >
  One entry point for making the docs true again, in two lanes. Lane A (code-derived) is a thin
  single-hop wrapper around gsd-core's docs update, with `--audit` mapped to its read-only verify
  pass. Lane B (not code-derivable) writes contributor rationale to unmarked `docs/` siblings and
  operator runbooks to the project wiki, on confirmation. Agent-facing rules are refused and left
  to grv-learn. Also the single destination grv-learn and grv-milestone-complete call for
  contributor or operator items and one-line `--pointer-to` cross-references.
  Triggers on: "docs sync", "update the docs", "refresh documentation", "docs audit", "grv-docs-sync".
allowed-tools:
  - Skill
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - AskUserQuestion
  - mcp__atlassian__getConfluenceContent
  - mcp__atlassian__searchConfluence
  - mcp__atlassian__createConfluenceContent
  - mcp__atlassian__updateConfluenceContent
  - mcp__atlassian__discover
  - mcp__atlassian__executeRead
---

# grv-docs-sync

Read `.grv/sdlc.json` first; stop naming any missing required key. Wiki coordinates are
`{config: docs.type}`, `{config: docs.spaceId}`, `{config: docs.parentPageId}`; the page conventions
(title prefix, label, section template) are the ones the project's `AGENTS.md` records.

- **Lane A, code-derived.** README, architecture, getting-started, development, testing,
  configuration and the like, fact-checked against the tree by gsd-core. This lane is a wrapper,
  never a reimplementation: it makes exactly one call.
- **Lane B, not code-derivable.** Rationale and operator runbooks. gsd-core's doc writer and
  verifier have no MCP tools and check only syntactic claims about code, so they can never reach a
  wiki or verify a rationale.

## Arguments

- none: Lane A then Lane B audit-and-propose.
- `--audit`: read-only; Lane A runs as `--verify-only`, Lane B lists open gaps. Writes nothing.
- `--code-only` / `--knowledge-only`: one lane. `--dry-run`: do the work, apply no write.
- `--item "<title>" --audience <contributor|operator> [--source <ref>]`: Lane B for one item,
  non-interactive (the shape grv-learn uses). `--item` with `--code-only` is a contradiction: stop.
- `--item ... --pointer-to "<destination>"`: write one cross-reference line to an existing canonical
  home and no body. One audience per call.
- `--force`: passed to Lane A only. A wiki page is never overwritten unprompted.

## The one-hop rule

This skill calls gsd-core's docs update and nothing else; it never calls another `grv-*` skill. The
graph, not the intent, is what erodes: every later caller wants one more delegation. Permitted
depth is at most `caller -> grv-docs-sync -> gsd-docs-update`. Callers never call gsd-docs-update
themselves (a second path would skip Lane B). Check it mechanically on a diff: this file has exactly
one line starting with `Skill(skill=` and it names `gsd-docs-update`.

## Routing, marker and gap index

Full table and rules: `../../references/docs-sync-routing.md` (path relative to this skill's
directory). `agent` rules: refused (owner `grv-learn` promote). `contributor`: **unmarked** `docs/`
files. `operator`: the wiki under `{config: docs.parentPageId}`, on confirmation. Code-derived
facts: Lane A, files marked `<!-- generated-by: gsd-doc-writer -->`, never hand-edited; a Lane B doc
never carries the marker. `.planning/codebase/` is neither source nor destination. Gaps are rows in
`.planning/docs/SYNCED.md` (append-only).

## Process

**1. Pick lanes.** A skill-invoked run that would need to ask stops and reports the question.

**2. Lane A** (skip on `--knowledge-only`). The single call:

```text
Skill(skill="gsd-docs-update", args="<--verify-only if --audit> <--force if --force>")
```

Then leave it alone: do not read its manifest, re-run it or hand-fix its findings. Record its
summary verbatim for the report. If it prompts about a hand-written file, the prompt is the human's;
in a skill-invoked run answer `preserve` and report that a human decision is needed. Never answer
regenerate on a human's behalf.

**3. Lane B audit** (skip on `--code-only`; with `--item` go to step 4). Cheap reads only: open
index rows; unmarked files under `docs/` (`grep -rL 'generated-by: gsd-doc-writer' docs/`) and
recent changes to them; knowledge with no home that the caller or the human hands over (a decision
living only in a PR thread, a runbook the process has outgrown); and control claims inside marked
docs (grep them for enforce, constraint, tenant check and similar, and read each against
`AGENTS.md`). A contradiction is an open row; its remedy is a `--code-only` regenerate or a note
that the claim belongs in `AGENTS.md`, never a hand-edit or a copy. Append an `open` row per new
gap. `--audit` stops here.

**4. Lane B write**, one item at a time:

- `agent`: refuse, name the owner, leave the row open.
- `contributor`: propose the literal diff. Grep the area first and propose an **amend** when a
  passage exists, listing every index or pointer line that must change too. Confirm the target has
  no marker before writing.
- `--pointer-to`: confirm the destination exists (path on disk, heading greps, page id resolves).
  Write exactly one line into an unmarked file or the page's resources section. Never create the
  destination to make a pointer valid.
- `operator`: requires `{config: docs.type}` not `none`. Search first and update an existing page
  rather than near-duplicating; batch edits (every update bumps the version). Plain text, never
  HTML-escaped. A create or update is outward-facing: confirm in-session; with no human present,
  leave the row open and report.
  Flip a row to `synced` only with the real destination.

**5. Commit** `docs/` and the index (`docs: sync <what> (<audience>)`); on the default branch or a
detached worktree say it is uncommitted. Lane A commits on its own terms.

**6. Report** Lane A's summary verbatim; Lane B gaps found, synced, dismissed, open (zero included);
and `Depth: <caller> -> grv-docs-sync -> gsd-docs-update. No other skill invoked.`

## Error handling

- Lane A fails: report verbatim, continue to Lane B; never hand-write what it would generate.
- Wiki unauthorized or `docs.type` is `none`: leave operator rows open with the reason; never write
  an operator runbook into `docs/` instead (its audience will not find it there).
- Target carries the marker, or a pointer destination does not exist: stop for that item, row open;
  never strip the marker. A caller asks for another `grv-*` skill: refuse, cite the one-hop rule.
