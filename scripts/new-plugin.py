#!/usr/bin/env python3
"""Scaffold a new engagement plugin in this marketplace.

Creates, for a plugin named <prefix>-<name>:
  plugins/<plugin>/.claude-plugin/plugin.json   manifest, version 0.1.0
  plugins/<plugin>/references/OWNERS.md         owner team and where requests go
  .claude/rules/<plugin>.md                     path-scoped authoring rules for this plugin
and adds the plugin's own line to CODEOWNERS and its entry to .claude-plugin/marketplace.json.

It creates no skill: add the first one under plugins/<plugin>/skills/ (docs/contributing/SKILL-AUTHORING.md).
Generic plugins come from the template, so this script only creates prefixed plugins.
Standard library only. Changes nothing when a check fails or with --dry-run.
"""
import argparse
import json
import os
import re
import sys

CONFIG = '.engagement.json'
MARKETPLACE = '.claude-plugin/marketplace.json'
CODEOWNERS = 'CODEOWNERS'
PREFIX_RE = re.compile(r'^[a-z][a-z0-9]{1,7}$')
KEBAB_RE = re.compile(r'^[a-z][a-z0-9-]*[a-z0-9]$')
OWNER_RE = re.compile(r'^@[A-Za-z0-9][A-Za-z0-9-]*(/[A-Za-z0-9][A-Za-z0-9._-]*)?$')
LICENSES = ('UNLICENSED', 'Apache-2.0')


def die(message):
    print(f'ERROR: {message}', file=sys.stderr)
    sys.exit(1)


def one_line(value, what):
    if not value.strip() or '\n' in value or '\r' in value:
        die(f'{what} must be a single non-empty line')
    return value.strip()


def main():
    parser = argparse.ArgumentParser(description='Scaffold a new engagement plugin.')
    parser.add_argument('--name', required=True, help='plugin name, starting with the engagement prefix, e.g. acme-servicing')
    parser.add_argument('--owner', required=True, action='append', help='owning GitHub team or user, e.g. @org/team (repeatable)')
    parser.add_argument('--description', required=True, help='one sentence: what the plugin is for')
    parser.add_argument('--audience', default='not set yet', help='who uses the plugin')
    parser.add_argument('--channel', default='not set yet', help='chat channel for the plugin')
    parser.add_argument('--license', default='UNLICENSED', choices=LICENSES)
    parser.add_argument('--dry-run', action='store_true', help='report what would change; modify nothing')
    args = parser.parse_args()

    os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

    for required in (CONFIG, MARKETPLACE, CODEOWNERS):
        if not os.path.exists(required):
            die(f'{required} is missing; run this from an initialized engagement repo')
    with open(CONFIG) as f:
        config = json.load(f)
    prefix = config.get('prefix', '')
    generic = config.get('genericPlugins', [])
    if not PREFIX_RE.match(prefix):
        die(f'{CONFIG} has no usable prefix yet; run scripts/init-engagement.sh first')

    name = args.name
    if not KEBAB_RE.match(name) or '--' in name:
        die(f'--name "{name}" must be lowercase kebab-case')
    if name in generic:
        die(f'"{name}" is a generic plugin; generic plugins come from the template')
    if not name.startswith(f'{prefix}-') or len(name) <= len(prefix) + 1:
        die(f'--name "{name}" must start with the engagement prefix: {prefix}-<name>')
    for owner in args.owner:
        if not OWNER_RE.match(owner):
            die(f'--owner "{owner}" must be a GitHub handle such as @org/team or @user')
    owners = list(dict.fromkeys(args.owner))
    description = one_line(args.description, '--description')
    audience = one_line(args.audience, '--audience')
    channel = one_line(args.channel, '--channel')

    plugin_dir = f'plugins/{name}'
    rules_path = f'.claude/rules/{name}.md'
    if os.path.exists(plugin_dir):
        die(f'{plugin_dir} already exists')
    if os.path.exists(rules_path):
        die(f'{rules_path} already exists')

    with open(MARKETPLACE) as f:
        marketplace = json.load(f)
    if any(entry.get('name') == name for entry in marketplace.get('plugins', [])):
        die(f'{MARKETPLACE} already lists "{name}"')
    with open(CODEOWNERS) as f:
        codeowners = f.read()
    if re.search(rf'^/?plugins/{re.escape(name)}/?\s', codeowners, re.MULTILINE):
        die(f'{CODEOWNERS} already has a line for plugins/{name}/')

    author = (marketplace.get('owner') or {}).get('name') or prefix
    manifest = {
        'name': name,
        'description': description,
        'version': '0.1.0',
        'author': {'name': author},
        'license': args.license,
    }
    owners_md = (
        f'# {name} Ownership\n'
        '\n'
        f'**Owner team:** {" ".join(owners)}\n'
        f'**Audience:** {audience}\n'
        f'**Chat channel:** {channel}\n'
        f'**Skill requests:** open a GitHub issue in this repo with the label `plugin:{name}` and the title prefix `[skill-request]`\n'
        f'**Bug reports:** open a GitHub issue in this repo with the label `plugin:{name}`\n'
        '\n'
        '## What the owner decides\n'
        '\n'
        f'- Reviews every pull request that touches `plugins/{name}/` (CODEOWNERS routes it).\n'
        '- Approves instruction changes proposed for this plugin, including lessons promoted by `sdlc:learn promote`.\n'
        '- Decides which requested skills are built, and in what order.\n'
    )
    rules_md = (
        '---\n'
        'paths:\n'
        f'  - "plugins/{name}/**"\n'
        '---\n'
        '\n'
        f'# Authoring rules for the {name} plugin\n'
        '\n'
        f'- Skill directories in this plugin start with `{prefix}-`, and each name is unique across every plugin in this repo.\n'
        f'- Files in `plugins/{name}/references/` are read only by this plugin\'s skills. Content that another plugin also\n'
        '  needs moves to the shared plugin (`docs/PLUGIN-TAXONOMY.md`).\n'
        '- A skill whose output feeds a skill in another plugin ends with a "next step" line naming that skill. It does not\n'
        '  call it.\n'
    )
    owners_line = f'/plugins/{name}/'.ljust(18) + ' ' + ' '.join(owners) + '\n'
    entry = {'name': name, 'description': description, 'source': f'./plugins/{name}', 'version': '0.1.0'}

    plan = [
        f'create {plugin_dir}/.claude-plugin/plugin.json',
        f'create {plugin_dir}/references/OWNERS.md',
        f'create {rules_path}',
        f'append to {CODEOWNERS}: {owners_line.strip()}',
        f'append to {MARKETPLACE}: {name} 0.1.0',
    ]
    if args.dry_run:
        for step in plan:
            print(f'  would {step}')
        print('Dry run complete. Nothing changed.')
        return 0

    os.makedirs(f'{plugin_dir}/.claude-plugin')
    os.makedirs(f'{plugin_dir}/references')
    os.makedirs(os.path.dirname(rules_path), exist_ok=True)
    with open(f'{plugin_dir}/.claude-plugin/plugin.json', 'w') as f:
        json.dump(manifest, f, indent=2)
        f.write('\n')
    with open(f'{plugin_dir}/references/OWNERS.md', 'w') as f:
        f.write(owners_md)
    with open(rules_path, 'w') as f:
        f.write(rules_md)
    with open(CODEOWNERS, 'w') as f:
        f.write(codeowners if codeowners.endswith('\n') else codeowners + '\n')
        f.write(owners_line)
    marketplace.setdefault('plugins', []).append(entry)
    with open(MARKETPLACE, 'w') as f:
        json.dump(marketplace, f, indent=2)
        f.write('\n')

    for step in plan:
        print(f'  {step}')
    print(f'Done. Next: add the first skill under {plugin_dir}/skills/ (docs/contributing/SKILL-AUTHORING.md),')
    print(f'add a row for {name} to docs/PLUGIN-TAXONOMY.md, then run: python3 scripts/check-naming.py && python3 scripts/check-plugin-owners.py')
    return 0


if __name__ == '__main__':
    sys.exit(main())
