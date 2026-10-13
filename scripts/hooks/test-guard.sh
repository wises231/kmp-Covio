#!/bin/bash
set -euo pipefail

# guard.py 的表驱动自测。
#
# 在临时 git 仓库里跑，不碰真实仓库，不调网络，不调 gh。
#
# 用例格式：<期望退出码>|<分支>|<命令>|<stderr 必含的关键字>
# 退出码 0 的用例，关键字留空。
#
# 本脚本兼容 macOS 自带的 bash 3.2。

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GUARD="$ROOT/scripts/hooks/guard.py"

if [ ! -f "$GUARD" ]; then
  printf '找不到守卫脚本：%s\n' "$GUARD" >&2
  exit 1
fi

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/covio-guard-test.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

git -C "$SANDBOX" init -q -b main
git -C "$SANDBOX" -c user.email=t@example.com -c user.name=T \
  commit -q --allow-empty \
  -m "Seed the sandbox" -m "Refs: none" -m "Waiver: 测试夹具"

# 夹具的 seed 提交必须能被 --amend --no-edit 的用例读到。
SEED_MESSAGE="$(git -C "$SANDBOX" log -1 --format=%B)"
case "$SEED_MESSAGE" in
  *"Waiver: 测试夹具"*) ;;
  *)
    printf '夹具初始化失败：seed 提交缺少 Waiver 行。\n' >&2
    exit 1
    ;;
esac

make_branch() {
  branch="$1"
  if git -C "$SANDBOX" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$SANDBOX" switch -q "$branch"
  else
    git -C "$SANDBOX" switch -q -c "$branch" main
  fi
}

pass=0
fail=0
index=0

check_case() {
  expect="$1"
  branch="$2"
  cmd="$3"
  keyword="$4"

  index=$((index + 1))
  make_branch "$branch"

  code=0
  out="$(python3 -I "$GUARD" --command "$cmd" --cwd "$SANDBOX" 2>&1)" || code=$?

  if [ "$code" -ne "$expect" ]; then
    fail=$((fail + 1))
    printf '失败 #%d：退出码期望 %s，实际 %s\n  分支：%s\n  命令：%s\n  输出：%s\n' \
      "$index" "$expect" "$code" "$branch" "$cmd" "$out" >&2
    return 0
  fi

  if [ -n "$keyword" ]; then
    case "$out" in
      *"$keyword"*) ;;
      *)
        fail=$((fail + 1))
        printf '失败 #%d：stderr 里找不到 %s\n  命令：%s\n  输出：%s\n' \
          "$index" "$keyword" "$cmd" "$out" >&2
        return 0
        ;;
    esac
  fi

  pass=$((pass + 1))
}

# ---- 用例表 ----------------------------------------------------------------
# 短分支不合规
check_case 2 "feature/workbench-store" \
  'git commit -m "Add the thing"' "分支名不合规"
# 分支编号正确但描述含大写
check_case 2 "feature/E03-S02-Workbench" \
  'git commit -m "Add the thing"' "分支名不合规"
# 缺尾行
check_case 2 "feature/E03-S02-workbench-store" \
  'git commit -m "Add the thing"' "缺少 issue 尾行"
# 走编辑器
check_case 2 "feature/E03-S02-workbench-store" \
  'git commit' "无法检查"
# 走编辑器且 amend
check_case 2 "feature/E03-S02-workbench-store" \
  'git commit --amend' "无法检查"
# 从标准输入读
check_case 2 "feature/E03-S02-workbench-store" \
  'git commit -F -' "无法检查"
# 尾行编号与分支不一致
check_case 2 "feature/E03-S02-workbench-store" \
  'git commit -m "Add x" -m "Refs: E05-S01"' "不一致"
# Refs: none 缺 Waiver
check_case 2 "feature/E03-S02-workbench-store" \
  'git commit -m "Add x" -m "Refs: none"' "Waiver"

# 本地编号尾行
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit -m "Add the thing" -m "Refs: E03-S02"' ""
# GitHub 编号尾行
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit -m "Add x" -m "Refs: #27"' ""
# 短选项簇 -am
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit -am "Add x" -m "Refs: E03-S02"' ""
# 多个编号，含分支编号
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit -m "Add x" -m "Refs: E03-S02, E03-S03"' ""
# git 全局选项
check_case 0 "feature/E03-S02-workbench-store" \
  'git -c user.email=a@b commit -m "Add x" -m "Refs: E03-S02"' ""
# 换目录后再提交
check_case 0 "feature/E03-S02-workbench-store" \
  'cd /tmp && git commit -m "Add x" -m "Refs: E03-S02"' ""
# --amend --no-edit 读原有 message
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit --amend --no-edit' ""
# 集成分支上提交，带引用
check_case 0 "feature/swiftui-macos" \
  'git commit -m "Add x" -m "Refs: E03-S02"' ""
# 主干上提交，走豁免
check_case 0 "main" \
  'git commit -m "Fix a typo" -m "Refs: none" -m "Waiver: 错别字"' ""
# 无法解析的 GitHub 编号不参与一致性检查
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit -m "Add x" -m "Refs: #9999"' ""

# 不是 commit 的命令，一律放行
check_case 0 "feature/E03-S02-workbench-store" 'git status' ""
check_case 0 "feature/E03-S02-workbench-store" 'git log --grep commit' ""
check_case 0 "feature/E03-S02-workbench-store" 'echo "git commit"' ""
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit-tree HEAD^{tree} -m x' ""
check_case 0 "feature/E03-S02-workbench-store" \
  'git commit --help' ""

# PR
check_case 2 "feature/E03-S02-workbench-store" \
  'gh pr create --fill' "缺少 body"
check_case 2 "feature/E03-S02-workbench-store" \
  'gh pr create --body "no reference here"' "没有 issue 引用"
check_case 0 "feature/E03-S02-workbench-store" \
  'gh pr create --base feature/swiftui-macos --body "Refs #27"' ""

# break-glass
check_case 0 "feature/E03-S02-workbench-store" \
  'COVIO_WORKFLOW_SKIP=1 git commit -m "x"' "跳过"

# ---- 汇总 ------------------------------------------------------------------
printf '\n守卫自测：%d 条通过，%d 条失败。\n' "$pass" "$fail"

if [ "$fail" -ne 0 ]; then
  exit 1
fi
