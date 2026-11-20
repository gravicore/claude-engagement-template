# Engagement template

How to create an engagement instance from this template, finish setting it up, and keep it current with later template
changes. For the wider rollout (people, training, cadence) see `docs/enablement/01-rollout-playbook.md` and
`docs/enablement/02-client-org-setup.md`.

An instance is one repo per client engagement: that client's centralized skills and agent repository, published as a
Claude Code plugin marketplace. It ships with the generic `sdlc` delivery-lifecycle plugin pre-registered; plugins
authored for the engagement are added beside it, named with the engagement prefix chosen at init.

## 1. Choose where the instance lives

Both options are supported; the choice does not change the repo contents.

| Option           | Hosted in                    | Maintaining consultancy's role                  | Client's role                                           |
| ---------------- | ---------------------------- | ----------------------------------------------- | ------------------------------------------------------- |
| Consultancy org  | The consultancy's GitHub org | Owns and administers the repo                   | Read access to install; may be granted write for PRs    |
| Client's own org | Client's GitHub org          | Contributes by pull request, never owns the org | Owns administration, branch protection, and access list |

Whichever org hosts it is the org name you pass to init. Create the repo as **private**: an instance holds engagement-specific content and stays private, even though the template and the `sdlc` plugin it starts from are open source under Apache-2.0 (see `LICENSE` and `NOTICE`).

## 2. Create the repo from the template

Either use the "Use this template" button on the template repo (owner: the hosting org, visibility: private), or from
a terminal:

```sh
gh repo create <org>/<slug> --template <template-owner>/<template-repo> --private --clone
cd <slug>
```

`<slug>` is the engagement's kebab-case slug, for example `acme-lending`.

Immediately record the template commit the instance started from, so later updates have a baseline (section 7):

```sh
git remote add template <template-repo-url>
git fetch template
git tag template-synced template/main
```

This assumes the template did not change between creating the repo and fetching, which holds when you do it right away.

## 3. Initialize

Work on a branch, not `main`:

```sh
git checkout -b gsd/init-engagement
scripts/init-engagement.sh \
  --name "Acme Lending" \
  --slug acme-lending \
  --org example-org \
  --prefix acme \
  --regimes "GLBA, SOC 2"
```

Flags:

| Flag            | Replaces the placeholder for | Notes                                              |
| --------------- | ---------------------------- | -------------------------------------------------- |
| `--name`        | ENGAGEMENT_NAME              | Human name, free text                              |
| `--slug`        | ENGAGEMENT_SLUG              | Lowercase kebab-case; also the repo name           |
| `--org`         | GITHUB_ORG                   | The org that hosts the instance                    |
| `--prefix`      | PREFIX                       | 2-8 chars, `^[a-z][a-z0-9]{1,7}$`; see below       |
| `--marketplace` | MARKETPLACE_NAME             | Optional; defaults to the prefix                   |
| `--regimes`     | COMPLIANCE_REGIMES           | Free text list of regimes in scope for this client |

Placeholders are double-curly-brace tokens named as in the table.

The prefix is a short engagement code (for example `acme`). Plugins and skills authored for this engagement are named
with it (`acme-servicing`, `acme-loan-summary`), while the generic `sdlc` plugin and its skills stay unprefixed. Init
writes it into `.engagement.json`, which the naming checks in CI, the pre-commit hook and `mise run validate` read. Pick
it once: renaming later means renaming every engagement plugin and skill. The script:

- replaces every occurrence in every text file, and prints each file with its replacement count;
- removes the template-only blocks (delimited by template:begin and template:end HTML comments) from `README.md`,
  `AGENTS.md`, and `CLAUDE.md`;
- never touches `.git`;
- refuses to run when no placeholder remains, so it cannot be applied twice;
- supports `--dry-run` to preview.

Review `git diff`, commit, push, and merge through a PR. Then run `mise run setup` (installs tools and activates the
git hooks) and `mise run lint && mise run validate`.

Do not substitute placeholders by hand and do not run init in the template repo itself.

## 4. Finish setup (manual)

- **CODEOWNERS**: it names a team called `<slug>-maintainers` in the hosting org. Create that team or edit the file to
  an existing one, and make the same change in `plugins/sdlc/references/OWNERS.md`. Every plugin directory needs its
  own CODEOWNERS line and an `OWNERS.md`; CI fails a plugin without both, or where the two name different owners.
- **More plugins**: this is one marketplace for many plugins. `docs/PLUGIN-TAXONOMY.md` describes the layers and the
  rules; `python3 scripts/new-plugin.py` scaffolds a new plugin with its owner records.
- **`.clients`**: list engagement-specific sensitive names one per line (client system names, partner IDs, personal
  identifiers). CI fails any pull request that has them outside `plugins/*/references/` (that is the enforcement), and
  a Claude Code PreToolUse hook refuses a Claude Code write that would add one (a local convenience that Bash
  redirects and other tools bypass). Do not list the engagement name itself; it legitimately appears in the root docs.
- **Secrets**: add the `ANTHROPIC_API_KEY` Actions secret in the hosting org or repo. The `scan-plugins` workflow
  needs it and was skipped while the repo was a template.
- **Repo settings**: allow squash merge only, and enable automatic deletion of merged head branches.

## 5. Branch protection (human act)

`.github/branch-protection.json` is a reference copy of the intended protection for `main`, with the repo coordinates
filled in by init. **Applying or changing branch protection or rulesets is a human repo-admin act, never an agent's.**
An agent that hits a blocked push reports it; it does not clear it, and agent credentials should not carry repo
administration rights. A person with admin rights on the hosting repo applies the protection from the reference copy
(repo settings, or the branch protection API after removing the `_comment` key), checks that the required status
checks match the CI job names, and re-exports any later change to the reference copy in a reviewed PR so the diff is the
record. Applying the ruleset is a human act; nothing in this repo applies it.

The reference copy requires the eight jobs of `validate.yml`, which run on every pull request to `main`: Validate
plugin integrity, Scan secrets, Check CODEOWNERS entries, Lint YAML workflows, Lint SKILL.md files, Format check, Lint
shell scripts, Validate plugins (claude CLI). `validate-frontmatter.yml` and `scan-plugins.yml` are path-filtered, so
requiring them would block every pull request that does not touch matching files; they are checks but not required
ones.

## 6. Grant access and install

Access follows the hosting choice:

- **Consultancy-hosted**: grant the client's users read access so they can install; grant the consultancy's
  contributors write.
- **Client-hosted**: the client grants the consultancy's contributors write or lets them open PRs from forks, and keeps
  administration to itself.

Anyone installing needs read access to the repo and a working GitHub credential on their machine. For a private
marketplace, background auto-update may additionally need a token in the environment; check the current Claude Code
plugin documentation for the exact variable.

Install, in Claude Code or Claude Cowork:

```text
/plugin marketplace add {{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}
/plugin install sdlc@{{MARKETPLACE_NAME}}
```

## 7. Pull later template updates into an instance

The template keeps evolving; an instance pulls changes on purpose, in a PR, never automatically. Because instance PRs
are squash-merged, the template's history never becomes an ancestor of `main`, so a plain `git merge` would conflict
again on every sync. Diff from the recorded baseline instead:

```sh
git fetch template
git checkout -b gsd/template-sync
git diff template-synced template/main -- . ':(exclude).clients' ':(exclude).planning' > ../template.patch
git apply --3way ../template.patch
```

Resolve conflicts by hand: files init edited (README, AGENTS, CLAUDE, CODEOWNERS, `marketplace.json`, `.engagement.json`) will conflict on
substituted lines, and the right answer is nearly always to keep the instance's values and take the template's new
structure. If the incoming change introduces new placeholder tokens, re-run `scripts/init-engagement.sh` with the
instance's original flag values; it replaces only what remains. Then run `mise run lint && mise run validate`, open a PR,
and after merge move the baseline:

```sh
git tag -f template-synced template/main
git push origin template-synced --force
```

Review incoming `plugins/sdlc` changes like any plugin change: `version` in `plugin.json` and in the marketplace
entry must still match (CI checks version drift; Claude Code itself uses the `plugin.json` value when both are set).

An instance that prefers merge commits for sync PRs may instead run
`git merge template/main --allow-unrelated-histories` once and plain `git merge template/main` afterwards; the same
conflict guidance applies.

## 8. What not to do

- Do not edit placeholders by hand or re-run init to change values after the fact; change the files directly.
- Do not add the engagement name to `.clients`.
- Do not put customer PII or account identifiers in skill prompts; use `references/`.
- Do not let an agent apply, change, or bypass branch protection or rulesets.
