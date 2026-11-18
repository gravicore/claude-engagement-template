# Local validation cheat-sheet

For the canonical workflow, see `docs/contributing/SKILL-TESTING.md` and the CI
config in `.github/workflows/validate.yml`. This file is a quick-reference for
human contributors running checks locally.

## One-time setup

This repo uses [mise](https://mise.jdx.dev) as the universal dev tool manager.
One command works on macOS, Linux, and Windows:

```sh
mise run setup
```

Installs `yamllint` and `markdownlint-cli` in isolation (no global pip/npm
needed) and activates the git pre-commit hook.

If `mise` itself is not installed:

| Platform      | Install mise                  |
| ------------- | ----------------------------- |
| macOS / Linux | `curl https://mise.run \| sh` |
| Windows       | `winget install jdx.mise`     |

## Ad-hoc checks

```sh
mise run lint                        # all linters against the working tree
mise run validate                    # CI-blockable checks locally

# Validate JSON before pushing
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo "OK"
find plugins -name "plugin.json" -exec python3 -m json.tool {} \; > /dev/null

# Check for malformed stubs (allowed-tools: [] but missing "not yet implemented")
grep -r "allowed-tools: \[\]" plugins --include="SKILL.md" -l \
  | xargs grep -L "not yet implemented"

# Check SKILL.md line counts (full skills should stay under 120)
find plugins -name "SKILL.md" | xargs wc -l | sort -rn | head -20
```

## CI checks

Ten jobs across three workflows. **Eight are required status checks** and run on every pull request to `main`: they are
the eight jobs of `validate.yml`, which has no path filter on `pull_request`. Two more jobs are path-filtered and are
**not required**, because a required check that never runs leaves the PR pending forever:

- `validate-frontmatter` runs only when a skill, agent or command file changes.
- `scan-plugins` runs only when `.claude-plugin/marketplace.json` or `.github/policy/` changes.

Pushes that touch only `.planning/**` or `docs/**` skip `validate.yml` (the push trigger has `paths-ignore`); pull
requests always run all eight regardless of which files they touch.

`.github/branch-protection.json` lists exactly the eight required job names. Applying it is a human repo-admin act, never
an agent's; the file is a reference copy.

| Check                         | Job name in CI              | Required | What it catches                                                                                                                                                                                                                  |
| ----------------------------- | --------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Validate plugin integrity     | `validate-plugin-integrity` | yes      | Schema validation, version drift between `plugin.json` and the marketplace entry, client name isolation, stub format, skill length warning (non-blocking), plugin/skill naming (`grv-` prefix, dirname match, global uniqueness) |
| Scan secrets                  | `scan-secrets`              | yes      | Hardcoded credentials via gitleaks (full git history, `fetch-depth: 0`)                                                                                                                                                          |
| Check CODEOWNERS entries      | `check-codeowners`          | yes      | New `plugins/<slug>/` directory with no CODEOWNERS entry                                                                                                                                                                         |
| Lint YAML workflows           | `yamllint-workflows`        | yes      | yamllint strict mode on `.github/workflows/`                                                                                                                                                                                     |
| Lint SKILL.md files           | `markdownlint-skills`       | yes      | markdownlint on all `SKILL.md` files                                                                                                                                                                                             |
| Format check                  | `format-check`              | yes      | Prettier `--check` on `**/*.{md,json,yml,yaml}` (respects `.prettierignore`) and `shfmt -i 2 -ci -d` on `*.sh`                                                                                                                   |
| Lint shell scripts            | `lint-shell-scripts`        | yes      | shellcheck on all `*.sh`                                                                                                                                                                                                         |
| Validate plugins (claude CLI) | `validate-plugin-cli`       | yes      | Official `claude plugin validate` - schema correctness against Anthropic marketplace schema (skipped inside the job while the repo is still a template)                                                                          |
| Validate frontmatter          | `validate-frontmatter`      | no       | SKILL.md requires `name` (equal to its directory name), `description` and `allowed-tools`; agent files require `name` and `description`; command files require `description`                                                     |
| Scan plugins for security     | `scan-plugins`              | no       | AI-driven security policy review via Claude - only runs on `marketplace.json` or policy changes                                                                                                                                  |

## Claude Code hooks

`.claude/settings.json` wires hooks that run inside Claude Code only. They read the hook input as JSON on stdin
(`tool_input.file_path`, plus `content` for Write and `new_string` for Edit) through `.claude/hooks/_hook-input.sh`, which
uses `jq` and falls back to `python3`. Timeouts are in seconds.

| Script                  | Event and matcher          | Exit codes                                                            |
| ----------------------- | -------------------------- | --------------------------------------------------------------------- |
| `block-client-names.sh` | PreToolUse, `Edit\|Write`  | 0 allow, 2 block (reason on stderr), 1 non-blocking error (bad input) |
| `post-edit.sh`          | PostToolUse, `Edit\|Write` | 0 clean, 2 a step reported a problem (stderr shown to Claude)         |

`post-edit.sh` runs these in order, because Claude Code runs hooks of one event in parallel and these touch the same
file: `format-file.sh` (Prettier at the pinned version), `lint-yaml.sh` (yamllint on `.github/workflows/`),
`check-stub-format.sh`, `check-skill-suffix.sh`, `regen-template-index.py`. A PostToolUse hook cannot block (the write
already happened); exit 2 only feeds the message back to Claude.

What the hooks are and are not:

- They are a local convenience. **CI is the enforcement point**: the client-name check in "Validate plugin integrity"
  fails the pull request even when every hook was bypassed.
- The client-name guard refuses only Claude Code `Edit` and `Write` calls. A Bash redirect, `NotebookEdit`, another
  editor, or a contributor not using Claude Code is not covered. It mirrors the CI scope (`.md .json .yml .yaml .sh`
  files, outside `references/` and dot-directories). A hook that times out or crashes does not block unless the hook
  sets `onFailure: "block"` (Claude Code 2.1.295 or later; UNVERIFIED on older versions).
- Skill-name suffixes are checked only by `check-skill-suffix.sh`, as feedback; CI does not check them.

## Secret files and permission rules

`.claude/settings.json` denies `Read(.env)` and `Read(.env.*)` (bare filenames match at any depth) plus Bash patterns that
end in `.env` or `.env.*`. Limits, from the permissions documentation (checked 2026-11-18):

- Read deny rules apply to Claude's built-in file tools (best-effort for Grep and Glob) and to file commands Claude Code
  recognizes in Bash such as `cat`, `head`, `tail` and `sed`, and to redirection targets.
- They do not apply to a command that reads a file without naming it (`grep -r pattern .` from the directory that holds
  it) or to a script or interpreter that opens the file itself.
- A Bash deny rule matches the command text Claude writes, not the program: `sh -c '...'`, a full path, or a variable
  expansion can sidestep it. Argument patterns are documented as fragile.
- The documented route to OS-level enforcement is the sandbox, which this repo does not configure. The control that still
  holds when these fail is the one in `docs/enablement/04-controls-and-governance.md` section 6: agents run with no
  production credentials in their environment at all.

## Template state

Before `scripts/init-engagement.sh` has run, the marketplace registry carries unresolved placeholder tokens.
`scripts/template-state.sh` detects that state (exit 0 means template). While it holds:

- `claude plugin validate` and the `scan-plugins` job skip, since the marketplace name is not yet a valid identifier
  and the scan needs the engagement's API secret.
- The client name isolation check (CI and `mise run validate`) skips.
- Every other check runs normally, so a template-repo PR is still schema-, format-, lint-, and secret-checked.
