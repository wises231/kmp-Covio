#!/bin/bash
set -euo pipefail

# 跑 macOS SwiftUI 宿主的 XCTest。

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="$ROOT/build/xcode-dd"
PROJECT="$ROOT/macosApp/Covio.xcodeproj"
SCHEME="Covio"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This script requires macOS.\n' >&2
  exit 1
fi

cd "$ROOT"

# spike 测试会把测量结果打到 stdout。--quiet 会压掉它们，所以不加。
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  test
