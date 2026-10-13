#!/bin/bash
# 创建 Covio 需要的自定义 issue type。
#
# 用法：
#   bash scripts/sync-issue-types.sh --dry-run
#   bash scripts/sync-issue-types.sh
#
# 警告：issue type 是账号级的。创建后该账号名下所有仓库都会出现这 4 个类型。
# 本脚本只创建缺失的类型。不动 GitHub 自带的 Task / Bug / Feature。
# 本脚本只做新增，不做修改，也不删除。
#
# 需要 read:user scope。缺失时脚本会打印补救命令：
#   gh auth refresh -h github.com -s read:user
#
# 类型定义见 docs/workflow/work-types.md。
#
# 本脚本兼容 macOS 自带的 bash 3.2。不要引入关联数组（declare -A）和 mapfile。

set -euo pipefail

DRY_RUN=0
REPO_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --repo) shift; REPO_ARGS=(--repo "${1:-}") ;;
    -h|--help)
      sed -n '2,17p' "$0"
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      exit 2
      ;;
  esac
  shift
done

# 格式：<name>|<color>|<description>
# color 只能取 GitHub 的固定色名。不用十六进制。
# 自带的 Task 是 yellow，Bug 是 red，Feature 是 blue。这里避开这三个。
TYPES=$(cat <<'EOF'
Goal|purple|跨多个 issue 的产品目标。关完所有 sub-issue 才算完成。
Design|pink|架构决策、设计合同变更、ADR。产物是文档，不是代码。
Plan|green|阶段划分和迁移路径。产物是计划文档。
Optimization|orange|性能、资源或可读性改进。关闭要有前后对比数据。
EOF
)

info() { printf '%s\n' "$*" >&2; }

# ---- 1. scope 检查 ---------------------------------------------------------
# /user/issue-types 需要 read:user。repo scope 不够。
if ! gh auth status 2>&1 | grep -q "'read:user'"; then
  info "错误：当前 token 没有 read:user scope。"
  info ""
  info "先运行下面这条命令，按提示完成浏览器授权："
  info "  gh auth refresh -h github.com -s read:user"
  info ""
  info "这条命令是交互式的，只能由人执行。"
  exit 1
fi

# ---- 2. 读已有类型 ---------------------------------------------------------
info "读取账号已有的 issue type。"

# 响应可能是裸数组，也可能是带 types 键的对象。两种都接。
EXISTING="$(gh api /user/issue-types \
  --jq 'if type == "array" then . else (.types // .issue_types // []) end | .[].name' \
  2>/dev/null || true)"

if [ -n "$EXISTING" ]; then
  info "已有：$(printf '%s' "$EXISTING" | tr '\n' ' ')"
else
  info "已有：读不到列表，按空处理。"
fi

# ---- 3. 只创建缺的 ---------------------------------------------------------
info ""
info "创建缺失的类型"

created=0
skipped=0

while IFS='|' read -r name color description; do
  [ -z "$name" ] && continue

  if printf '%s\n' "$EXISTING" | grep -qxF "$name"; then
    info "  跳过 ${name}（已存在）"
    skipped=$((skipped + 1))
    continue
  fi

  info "  创建 ${name}（${color}）"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "    [dry-run] gh api --method POST /user/issue-types -f name=$name -f color=$color -F is_enabled=true"
    created=$((created + 1))
    continue
  fi

  # is_enabled 是必填的布尔值。-F 才会传成 true，-f 会传成字符串。
  gh api --method POST /user/issue-types \
    -f name="$name" \
    -f color="$color" \
    -f description="$description" \
    -F is_enabled=true >/dev/null
  info "    -> 已创建"
  created=$((created + 1))
done <<< "$TYPES"

# ---- 4. 核对本仓库可见的类型 -----------------------------------------------
info ""
if [ "$DRY_RUN" -eq 1 ]; then
  info "dry-run 完成。没有写入 GitHub。"
  info "计划创建 $created 个，跳过 $skipped 个。"
  exit 0
fi

info "完成。新建 $created 个，跳过 $skipped 个。"

SLUG="$(gh repo view ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
if [ -n "$SLUG" ]; then
  VISIBLE="$(gh api "/repos/$SLUG/issue-types" --jq '.[].name' 2>/dev/null || true)"
  info ""
  info "本仓库（${SLUG}）当前可见的类型："
  if [ -n "$VISIBLE" ]; then
    printf '%s\n' "$VISIBLE" | sed 's/^/  /' >&2
    info ""
    info "新建的类型如果不在上面，去仓库 Settings 里手动启用。"
  else
    info "  读不到。"
  fi
fi

info ""
info "下一步：给已有 issue 补 type。"
info "  gh issue edit <编号> --type <类型>"
