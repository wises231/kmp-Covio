#!/bin/bash
set -euo pipefail

# 构建 macOS SwiftUI 宿主。
#
# kmpDomain.framework 由 Xcode 工程里的 "Build KMP framework" 脚本阶段产出，
# 本脚本只负责调用 xcodebuild。

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="$ROOT/build/xcode-dd"
PROJECT="$ROOT/macosApp/Covio.xcodeproj"
SCHEME="Covio"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This script requires macOS.\n' >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  printf 'Missing xcodebuild. Install Xcode.\n' >&2
  exit 1
fi

cd "$ROOT"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/Covio.app"
if [[ ! -d "$APP" ]]; then
  printf 'Missing app bundle: %s\n' "$APP" >&2
  exit 1
fi

printf 'Built %s\n' "$APP"
