#!/usr/bin/env python3
"""check-naming.py - enforce the plugin and skill naming taxonomy.

The single implementation of the naming rule, run by CI (validate.yml), the pre-commit hook and
`mise run validate`, so all three apply the same rule. Run from the repo root.

Rule, read from .engagement.json (schema: schemas/engagement.json):
  - A plugin directory is valid when it is listed in genericPlugins, or starts with "<prefix>-".
  - plugin.json `name` equals its directory; a marketplace entry `name` equals its source directory.
  - Skills inside a generic plugin carry no prefix requirement. Skills inside a prefixed plugin
    start with "<prefix>-".
  - Skill names are unique across all plugins.
  - Every plugin directory has a marketplace.json entry, and every entry points at its directory.

Template state: while the prefix is still the init placeholder, the prefix checks are skipped with
an explicit OK line; generic-plugin, name-equality and uniqueness checks still run.

Exit 0 when every check passes, 1 otherwise.
"""
import json
import os
import re
import sys

CONFIG = '.engagement.json'
MARKETPLACE = '.claude-plugin/marketplace.json'
# Written as bracket expressions so init never rewrites this file.
PLACEHOLDER = re.compile(r'^[{][{]PREFIX[}][}]$')
PREFIX_RE = re.compile(r'^[a-z][a-z0-9]{1,7}$')
KEBAB_RE = re.compile(r'^[a-z][a-z0-9-]*$')


def listdirs(path):
    if not os.path.isdir(path):
        return []
    return sorted(d for d in os.listdir(path) if os.path.isdir(os.path.join(path, d)) and not d.startswith('.'))


def main():
    errors = []

    if not os.path.exists(CONFIG):
        print(f'ERROR: {CONFIG} is missing; it declares the engagement prefix and the generic plugins.')
        return 1
    try:
        with open(CONFIG) as f:
            config = json.load(f)
    except json.JSONDecodeError as e:
        print(f'ERROR: {CONFIG} is not valid JSON: {e}')
        return 1

    prefix = config.get('prefix', '')
    generic = config.get('genericPlugins', [])
    if not isinstance(prefix, str) or not isinstance(generic, list) or not all(isinstance(g, str) for g in generic):
        print(f'ERROR: {CONFIG} needs a string "prefix" and a list of strings "genericPlugins".')
        return 1
    for g in generic:
        if not KEBAB_RE.match(g):
            errors.append(f'CONFIG: generic plugin "{g}" in {CONFIG} is not lowercase kebab-case')

    template = bool(PLACEHOLDER.match(prefix))
    if template:
        print(f'OK: template state - prefix checks skipped until init has run ({CONFIG} prefix is the placeholder)')
    elif not PREFIX_RE.match(prefix):
        errors.append(f'CONFIG: prefix "{prefix}" in {CONFIG} must match ^[a-z][a-z0-9]{{1,7}}$')
        template = True  # the prefix is unusable; do not report every name against it
    elif prefix in generic:
        errors.append(f'CONFIG: prefix "{prefix}" must not also be a generic plugin name')

    def plugin_kind(name):
        if name in generic:
            return 'generic'
        if not template and name.startswith(f'{prefix}-') and len(name) > len(prefix) + 1:
            return 'prefixed'
        return 'template' if template else 'invalid'

    # Plugin directories and their manifests.
    skills = {}
    for plugin in listdirs('plugins'):
        kind = plugin_kind(plugin)
        if kind == 'invalid':
            errors.append(
                f'PLUGIN DIR: plugins/{plugin} - must be a generic plugin ({", ".join(generic) or "none listed"}) '
                f'or start with "{prefix}-"'
            )
        elif kind == 'template':
            print(f'OK: plugins/{plugin} - prefix check skipped (template state)')

        manifest = f'plugins/{plugin}/.claude-plugin/plugin.json'
        if os.path.exists(manifest):
            try:
                with open(manifest) as f:
                    name = json.load(f).get('name', '')
            except json.JSONDecodeError:
                name = None  # the schema step reports invalid JSON
            if name is not None and name != plugin:
                errors.append(f'PLUGIN NAME: {manifest} name "{name}" != directory "{plugin}"')

        for skill in listdirs(f'plugins/{plugin}/skills'):
            skills.setdefault(skill, []).append(plugin)
            if kind == 'prefixed' and not skill.startswith(f'{prefix}-'):
                errors.append(
                    f'SKILL PREFIX: plugins/{plugin}/skills/{skill} - skills in prefixed plugin "{plugin}" '
                    f'must start with "{prefix}-"'
                )

    # Marketplace entries name their source directory.
    if os.path.exists(MARKETPLACE):
        with open(MARKETPLACE) as f:
            marketplace = json.load(f)
        for entry in marketplace.get('plugins', []):
            src = entry.get('source')
            path = src.lstrip('./') if isinstance(src, str) else (src or {}).get('path', '')
            dirname = os.path.basename(path.rstrip('/'))
            if not dirname:
                errors.append(f'MARKETPLACE: entry "{entry.get("name")}" has no source path')
            elif entry.get('name', '') != dirname:
                errors.append(f'MARKETPLACE: entry "{entry.get("name")}" != source directory "{dirname}"')
            elif not os.path.isdir(path):
                errors.append(f'MARKETPLACE: entry "{dirname}" points at missing directory {path}')

        listed = {e.get('name') for e in marketplace.get('plugins', [])}
        for plugin in listdirs('plugins'):
            if plugin not in listed:
                errors.append(f'MARKETPLACE: plugins/{plugin} has no entry in {MARKETPLACE}, so it cannot be installed')

    # Global skill name uniqueness.
    for skill, plugins in sorted(skills.items()):
        if len(plugins) > 1:
            errors.append(f'DUPLICATE SKILL: "{skill}" exists in plugins: {", ".join(plugins)}')

    if errors:
        for e in errors:
            print(f'ERROR: {e}')
        print('See .claude/docs/naming-convention.md for the naming rule.')
        return 1
    print(f'OK: naming checks passed ({len(listdirs("plugins"))} plugin(s), {len(skills)} unique skill name(s))')
    return 0


if __name__ == '__main__':
    sys.exit(main())
