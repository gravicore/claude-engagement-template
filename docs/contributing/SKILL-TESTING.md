# Skill Testing Guide

Before pushing a PR, run two local tasks that mirror most CI-blockable checks.

## Two-Task Model

| Task                | Checks                                                                           | Maps to CI Failures                                         |
| ------------------- | -------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| `mise run lint`     | YAML syntax, Markdown style, shell script linting                                | yamllint-workflows, markdownlint-skills, lint-shell-scripts |
| `mise run validate` | Schema validation, version drift, client names, stub format, tests.yaml presence | validate-plugin-integrity                                   |
| `mise run test`     | Skill behavioral quality (LLM calls - pre-CI only, never in CI)                  | None - local quality gate only                              |

## `mise run lint`

```bash
mise run lint
```

Runs yamllint on `.github/workflows/`, markdownlint on all `SKILL.md` files, and shellcheck on all `.sh` files.

## `mise run validate`

```bash
mise run validate
```

Checks schema validation, version drift, client name isolation, stub format, and `tests.yaml` presence.

## `mise run test`

```bash
mise run test
```

Runs skill behavioral quality tests via promptfoo. Makes LLM API calls - **never runs in CI**.
Requires `ANTHROPIC_API_KEY` in your environment.

**Test fixture format** (`plugins/<plugin>/skills/<skill>/tests.yaml`):

```yaml
prompts:
  - label: skill-chat
    raw: '[{"role":"system","content":{{ skill | dump }}},{"role":"user","content":{{ user_input | dump }}}]'

defaultTest:
  vars:
    skill: file://SKILL.md

providers:
  - id: anthropic:messages:claude-haiku-4-5-20251001
    config:
      temperature: 0.0
      max_tokens: 512

tests:
  - description: What this test checks
    vars:
      user_input: "a representative question or input for the skill"
    assert:
      - type: contains
        value: "expected phrase in output"
      - type: not-contains
        value: "not yet implemented"
```

Why this shape: the skill is the instruction set, so it goes to the model as the **system** message, and the test's
`user_input` is the **user** turn. The `raw` prompt builds exactly that two-message chat. (The older fixture listed
`file://.../SKILL.md` as the prompt itself, which made the skill the user's message and left `user_input` unused, so the
test measured nothing about how the skill behaves when invoked.) `{{ skill | dump }}` and `{{ user_input | dump }}`
JSON-encode the text so quotes and newlines in the skill cannot break the message array. `defaultTest.vars.skill` loads
the file once for every test; `file://SKILL.md` is relative to the `tests.yaml` file, not to the directory you run the
command from, so the same line works in every skill directory (checked with promptfoo's `echo` provider from an
unrelated working directory).

Write 3-5 test cases per full skill. Use `temperature: 0.0` for determinism. A test that cannot fail is worthless: assert
on a phrase the skill's rules force, and add a `not-contains` for the failure you are guarding against.

To run one skill's tests: `npx promptfoo eval --config plugins/<plugin>/skills/<skill>/tests.yaml`. `mise run test` runs
every `tests.yaml` the same way, one `--config` per file.

## Plugin Installation Testing

Verify the plugin installs and displays correctly in Claude Desktop.

```text
/plugin marketplace add {{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}#<branch-name>
/plugin install <plugin-name>@{{MARKETPLACE_NAME}}
```

After merge to main:

```text
/plugin marketplace add {{GITHUB_ORG}}/{{ENGAGEMENT_SLUG}}
/plugin install <plugin-name>@{{MARKETPLACE_NAME}}
```

## Full Pre-PR Checklist

```bash
mise run format        # auto-format all files first
mise run lint          # style checks
mise run validate      # structural checks (includes tests.yaml presence check)
mise run test          # skill quality tests - requires ANTHROPIC_API_KEY (pre-CI only)
git diff --exit-code   # verify no formatting diffs remain
```
