#!/usr/bin/env python3
"""Check that every plugin has a named owner (multi-plugin ownership).

For each directory under plugins/:
  - CODEOWNERS has a line whose pattern is that plugin directory itself. The catch-all and a plugins/*
    wildcard do not count: a plugin without its own line has no owner anyone chose.
  - plugins/<plugin>/references/OWNERS.md exists and fills in its required fields.
  - Every @handle on the OWNERS.md "Owner team" line is an owner on that plugin's CODEOWNERS line, so the
    two records cannot drift apart.

Standard library only. Exits 1 on any error.
"""
import os
import re
import sys

CODEOWNERS = 'CODEOWNERS'
REQUIRED_FIELDS = ('Owner team', 'Skill requests', 'Bug reports')
FIELD_RE = re.compile(r'^\*\*(?P<key>[^*:]+):\*\*\s*(?P<value>.*)$')
HANDLE_RE = re.compile(r'@[^\s,;]+')


def listdirs(path):
    if not os.path.isdir(path):
        return []
    return sorted(d for d in os.listdir(path) if os.path.isdir(os.path.join(path, d)) and not d.startswith('.'))


def normalize(pattern):
    """Reduce a CODEOWNERS pattern to a bare path, or None when it contains a wildcard."""
    p = pattern.lstrip('/')
    for suffix in ('/**', '/*', '/'):
        if p.endswith(suffix):
            p = p[: -len(suffix)]
            break
    return None if '*' in p else p


def read_codeowners():
    owners = {}
    with open(CODEOWNERS) as f:
        for raw in f:
            line = raw.split('#', 1)[0].strip()
            if not line:
                continue
            parts = line.split()
            path = normalize(parts[0])
            if path is not None:
                owners[path] = parts[1:]
    return owners


def read_fields(path):
    fields = {}
    with open(path) as f:
        for raw in f:
            m = FIELD_RE.match(raw.strip())
            if m:
                fields[m.group('key').strip()] = m.group('value').strip()
    return fields


def main():
    if not os.path.exists(CODEOWNERS):
        print(f'ERROR: {CODEOWNERS} file missing')
        return 1

    plugins = listdirs('plugins')
    if not plugins:
        print('OK: no plugin directories found - nothing to verify')
        return 0

    owners = read_codeowners()
    errors = []
    for plugin in plugins:
        line_owners = owners.get(f'plugins/{plugin}')
        if line_owners is None:
            errors.append(
                f'CODEOWNERS: no line for /plugins/{plugin}/ - every plugin needs its own line; '
                f'the catch-all and plugins/* do not count'
            )
        elif not line_owners:
            errors.append(f'CODEOWNERS: the /plugins/{plugin}/ line names no owner')

        owners_md = f'plugins/{plugin}/references/OWNERS.md'
        if not os.path.exists(owners_md):
            errors.append(f'MISSING: {owners_md}')
            continue
        fields = read_fields(owners_md)
        for key in REQUIRED_FIELDS:
            if not fields.get(key):
                errors.append(f'OWNERS: {owners_md} has no value for "**{key}:**"')
        handles = HANDLE_RE.findall(fields.get('Owner team', ''))
        if fields.get('Owner team') and not handles:
            errors.append(f'OWNERS: {owners_md} "Owner team" names no @handle')
        for handle in handles:
            if line_owners is not None and handle not in line_owners:
                errors.append(
                    f'OWNER DRIFT: {owners_md} names {handle}, which is not on the /plugins/{plugin}/ line in {CODEOWNERS}'
                )

    if errors:
        for e in errors:
            print(f'ERROR: {e}')
        print('See docs/PLUGIN-TAXONOMY.md ("Ownership"). scripts/new-plugin.py creates both records for a new plugin.')
        return 1
    print(f'OK: {len(plugins)} plugin(s) each have their own CODEOWNERS line and a complete OWNERS.md')
    return 0


if __name__ == '__main__':
    sys.exit(main())
