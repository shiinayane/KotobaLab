#!/usr/bin/env bash
#
# release_dictionary.sh
# KotobaLab
#
# Build, verify, and publish dictionary.sqlite as a GitHub Release artifact.
#
# This is the Tier-1 release automation: a single command that runs the
# Python builder, runs verify_database.py, computes a SHA-256, and creates
# a tagged GitHub Release with the artifact and checksum attached.
#
# Usage:
#   Tools/scripts/release_dictionary.sh <tag>
#
# Example:
#   Tools/scripts/release_dictionary.sh dict-v2026.05.21
#
# Requirements:
#   - python3 with the DictionaryBuilder source tree on disk
#   - sqlite3 CLI (used to collect release-note stats)
#   - gh CLI authenticated against shiinayane/KotobaLab
#   - dataset/source/jitendex-yomitan present locally (builder maintainer only)

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: release_dictionary.sh <tag>

Builds the dictionary database, verifies it, and publishes it as a
GitHub Release artifact at github.com/shiinayane/KotobaLab.

Arguments:
  <tag>    Release tag, e.g. dict-v2026.05.21

The release title is "Dictionary <tag>". The tag must not already
exist on the remote; this script will not overwrite an existing release.
EOF
}

if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

TAG="$1"

# Resolve repo root from the script's own location so the script can be
# invoked from any working directory. cd into it so `gh` resolves the
# correct repository from the local git remote (instead of inferring
# from the caller's cwd).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"

BUILDER_DIR="${REPO_ROOT}/Tools/DictionaryBuilder"
SOURCE_DIR="${REPO_ROOT}/dataset/source/jitendex-yomitan"
SCHEMA_PATH="${BUILDER_DIR}/schema/dictionary_schema.sql"
OUTPUT_DB="${BUILDER_DIR}/output/dictionary.sqlite"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: required command '$1' not found in PATH" >&2
        exit 1
    fi
}

require_cmd python3
require_cmd sqlite3
require_cmd gh
require_cmd shasum

if ! gh auth status >/dev/null 2>&1; then
    echo "ERROR: gh is not authenticated. Run 'gh auth login' first." >&2
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "ERROR: source dataset not found at: $SOURCE_DIR" >&2
    echo "Obtain jitendex-yomitan and place it there before releasing." >&2
    exit 1
fi

if gh release view "$TAG" >/dev/null 2>&1; then
    echo "ERROR: release tag '$TAG' already exists on the remote." >&2
    echo "Pick a new tag, or delete the existing release first." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. Build
# ---------------------------------------------------------------------------
echo "==> Building dictionary database..."
python3 "${BUILDER_DIR}/main.py" \
    --source "$SOURCE_DIR" \
    --schema "$SCHEMA_PATH" \
    --output "$OUTPUT_DB"

# ---------------------------------------------------------------------------
# 2. Verify (hard fails on any structural regression)
# ---------------------------------------------------------------------------
echo "==> Verifying dictionary database..."
python3 "${BUILDER_DIR}/debug/verify_database.py" --db "$OUTPUT_DB"

# ---------------------------------------------------------------------------
# 3. Checksum
# ---------------------------------------------------------------------------
echo "==> Computing SHA-256 checksum..."
CHECKSUM_FILE="${OUTPUT_DB}.sha256"
# Write the standard "<hash>  <filename>" format so consumers can verify
# with `shasum -a 256 -c dictionary.sqlite.sha256` directly.
(cd "$(dirname "$OUTPUT_DB")" && shasum -a 256 "$(basename "$OUTPUT_DB")") > "$CHECKSUM_FILE"
CHECKSUM="$(awk '{print $1}' "$CHECKSUM_FILE")"

# ---------------------------------------------------------------------------
# 4. Stats for release notes
# ---------------------------------------------------------------------------
# stat: macOS uses -f%z, GNU uses -c%s.
if SIZE_BYTES="$(stat -f%z "$OUTPUT_DB" 2>/dev/null)"; then
    :
else
    SIZE_BYTES="$(stat -c%s "$OUTPUT_DB")"
fi
SIZE_MB="$(awk "BEGIN { printf \"%.2f\", ${SIZE_BYTES}/1024/1024 }")"
WORD_COUNT="$(sqlite3 "$OUTPUT_DB" 'SELECT COUNT(*) FROM words;')"
MEANING_COUNT="$(sqlite3 "$OUTPUT_DB" 'SELECT COUNT(*) FROM meanings;')"

# ---------------------------------------------------------------------------
# 5. Publish release
# ---------------------------------------------------------------------------
NOTES_FILE="$(mktemp)"
trap 'rm -f "$NOTES_FILE"' EXIT

cat > "$NOTES_FILE" <<EOF
Dictionary database build for KotobaLab.

| Metric  | Value |
| ------- | ----: |
| Size    | ${SIZE_MB} MB |
| Words   | ${WORD_COUNT} |
| Meanings | ${MEANING_COUNT} |
| SHA-256 | \`${CHECKSUM}\` |

Source: derivative work of [JMdict](https://www.edrdg.org/jmdict/j_jmdict.html) via [jitendex-yomitan](https://github.com/stephenmk/jitendex).
License: CC BY-SA 4.0.

To use this build, download \`dictionary.sqlite\` and place it at
\`KotobaLab/Resources/dictionary.sqlite\`. See the repository README for
the full onboarding flow.
EOF

echo "==> Publishing release ${TAG}..."
gh release create "$TAG" \
    "$OUTPUT_DB" \
    "$CHECKSUM_FILE" \
    --title "Dictionary ${TAG}" \
    --notes-file "$NOTES_FILE"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "Released ${TAG}"
echo "  Size:     ${SIZE_MB} MB"
echo "  Words:    ${WORD_COUNT}"
echo "  Meanings: ${MEANING_COUNT}"
echo "  SHA-256:  ${CHECKSUM}"
echo ""
echo "URL: https://github.com/shiinayane/KotobaLab/releases/tag/${TAG}"
