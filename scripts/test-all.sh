#!/bin/bash
set -euo pipefail

# 跑全部测试。提交前用这个。
#
# 三步，任一步失败就停：
#   1. 共享层的 Kotlin 测试。两个平台都跑，macosArm64 也在内。
#   2. 割接脚本的断言。
#   3. macOS SwiftUI 宿主的 XCTest。

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

step() { printf '\n=== %s ===\n' "$1"; }

step "Kotlin 共享层"
/bin/sh ./kotlin test

step "helper 割接脚本"
bash "$ROOT/scripts/verify-helper-cutover.sh" selftest

step "macOS SwiftUI 宿主"
bash "$ROOT/scripts/test-macos-swift.sh"

printf '\n全部通过。\n'
