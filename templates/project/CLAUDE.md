> **Scope of this file.** CLAUDE.md holds only what exists because Claude Code is the tool: slash
> commands, skills, `.claude/` authoring, delivery-engine wiring, agent and model routing.
> Everything true about the project regardless of tooling (stack, structure, conventions, review
> discipline, security invariants, environments, tracker process) lives in `AGENTS.md`, included
> below. When adding a rule, ask: "would this still be true with a different agent, or none?" If
> yes, it belongs in `AGENTS.md`, not here.

@AGENTS.md

# Claude Code Conventions

- **In `.claude/` files (hooks, skills, commands) use bare relative paths** such as
  `.claude/foo.md`, never a project-directory environment variable. Why: those variables do not
  resolve in every Claude Code context, and the failure is silent.
- **Agent and model routing resolves from `.planning/config.json`** (`model_profile`,
  `models[phase_type]`, `model_overrides[agent]`). That file is the single source of truth; never
  hardcode a model table in a skill or in this file. Why: a private table drifts from the config
  and the wrong model runs unnoticed.
- **A bare one-word instruction with no stated object ("undo", "revert", "stop") is clarified
  before it is acted on, not investigated first.** Ask "undo what?"; inspecting git state is a
  fine second step once the target is known. Why: investigating first acts on a guess about what
  the user meant.
- **A skill's `allowed-tools` frontmatter gates what it may call.** A step that fails for a
  missing tool inside a subagent is an allowlist gap to escalate, not an environment limitation.
  Why: recording it as "the environment can't do this" propagates a false claim.
- **Connector tool names change.** Translate the names a skill's prose uses to the connector
  that is installed, look up an operation's exact name before calling it, and never guess one.

<!-- FILL: connector specifics for this workspace, if any: which tracker and chat connectors are
installed, and any old-name to new-name translation table the skills' prose needs. -->

# Delivery Engine (gsd-core)

- **gsd-core is consumed from a global install and is never vendored in this repo.** Every
  developer machine needs it installed globally (`npx @opengsd/gsd-core@latest --claude --global`,
  which installs to `~/.claude/gsd-core/`; repository `github.com/open-gsd/gsd-core`; verified on
  1.19.0, re-check on newer versions) at or above `engine.gsdCoreMinVersion` in `.sdlc/config.json`. Do not commit an eject, a copy of
  its commands, or a hook layer. Why: a vendored copy goes stale on one machine and hard-requires
  tooling the others no longer have.
- **The global install is never patched.** A defect in the engine is worked around in an `sdlc:*`
  skill or reported upstream. Why: a local patch disappears on the next update and nobody
  remembers it existed.
- **The `sdlc` skills are coupled to gsd-core's behavior, not its code.** The assumptions
  they depend on are listed in the plugin's `references/gsd-core-assumptions.md`. Re-test every
  item on that list on each gsd-core version bump before running a phase on the new version, and
  record the result there. Why: the coupling is invisible until an update breaks it mid-phase.
- **`.claude/settings.json` carries project permissions only.** Skills, commands, hooks and
  statusline come from the global install and the plugin marketplace.
- **Branch names and creation belong to the engine's config** (the `git` section of
  `.planning/config.json`). Do not hand-construct or hand-name branches.

# Invoking the Workflows

The workflows themselves, and the order they run in, are documented in `AGENTS.md` under
`# Delivery Workflow`. This section covers only how Claude Code invokes them.

- The `sdlc` plugin's skills are invoked with the plugin namespace, for example
  `/sdlc:phase-run 12`. Claude Code namespaces plugin skills as `/<plugin>:<skill>`; a flat
  `/phase-run` alias is not documented for plugin skills in general, so treat it as UNVERIFIED -
  confirm against current docs. The table below and the rest of this repo's prose write the full
  namespaced form, which is what to type.
- gsd-core's own bare commands exist on every machine, but most have an `sdlc:*` wrapper that must
  be used instead. **Never suggest a bare `/gsd-*` or `/gsd:*` command to the user, in a "Next:"
  block or anywhere else, when a wrapper below exists, even when gsd-core's own output (a
  banner, a `next_command` field, a progress suggestion) names the bare command.** That upstream
  text is routing input for the orchestrating skill, not something to relay. Why: the bare
  command skips the tracker transitions, the human gates and the verification lanes the wrapper
  adds, and the most common leak is relaying an engine banner verbatim.

| Bare gsd-core command                     | Wrapper to use                                                                            | Notes                                                                                                     |
| ----------------------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `/gsd-new-milestone`                      | `/sdlc:milestone-init <epic-key>`                                                         | The wrapper embeds the epic key where downstream skills expect it                                         |
| `/gsd-discuss-phase`, `/gsd-plan-phase`   | `/sdlc:phase-run <N>`, or `/sdlc:milestone-planner` for a full-milestone pass             | Called internally by the wrappers                                                                         |
| `/gsd-execute-phase`                      | `/sdlc:phase-run <N>`                                                                     | Fine for an agent's own use inside a wrapper; never surfaced as the next user-facing command              |
| `/gsd-verify-work`                        | `/sdlc:phase-complete <N>`                                                                | The bare command has no create path for a verification report and is a silent no-op against a missing one |
| `/gsd-ship`                               | `/sdlc:phase-run <N>` (draft) or `/sdlc:phase-complete <N>` (tracker close-out around it) | The bare command skips the UAT transition                                                                 |
| `/gsd-autonomous`                         | `/sdlc:milestone-run`, or `/sdlc:epic-run <epic-key>` for a whole epic                    | The wrappers halt at every human gate                                                                     |
| `/gsd-quick`, `/gsd-fast`                 | `/sdlc:story-deliver <ticket-key>`                                                        | The wrapper isolates the work and ties it to a ticket                                                     |
| `/gsd-audit-milestone`                    | `/sdlc:milestone-review <version>`                                                        | Adds the cross-phase gates around the audit                                                               |
| `/gsd-complete-milestone`, `/gsd-cleanup` | `/sdlc:milestone-complete`, then `/sdlc:release-close` after the merge                    | One combined close-out; never run the pieces separately                                                   |
| `/gsd-extract-learnings`                  | `/sdlc:learn extract <scope>`                                                             | Promotion into instruction files is `/sdlc:learn promote`, a human gate                                   |
| `/gsd-docs-update`                        | `/sdlc:docs-sync`                                                                         | One hop; the wrapper also covers docs the engine cannot reach                                             |
| `/gsd-progress`                           | none; safe to suggest directly                                                            | Read-only status query, outside the write path this table protects                                        |

If a workflow does not appear in this table, check whether an `sdlc:*` skill covers it before
suggesting the bare form. The table lists the commands that have caused confusion; it is not a
claimed-complete list.

<!-- FILL: project-specific Claude Code notes: local skills beyond the plugin, hooks that gate
commands against hosted environments, and any engine behavior this repo has had to work around
(with the engine version it was observed on). -->
