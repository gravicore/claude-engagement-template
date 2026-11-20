# Plugin taxonomy

How this marketplace is divided into plugins, who owns each one, and how a new one is added. One repository, one
marketplace, many plugins: people install only the plugins they need.

## Layers

The engagement prefix is `{{PREFIX}}`. It is written as `<prefix>` in the table.

| Layer       | Plugin name                    | Holds                                                                | Changed by                                  |
| ----------- | ------------------------------ | -------------------------------------------------------------------- | ------------------------------------------- |
| Generic     | `sdlc`                         | The delivery-lifecycle skills shipped by the template                | Template updates (`TEMPLATE.md`, section 7) |
| Shared      | `<prefix>-shared`              | Skills and reference files that more than one team or department use | The marketplace maintainers                 |
| Engineering | `<prefix>-eng-<stack-or-team>` | Stack- or team-specific engineering skills and instructions          | That team's lead                            |
| Department  | `<prefix>-<department>`        | A business department's skills                                       | A named owner in that department            |

Only `sdlc` exists when the instance is created. Create the others when there is a first real skill for them, not
before: an empty plugin is one more thing to own.

## Plugins in this marketplace

Keep this table current. `scripts/new-plugin.py` creates the plugin; add its row here in the same pull request. The
owner of each plugin is recorded in `CODEOWNERS` and in the plugin's `references/OWNERS.md`, not here.

| Plugin | Layer   | Audience              |
| ------ | ------- | --------------------- |
| `sdlc` | Generic | All engineering teams |

## Rules

1. **One plugin per owning group.** A plugin maps to one team or department, so it is always clear who decides. If two
   groups would both need to approve changes, the content belongs in the shared plugin.
2. **No reference files shared across plugins.** A skill reads `references/` in its own plugin only. Content that a
   second plugin needs moves to `{{PREFIX}}-shared`; it is not copied.
3. **Skills hand off; they do not call across plugins.** When a skill's output is the natural input of a skill in
   another plugin, its output ends with a "next step" line naming that skill. Calls between skills stay inside one
   plugin (`sdlc` skills call `sdlc` skills).
4. **One clear purpose per skill.** A skill that drafts does not also review; a skill that reviews does not also draft.
5. **Stubs are honest.** A planned skill may be listed as a stub (`docs/contributing/STUB-FORMAT.md`); it says it is not
   implemented and does nothing else.
6. **Names are prefixed and unique.** Engagement plugins and their skills start with `{{PREFIX}}-`, and a skill name is
   unique across every plugin (`.claude/docs/naming-convention.md`, enforced by `scripts/check-naming.py`).
7. **Each plugin is versioned on its own.** A change to a plugin bumps `version` in its `plugin.json` and in its
   `marketplace.json` entry in the same pull request. CI fails when the two differ.

## Ownership

Every plugin has two records, and CI (`scripts/check-plugin-owners.py`) fails a plugin that lacks either or where they
disagree:

- **`CODEOWNERS`** has a line for the plugin's own directory. The catch-all and a `plugins/*` wildcard do not count.
  This routes every pull request that touches the plugin to its owner.
- **`plugins/<plugin>/references/OWNERS.md`** names the owner team, the audience, the chat channel, and where skill
  requests and bug reports go. It is the entry point for people who will never open a pull request.

CODEOWNERS routes review; it only blocks a merge when branch protection on the hosting repo requires code-owner review.
Applying that protection is a human repo-admin act (`TEMPLATE.md`, section 5).

Changes to `.claude-plugin/marketplace.json`, `.github/` and `scripts/` stay with the marketplace maintainers.

## Where an instruction lives

A lesson or rule goes at the narrowest level it applies to, and moves up only when it recurs:

1. **One consuming repository** - that repository's own `AGENTS.md`.
2. **One stack, team or department** - that plugin here (a skill, a file in its `references/`, or its path-scoped rule
   file `.claude/rules/<plugin>.md`).
3. **Everyone** - `{{PREFIX}}-shared`, or for the delivery lifecycle itself, the generic `sdlc` plugin by way of the
   template.

`sdlc:learn promote` proposes the change; the owner of the level it lands in approves it.

## Adding a plugin

```text
python3 scripts/new-plugin.py --name {{PREFIX}}-<name> --owner @<org>/<team> --description "<one sentence>"
```

It creates the manifest, `references/OWNERS.md` and `.claude/rules/<plugin>.md`, and adds the CODEOWNERS line and the
marketplace entry. Then, in the same pull request:

1. Add the first skill under `plugins/<plugin>/skills/` (`docs/contributing/SKILL-AUTHORING.md`).
2. Add the plugin's row to the table above.
3. Create the owning team in the hosting org if it does not exist. CODEOWNERS ignores a team that does not exist or has
   no write access to the repo.
4. Run `python3 scripts/check-naming.py` and `python3 scripts/check-plugin-owners.py`.

## When to use a second repository

Keep one repository unless one of these is true:

- **Confidentiality.** A hosting repository cannot restrict read access by directory. Skills that not everyone with
  access to this repository may read need their own private repository.
- **A different change-control regime.** If one group's skills need a review path that the rules on this repository
  cannot express without exceptions.
- **Noise.** Reviewers are flooded by another group's pull requests, or CI has become slow for everyone.

Moving a plugin directory out later keeps its history; merging separate repositories later is much harder.
