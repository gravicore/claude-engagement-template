# Docs Sync Routing, Lane Marker and Gap Index

Reference detail for `docs-sync`. The skill decides which lane an item belongs to from this
table; the marker and the gap index are what keep the two lanes from overwriting each other.

## Routing

| Audience or content                                               | Destination                                                  | Owner                                                                                                        |
| ----------------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `agent` rules                                                     | `AGENTS.md`, `CLAUDE.md`, a `SKILL.md`, `PROJECT.md`         | refuse; name learn promote                                                                                   |
| `contributor`                                                     | `docs/<area>/<topic>.md`, **unmarked**                       | Lane B                                                                                                       |
| `operator`                                                        | the wiki under `{config: docs.parentPageId}`                 | Lane B, on confirmation                                                                                      |
| code-derived facts                                                | `docs/` files marked `<!-- generated-by: gsd-doc-writer -->` | Lane A                                                                                                       |
| architecture structure (layers, request path, stages, module map) | `docs/architecture/overview.md`, marked                      | Lane A; `AGENTS.md` carries one pointer, never a restatement                                                 |
| controls and invariants (what enforces what, at which layer)      | `AGENTS.md`                                                  | refuse here; rationale for humans goes to an unmarked `docs/architecture/rationale-<topic>.md` that links it |
| anything from or into `.planning/codebase/`                       | none                                                         | refuse: a regenerated planner cache, not a source or destination                                             |

**The marker is the lane boundary.** A marked file is regenerated without asking, so a Lane B doc
must never carry the marker (it would be silently deleted next run), and a marked file is never
hand-edited (the edit is lost): fix the code or re-run Lane A. Prefer a sibling file to an
insertion into a generated one.

## Gap index

`.planning/docs/SYNCED.md`, append-only: `| date | item | audience | source | destination | status |`
with status `open`, `synced` (a real path or page id) or `dismissed` (reason). An open row is the
whole gap mechanism; it re-surfaces in the next audit. Never write gsd-core's own run manifest.
