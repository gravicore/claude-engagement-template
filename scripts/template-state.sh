#!/usr/bin/env bash
# template-state.sh - report whether this repo is still the uninitialized engagement template.
#
# Exit 0: the marketplace registry still carries unresolved placeholder tokens (template state).
# Exit 1: no placeholders remain (an initialized engagement instance).
# CI uses this to skip checks that cannot pass before scripts/init-engagement.sh has run.
# The pattern is written as bracket expressions so this file never contains a literal token.

set -euo pipefail

REGISTRY="${1:-.claude-plugin/marketplace.json}"
PATTERN='[{][{](ENGAGEMENT_NAME|ENGAGEMENT_SLUG|GITHUB_ORG|MARKETPLACE_NAME|COMPLIANCE_REGIMES)[}][}]'

if [[ -f "$REGISTRY" ]] && grep -Eq "$PATTERN" "$REGISTRY"; then
  echo "template"
  exit 0
fi

echo "instance"
exit 1
