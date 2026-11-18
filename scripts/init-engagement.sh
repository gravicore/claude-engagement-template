#!/usr/bin/env bash
# init-engagement.sh - turn a fresh copy of the engagement template into one client's instance.
#
# Replaces the six placeholder tokens in every text file, removes the template-only blocks
# (between the template:begin and template:end HTML comment markers), and reports each change.
# Never touches .git. Refuses to run when no placeholder remains, so it cannot be applied twice.
# Portable across macOS/BSD and GNU userland (uses sed -i.bak, awk, find, grep only).
#
# The token strings are assembled at run time so this file never contains a literal token and is
# never rewritten by itself.

set -euo pipefail

OPEN='{'
OPEN="${OPEN}${OPEN}"
CLOSE='}'
CLOSE="${CLOSE}${CLOSE}"
BEGIN_MARK='<!-- template:begin -->'
END_MARK='<!-- template:end -->'
SELF='./scripts/init-engagement.sh'

tok() { printf '%s%s%s' "$OPEN" "$1" "$CLOSE"; }

usage() {
  cat <<'USAGE'
Usage: scripts/init-engagement.sh --name NAME --slug SLUG --org ORG --prefix CODE --regimes LIST [options]

Required:
  --name NAME          Human engagement name (replaces the ENGAGEMENT_NAME token)
  --slug SLUG          Kebab-case slug, e.g. acme-lending (ENGAGEMENT_SLUG)
  --org ORG            GitHub org that hosts the instance (GITHUB_ORG)
  --prefix CODE        Engagement prefix for engagement-authored plugins and skills, 2-8 chars,
                       lowercase letters and digits, starting with a letter, e.g. acme (PREFIX)
  --regimes LIST       Compliance regimes in scope, free text (COMPLIANCE_REGIMES)

Optional:
  --marketplace ID     Marketplace id (MARKETPLACE_NAME); default: the prefix
  --dry-run            Report what would change; modify nothing
  -h, --help           Show this help

Run once, from a fresh copy of the template, then review the diff before committing.
USAGE
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

NAME=""
SLUG=""
ORG=""
MARKETPLACE=""
PREFIX=""
REGIMES=""
DRY_RUN=0

need_value() {
  [[ $# -ge 2 ]] || die "option $1 requires a value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) need_value "$@" && NAME="$2" && shift 2 ;;
    --slug) need_value "$@" && SLUG="$2" && shift 2 ;;
    --org) need_value "$@" && ORG="$2" && shift 2 ;;
    --marketplace) need_value "$@" && MARKETPLACE="$2" && shift 2 ;;
    --prefix) need_value "$@" && PREFIX="$2" && shift 2 ;;
    --regimes) need_value "$@" && REGIMES="$2" && shift 2 ;;
    --name=*) NAME="${1#*=}" && shift ;;
    --slug=*) SLUG="${1#*=}" && shift ;;
    --org=*) ORG="${1#*=}" && shift ;;
    --marketplace=*) MARKETPLACE="${1#*=}" && shift ;;
    --prefix=*) PREFIX="${1#*=}" && shift ;;
    --regimes=*) REGIMES="${1#*=}" && shift ;;
    --dry-run) DRY_RUN=1 && shift ;;
    -h | --help) usage && exit 0 ;;
    *) usage >&2 && die "unknown argument: $1" ;;
  esac
done

[[ -n "$NAME" ]] || die "--name is required"
[[ -n "$SLUG" ]] || die "--slug is required"
[[ -n "$ORG" ]] || die "--org is required"
[[ -n "$PREFIX" ]] || die "--prefix is required (a short engagement code such as acme)"
[[ -n "$REGIMES" ]] || die "--regimes is required (use a short phrase such as 'none identified' if truly none)"
[[ "$PREFIX" =~ ^[a-z][a-z0-9]{1,7}$ ]] || die "--prefix must be 2-8 chars: lowercase letters and digits, starting with a letter"
[[ -n "$MARKETPLACE" ]] || MARKETPLACE="$PREFIX"

[[ "$SLUG" =~ ^[a-z][a-z0-9-]*$ ]] || die "--slug must be lowercase kebab-case (a-z, 0-9, hyphen), starting with a letter"
[[ "$MARKETPLACE" =~ ^[a-z][a-z0-9-]*$ ]] || die "--marketplace must be lowercase kebab-case, starting with a letter"
[[ "$ORG" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || die "--org must be a valid GitHub org name"

for v in "$NAME" "$REGIMES"; do
  case "$v" in
    *$'\n'* | *$'\r'*) die "values must be single-line" ;;
    *"$OPEN"*) die "values must not contain the placeholder opening sequence" ;;
  esac
done

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ -f .engagement.json ]] && grep -Eq "\"genericPlugins\".*\"${PREFIX}\"" .engagement.json; then
  die "--prefix '$PREFIX' is the name of a generic plugin; choose another code"
fi

TOKENS=(ENGAGEMENT_NAME ENGAGEMENT_SLUG GITHUB_ORG MARKETPLACE_NAME COMPLIANCE_REGIMES PREFIX)
VALUES=("$NAME" "$SLUG" "$ORG" "$MARKETPLACE" "$REGIMES" "$PREFIX")

# Escape a value for use in a sed replacement that uses | as its delimiter.
esc() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }

# Text files only: skip .git, node_modules, this script, binary and empty files.
FILES=()
while IFS= read -r -d '' f; do
  [[ "$f" == "$SELF" ]] && continue
  grep -qI '' "$f" 2>/dev/null || continue
  FILES+=("$f")
done < <(find . \( -path ./.git -o -path ./node_modules \) -prune -o -type f -print0)

count_tokens() {
  local f="$1" t c total=0
  for t in "${TOKENS[@]}"; do
    c=$(grep -oF "$(tok "$t")" "$f" | wc -l | tr -d ' ')
    total=$((total + c))
  done
  echo "$total"
}

# Preflight: any placeholder left to replace? Marker blocks balanced?
TOTAL=0
for f in "${FILES[@]}"; do
  TOTAL=$((TOTAL + $(count_tokens "$f")))
  b=$(grep -cxF "$BEGIN_MARK" "$f" || true)
  e=$(grep -cxF "$END_MARK" "$f" || true)
  [[ "$b" == "$e" ]] || die "unbalanced template markers in $f (begin=$b end=$e); fix before running"
done

if [[ "$TOTAL" -eq 0 ]]; then
  die "no placeholders remain; this repo looks already initialized. Nothing changed."
fi

echo "Engagement:  $NAME"
echo "Slug:        $SLUG"
echo "Org:         $ORG"
echo "Prefix:      $PREFIX"
echo "Marketplace: $MARKETPLACE"
echo "Regimes:     $REGIMES"
[[ "$DRY_RUN" -eq 1 ]] && echo "(dry run: no files will be modified)"
echo

SED_ARGS=()
i=0
for t in "${TOKENS[@]}"; do
  SED_ARGS+=(-e "s|$(tok "$t")|$(esc "${VALUES[$i]}")|g")
  i=$((i + 1))
done

STRIPPED=0
REPLACED=0
CHANGED_FILES=0
TMP="$(mktemp "${TMPDIR:-/tmp}/init-engagement.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

for f in "${FILES[@]}"; do
  n=$(count_tokens "$f")
  has_block=0
  grep -qxF "$BEGIN_MARK" "$f" && has_block=1
  [[ "$n" -gt 0 || "$has_block" -eq 1 ]] || continue

  note=""
  if [[ "$has_block" -eq 1 ]]; then
    note=", template-only block removed"
    STRIPPED=$((STRIPPED + 1))
    if [[ "$DRY_RUN" -eq 0 ]]; then
      awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; after = 1; next }
        skip { next }
        after && $0 == "" { after = 0; next }
        { after = 0; print }' "$f" >"$TMP"
      cat "$TMP" >"$f"
    fi
  fi
  if [[ "$DRY_RUN" -eq 0 && "$n" -gt 0 ]]; then
    sed -i.bak "${SED_ARGS[@]}" "$f" && rm -f "$f.bak"
  fi
  echo "  ${f#./}: $n replacement(s)$note"
  REPLACED=$((REPLACED + n))
  CHANGED_FILES=$((CHANGED_FILES + 1))
done

echo
echo "Files touched: $CHANGED_FILES, placeholder occurrences: $REPLACED, template-only blocks removed: $STRIPPED"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete. Re-run without --dry-run to apply."
  exit 0
fi

# Anything still looking like a token is unknown to this script; report it.
LEFT=0
for f in "${FILES[@]}"; do
  if grep -qE "[{][{][A-Z][A-Z_]*[}][}]" "$f"; then
    echo "WARNING: unresolved token left in ${f#./}" >&2
    LEFT=1
  fi
done
[[ "$LEFT" -eq 0 ]] || {
  echo "Completed with warnings: resolve the tokens above by hand." >&2
  exit 2
}

echo "Done. Review with 'git diff', then commit. .git was not touched."
