# Client Organization Setup

Steps for the client platform lead (with the consultancy lead engineer) to stand up the instance
and get the plugin onto developers' machines.

Verification note: Claude Code facts below were checked on 2026-11-18 against these official pages:
`https://code.claude.com/docs/en/plugins/create-marketplace.md` (reached from `.../plugin-marketplaces`),
`.../plugins/marketplace-reference.md`, `.../plugins/host-marketplace.md`, `.../plugins/org.md`,
`.../managed-settings.md`, `.../settings.md`, `.../settings-reference`, `.../permissions.md`,
`.../hooks.md`, `.../memory.md`, `.../skills.md` and `.../mcp`. Items not covered by those pages are
marked "UNVERIFIED - confirm against current docs". Claude Code changes quickly; re-check before
each phase.

## 1. Create the instance in the client org

1. In the client's GitHub organization, create a new repository from the template (use the
   "Use this template" flow or `gh repo create <org>/<name> --template <template-repo> --private`;
   the second form is UNVERIFIED - confirm the flags against the current GitHub CLI manual).
2. Set visibility to private. The instance holds process knowledge and, over time, project
   references; it should not be public.
3. Grant access by team, not by individual: a platform team with admin, a maintainers team with
   write plus code-owner review, all developers with read. The consultancy's contributors get write
   only through a fork or a restricted team, so their changes arrive by pull request.
4. Edit `CODEOWNERS` to the client's real teams, and rename the marketplace in
   `.claude-plugin/marketplace.json`. The marketplace `name` is what developers type after `@`, it
   is taken from that file rather than the repository name, and a user cannot register two
   marketplaces with the same name. Pick a name other authors are unlikely to choose.
5. Run `claude plugin validate .` from the repository root and fix every error before publishing
   (verified: the command validates JSON syntax, required fields and names).
6. Apply the controls in `04-controls-and-governance.md` (rulesets, signing, code-owner review) to
   the instance itself before inviting anyone. The instance is a build-plane asset: a change to a
   skill changes what every agent does.

Plugin versioning: users get a new copy only when the computed version changes, so either bump
`version` on each release or omit it and let commits drive updates. When both `plugin.json` and the
marketplace entry set `version`, Claude Code uses the `plugin.json` value, and `claude plugin
validate` warns when the two differ (verified, marketplace-reference and host-marketplace pages; the
official guidance is to set it in one place). This template keeps both and its CI job "Validate
plugin integrity" fails when they differ, so a mismatch can never be silently ignored: bump both in
the same pull request. A client that prefers the official one-place rule removes `version` from the
marketplace entry and the version-drift step from `validate.yml` and `mise run validate` together.

## 2. Distribute the marketplace to developers

Per developer (verified syntax; in a shell or inside a session):

```text
/plugin marketplace add <org>/<repo>
/plugin install grv-sdlc@<marketplace-name>
```

The shell equivalents are `claude plugin marketplace add <org>/<repo>` and
`claude plugin install grv-sdlc@<marketplace-name>`. Confirm with `claude plugin list`.

Private repository access: Claude Code has no git token of its own; it runs `git` on the user's
machine with prompts disabled and relies on stored credentials. For GitHub `owner/repo` it tries
SSH first and falls back to HTTPS; users without a GitHub SSH key can set
`CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`. For HTTPS the credential must already be stored, for example
by `gh auth login` followed by `gh auth setup-git`. Background auto-update uses the same
credentials and fails quietly, keeping the old checkout, if they are missing.

Auto-update is off by default for a marketplace. Either each user enables it under Marketplaces in
`/plugin`, or the administrator sets `"autoUpdate": true` in the managed entry (section 3).
Without it, users run `/plugin marketplace update <name>`.

Developers without git-host accounts can be served by a seed directory (`CLAUDE_CODE_PLUGIN_SEED_DIR`)
built at image time; see the org plugin page. Not needed for a normal pilot.

## 3. Org-level managed settings

Managed settings are the enforcement point outside the agent's and the developer's write access.
Delivery options (verified): server-managed settings from the claude.ai admin console (Owner role
required), MDM policy, or a `managed-settings.json` file at a system path:

| OS            | Path                                                            |
| ------------- | --------------------------------------------------------------- |
| macOS         | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux and WSL | `/etc/claude-code/managed-settings.json`                        |
| Windows       | `C:\Program Files\ClaudeCode\managed-settings.json`             |

An optional `managed-settings.d/` directory beside the file merges alphabetically. By default only
one managed source applies on a machine (server, then MDM, then file); `managedSourcesBehavior` set
to `"merge"` applies all. Managed settings outrank user, project, local and command-line settings.

A starting policy, using keys verified on the org and settings pages:

```json
{
  "extraKnownMarketplaces": {
    "<marketplace-name>": {
      "source": { "source": "github", "repo": "<org>/<repo>" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": { "grv-sdlc@<marketplace-name>": true },
  "strictKnownMarketplaces": [{ "source": "github", "repo": "<org>/<repo>" }, { "source": "skills-dir" }],
  "disableSideloadFlags": true,
  "allowManagedPermissionRulesOnly": true,
  "permissions": { "disableBypassPermissionsMode": "disable" }
}
```

What each does: register and force-enable the plugin; allow only the instance (the `skills-dir`
entry keeps users' own skills-directory plugins loading); reject the sideloading flags
(`--plugin-dir`, `--plugin-url`, `--agents`, `--mcp-config`); make managed settings the only source
of permission rules; refuse bypass mode. Plan the
managed `permissions.allow` and `permissions.deny` lists deliberately, because with
`allowManagedPermissionRulesOnly` nothing a developer adds locally counts. Also consider
`allowManagedHooksOnly` and `allowManagedMcpServersOnly` (both verified as managed-scope keys).
Test the policy on one machine first: a malformed managed file stops Claude Code starting.

Confirm a policy is in force with `/status` (look for the managed entry in `Setting sources`) and
`claude doctor`. A repository's own `.claude/settings.json` can also register marketplaces, but
only after the developer trusts the folder, so it is not an enforcement point.

Read-deny rules for secret files (`Read(./.env)`, `Read(./.env.*)`) are a documented pattern
(settings and permissions pages). Verified scope: they apply to Claude's built-in file tools, to
file commands Claude Code recognizes in Bash (`cat`, `head`, `tail`, `sed`, `tee`) and to the
targets of Bash redirections; for Grep and Glob the docs say best-effort. They do not apply to a
command that reads a file without naming it (`grep -r pattern .` from the directory that holds it)
or to a script that opens the file itself, and a Bash deny rule matches only the command text Claude
writes. The documented route to OS-level enforcement is the sandbox (sandbox filesystem key names:
UNVERIFIED - confirm against current docs). See `04`, section 6.

## 4. Atlassian connector (Jira)

The skills use a Jira connector through MCP. Verified Claude Code mechanics: add a remote HTTP
server with `claude mcp add --transport http <name> <url>`, use `--scope project` to write a shared
`.mcp.json` (project-scoped servers need interactive approval), and authenticate OAuth servers by
running `/mcp` or `claude mcp login <name>`. Get the current Atlassian endpoint and the supported
scopes from Atlassian's own documentation; they are not reproduced here. UNVERIFIED - confirm
against current docs: whether the client's Atlassian site needs an administrator to allow the
connector, and which Jira permissions the OAuth grant carries.

Use a dedicated service account for the agent where the client's identity policy allows, so agent
writes are attributable (see the provenance and identity rules in `04`). Restrict what the
connector may do with the managed MCP allowlist (`allowedMcpServers`, with `allowManagedMcpServersOnly`).
Exact file format for `managed-mcp.json`: UNVERIFIED - confirm against `.../managed-mcp.md`.

## 5. gsd-core global install

The skills drive the gsd-core engine from a global install; it is intentionally not vendored into
repositories. Install it per machine with `npx @opengsd/gsd-core@latest --claude --global`, which
installs to `~/.claude/gsd-core/` (repository `github.com/open-gsd/gsd-core`). Verified on 1.19.0 by
the consultancy's reference process; re-check on newer versions. Record the engine version in `.grv/sdlc.json` (`engine.gsdCoreMinVersion`) and re-test
the skills' assumptions about the engine whenever it updates. Every developer machine needs it
before the lifecycle skills work; add it to the onboarding script.

## 6. Per-repository `.grv/sdlc.json`

Copy `templates/project/.grv/sdlc.json` into each consuming repository and fill every required key
(`plugins/grv-sdlc/references/config-contract.md`). Points that matter in practice:

1. Transition values are Jira transition ids, not display names; look them up once per workflow.
2. `owners.productOwner` and `owners.leadEngineer` are named individuals, because decisions must
   name a person, never a team.
3. `environments[].dataClass` and `promotion` must be honest; they drive how skills describe risk.
4. `repo.requiredChecks` must match the real required checks in the ruleset, or skills will report
   readiness against the wrong list.
5. A skill that finds a required key missing stops and names it. That is intended; fix the file.

Technology-specific rules (framework traps, database rules) go in that repository's `AGENTS.md`,
not in a skill.

## 7. Smoke test before declaring Foundation done

On a clean machine with a normal developer account: add the marketplace, install the plugin, open
the sandbox repo, run one skill that only reads, then confirm `/status` shows the managed source
and `claude plugin list` shows the plugin enabled. Attempt `--plugin-dir` and an unlisted
marketplace and confirm both are refused.
