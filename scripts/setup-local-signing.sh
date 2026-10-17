#!/bin/bash
set -euo pipefail

# 给本机准备固定的签名身份。
#
# ad-hoc 签名没有 Team ID，TCC 的识别依据退化成 cdhash。每次构建换一个 cdhash，
# 系统就把新构建当成新应用，重新要辅助功能与桌面文件夹权限。换成证书签名后
# 识别依据锚定证书，授权跨构建保留。
#
# Signing.local.xcconfig 不进仓库，所以每个 worktree 各要一份。本脚本负责补上。
# 原理与建证书的步骤见 docs/adr/adr-0005-local-code-signing.md。
#
# 下面四种情况什么都不写，保持工程默认的 ad-hoc：
#   - 不是 macOS
#   - 工程没有 Signing.xcconfig（旧分支，还没合并签名修复）
#   - 已经有 Signing.local.xcconfig（里面可能是别的身份，不动它）
#   - 本机没有这张证书（CI 与别人的克隆）

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_CONFIG="$ROOT/macosApp/Signing.xcconfig"
OVERRIDE="$ROOT/macosApp/Signing.local.xcconfig"
IDENTITY="${COVIO_SIGN_IDENTITY:-Covio Dev}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 0
fi

if [[ ! -f "$PROJECT_CONFIG" ]]; then
  exit 0
fi

if [[ -f "$OVERRIDE" ]]; then
  exit 0
fi

# 不用 -v。`security find-identity -v` 只列受信任的身份，自签名证书不在其中。
if ! security find-identity -p codesigning 2>/dev/null | grep -q "\"$IDENTITY\""; then
  exit 0
fi

cat > "$OVERRIDE" <<EOF
// 本机签名身份。此文件不进仓库，由 scripts/setup-local-signing.sh 生成。
// 说明见 macosApp/Signing.xcconfig 与 docs/adr/adr-0005-local-code-signing.md。

CODE_SIGN_IDENTITY = $IDENTITY
CODE_SIGN_STYLE = Manual
EOF

printf '本机签名身份已固定为 %s。\n' "$IDENTITY"
printf '写入 %s\n' "$OVERRIDE"
