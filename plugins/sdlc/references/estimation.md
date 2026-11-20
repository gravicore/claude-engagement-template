# Story Points and Original Estimates

Shared by `milestone-sync` (a Story created from the roadmap, before planning) and
`story-update` (the same Story after planning, or a quick change after commits). Points and
estimates are computed **independently**; neither is derived from the other. Both are advisory
inputs to planning, which is why every skill that writes them previews them first.

Estimate buckets: `2h, 4h, 1d, 2d, 3d, 4d, 5d`. Cap `5d`: anything larger means split the phase.
When ambiguous, round up; it corrects for the planning fallacy. Round estimates only.

## Before planning (`milestone-sync`)

- **Story points:** `max(1, min(8, req_count * 2 + (ui_hint ? 1 : 0)))`.
- **Original estimate** by requirement count and UI hint: 1 req `4h` (`1d` with UI); 2 reqs `1d`
  (`2d` with UI); 3 reqs `2d`; 3-4 reqs with UI `3d`; 4+ reqs `3d`; 5+ reqs `4d`.
- **Booster:** advance one bucket if the text mentions a new page or route, a multi-step flow,
  real-time, permissions, tenancy or auth, or the phase has 4+ acceptance criteria.

## After planning (`story-update`, phase mode)

| Phase `task_count` | Estimate |
| ------------------ | -------- |
| 1-2                | `4h`     |
| 3-4                | `1d`     |
| 5-7                | `2d`     |
| 8-11               | `3d`     |
| 12-15              | `4d`     |
| 16+                | `5d`     |

- **Booster:** advance one bucket if a task mentions migration, new route, new page, real-time,
  multi-step, permissions, auth or refactor.
- **Sweep phases** (a restyle, rename or fix pass across many call sites): task count is a poor
  proxy, because plans restructure around what the sweep touches while the task count stays flat.
  Use the scope probe's `site_count` (from CONTEXT.md or the phase's committed probe script) through
  the same buckets, and take the larger of the two when both exist. With neither, say in Technical
  Notes that scope was estimated from task count only.
- **Story points:** `max(1, min(13, ceil(task_count / 3)))`; with no tasks, the pre-planning formula.

## Quick changes (`story-update`, quick mode)

| `total_lines` (insertions + deletions) | Estimate | Story points |
| -------------------------------------- | -------- | ------------ |
| under 100                              | `2h`     | 1            |
| 100-299                                | `4h`     | 2            |
| 300-599                                | `1d`     | 3            |
| 600-999                                | `2d`     | 5            |
| 1000+                                  | `3d`     | 5            |

An explicit estimate in the PR body wins.
