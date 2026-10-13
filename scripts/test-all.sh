#!/bin/bash
set -euo pipefail

# 跑全部测试。提交前用这个。
#
# 六步，任一步失败就停：
#   1. 共享层的 Kotlin 测试。两个平台都跑，macosArm64 也在内。
#   2. 合同常量有没有漂移。
#   3. 合同的跨段规则。schema 表达不了的那些。
#   4. 割接脚本的断言。
#   5. macOS SwiftUI 宿主的 XCTest。
#   6. issue-first 守卫的自测。
#
# 第 5 步自己也会跑第 2、3 步。分开列是为了让它们单独报错，一眼能看出问题在哪。
#
# 第 6 步是守卫脚本的单元测试，不是 issue-first 门禁。
# 它只保证守卫本身没写坏，不检查改动有没有关联 issue。

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

step() { printf '\n=== %s ===\n' "$1"; }

step "Kotlin 共享层"
/bin/sh ./kotlin test

step "设计合同常量"
# `-I` 是隔离模式：不读当前目录，防止目录里被放一个同名模块顶替标准库。
python3 -I "$ROOT/scripts/generate-contract-constants.py" --check

step "设计合同跨段规则"
python3 -I "$ROOT/scripts/validate-contract.py"

step "helper 割接脚本"
bash "$ROOT/scripts/verify-helper-cutover.sh" selftest

step "macOS SwiftUI 宿主"
bash "$ROOT/scripts/test-macos-swift.sh"

step "issue-first 守卫"
bash "$ROOT/scripts/hooks/test-guard.sh"

printf '\n全部通过。\n'
