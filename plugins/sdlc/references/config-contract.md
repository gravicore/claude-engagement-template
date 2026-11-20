# SDLC Project Config Contract

Every `sdlc` skill reads project coordinates from one file in the consuming repository:
`.sdlc/config.json`. No skill hardcodes a tracker key, repository, environment, channel or person.
A skill that needs a key that is missing stops and names the key; it never guesses a value.

The JSON Schema is `plugins/sdlc/references/sdlc-config.schema.json`. A starter file is
`templates/project/.sdlc/config.json`.

## Keys

| Path                                                              | Type                            | Meaning                                                                       |
| ----------------------------------------------------------------- | ------------------------------- | ----------------------------------------------------------------------------- |
| `project.name`                                                    | string                          | Human name of the product or service                                          |
| `project.key`                                                     | string                          | Short slug used in branch names and skill output                              |
| `repo.owner` / `repo.name`                                        | string                          | GitHub coordinates                                                            |
| `repo.defaultBranch`                                              | string                          | Usually `main`                                                                |
| `repo.requiredChecks`                                             | string[]                        | Names of the required status checks (merge gates)                             |
| `repo.mergePolicy`                                                | `squash` \| `merge` \| `rebase` | What the ruleset allows                                                       |
| `tracker.type`                                                    | `jira`                          | Only Jira is supported today                                                  |
| `tracker.cloudId`                                                 | string                          | Atlassian site id                                                             |
| `tracker.projectKey`                                              | string                          | Jira project key, e.g. `ABC`                                                  |
| `tracker.transitions.selected` / `.inProgress` / `.uat` / `.done` | string                          | Transition **ids**, never display names                                       |
| `tracker.labels.provenance`                                       | string                          | Permanent agent-provenance label (default `ai`)                               |
| `tracker.labels.stage`                                            | object                          | `discussing`, `planning`, `executing`, `halted` stage labels                  |
| `tracker.releaseGateEpic`                                         | string \| null                  | Epic gating promotion to live production                                      |
| `owners.productOwner` / `owners.leadEngineer`                     | string                          | Named individuals (decisions name a person, never a team)                     |
| `environments[]`                                                  | object[]                        | `{ name, url, dataClass: synthetic \| production, promotion: auto \| human }` |
| `chat.type` / `chat.channel`                                      | string                          | `slack` and channel name, or `none`                                           |
| `docs.type` / `docs.spaceId` / `docs.parentPageId`                | string                          | `confluence` coordinates, or `none`                                           |
| `compliance.regimes`                                              | string[]                        | e.g. `["SOC2", "GLBA"]`; drives the flag lines skills print                   |
| `engine.gsdCoreMinVersion`                                        | string                          | Minimum gsd-core version the skills were verified on                          |
| `verification.localStack`                                         | string \| null                  | Command that brings up the local stack, if any                                |
| `verification.preview`                                            | `none` \| `per-pr`              | Whether each PR gets a preview environment                                    |

## Optional keys

Everything in the table above is required; use `null`, `"none"` or `[]` for a capability the
project does not have. The keys below are optional. A skill skips the behaviour when the key is
absent and never guesses a value.

| Path                                                       | Type           | Meaning                                                                                                                                                                |
| ---------------------------------------------------------- | -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tracker.siteUrl`                                          | string \| null | Base URL of the tracker site, for browse links only                                                                                                                    |
| `tracker.fields.storyPoints` / `.track` / `.specReference` | string \| null | Custom field ids                                                                                                                                                       |
| `tracker.linkTypes.blocks`                                 | string         | Name of the Blocks issue link type                                                                                                                                     |
| `tracker.componentMap`                                     | object         | Prefix to tracker component name. A key ending `/` is a repository path prefix (used on a diff); a key ending `-` is a requirement-id prefix (used before code exists) |
| `release.targetEnvironment`                                | string         | Name of the `environments[]` entry a release ships to                                                                                                                  |

Not in the config by design: an Approved transition (a human act the skills never perform), agent
credentials or signing keys (never stored in a repo), and working hours.

## Rules for skill authors

1. First step of every skill: read `.sdlc/config.json`; fail closed on a missing required key.
2. Reference values as `{config: tracker.projectKey}` in prose so a reader can see the source, and
   optional ones as `{config: tracker.siteUrl}` (optional) so a reader knows absence is allowed.
3. Human gates are not configurable: merge, ticket closure, UAT sign-off, release publication
   and ruleset changes always wait for a named human, whatever the config says.
4. Project-specific technology rules (framework footguns, database rules) belong in the consuming
   repo's `AGENTS.md`, never in a skill.
