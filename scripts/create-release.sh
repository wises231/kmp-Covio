#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
# 版本号只有一个来源：kmpDomain 的 APP_VERSION。
# 在这里抄一份会漂移，发布脚本就会打出一个与包内版本不同的标签。
MODELS="$ROOT/kmpDomain/src/com/wyz/covio/core/Models.kt"
VERSION="$(sed -n 's/^const val APP_VERSION = "\(.*\)"$/\1/p' "$MODELS")"
if [[ -z "$VERSION" ]]; then
  printf 'Could not read APP_VERSION from %s\n' "$MODELS" >&2
  exit 1
fi
TAG="v$VERSION"
DMG="$DIST/Covio-$VERSION.dmg"
NOTES="$ROOT/RELEASE_NOTES.md"
REPO="wises231/kmp-Covio"

if ! command -v gh >/dev/null 2>&1; then
  printf 'Install the GitHub CLI first: brew install gh\n' >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  printf 'Authenticate first: gh auth login\n' >&2
  exit 1
fi

if [[ ! -f "$DMG" ]]; then
  printf 'Missing artifact: %s\nRun scripts/package-macos-swift.sh first.\n' "$DMG" >&2
  exit 1
fi

# The app reads the Releases page.
# Therefore this release must stay a full release, not a pre-release.
gh release create "$TAG" "$DMG" \
  --repo "$REPO" \
  --title "Covio $VERSION (internal test)" \
  --notes-file "$NOTES"

printf 'Created release %s in %s\n' "$TAG" "$REPO"
