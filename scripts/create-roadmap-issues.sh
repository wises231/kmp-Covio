#!/bin/bash
# 按 docs/roadmap/issues/ 下的定义创建 GitHub issue。
#
# 用法：
#   bash scripts/create-roadmap-issues.sh --dry-run
#   bash scripts/create-roadmap-issues.sh
#   bash scripts/create-roadmap-issues.sh --only E00
#
# 警告：本仓库是公开仓库。不加 --dry-run 会把 issue 发布到 GitHub。
#
# 脚本可以重复运行。docs/roadmap/issues/.created.json 里已有的编号会跳过。
#
# front-matter 的 type 字段是可选的。填了就传给 gh issue create --type。
# 缺字段时不传 --type。
# gh 从账号级列表解析类型。读不到这个列表时 --type 会失败。
# 所以有 type 字段时，脚本先检查 scope，不合格就整体退出。
# 自定义类型由 scripts/sync-issue-types.sh 创建。
#
# 本脚本兼容 macOS 自带的 bash 3.2。不要引入关联数组（declare -A）和 mapfile。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISSUES_DIR="$ROOT/docs/roadmap/issues"
CREATED_FILE="$ISSUES_DIR/.created.json"

DRY_RUN=0
ONLY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --only) shift; ONLY="${1:-}" ;;
    -h|--help)
      sed -n '2,11p' "$0"
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      exit 2
      ;;
  esac
  shift
done

if [ ! -d "$ISSUES_DIR" ]; then
  echo "找不到 issue 目录：$ISSUES_DIR" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

MAP_FILE="$TMP/map.tsv"
: > "$MAP_FILE"

# index.tsv 与 map.tsv 的字段分隔符。不要用制表符：bash 的 read 会折叠连续空白，
# 空字段（例如 epic 的 parent）会因此丢失。
SEP="|"

info() { printf '%s\n' "$*" >&2; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] %s\n' "$*" >&2
    return 0
  fi
  "$@"
}

# 本地编号 -> GitHub 编号。映射存在 map.tsv 里，避免 bash 3.2 没有关联数组。
map_get() {
  awk -F'\t' -v key="$1" '$1 == key { print $2; exit }' "$MAP_FILE"
}

map_put() {
  printf '%s\t%s\n' "$1" "$2" >> "$MAP_FILE"
}

# ---- 1. 解析 front-matter --------------------------------------------------
# python3 把每个 issue 解析成 index.tsv 的一行，正文写到 $TMP/<id>.body。
python3 - "$ISSUES_DIR" "$TMP" <<'PY'
import os
import re
import sys

issues_dir, tmp = sys.argv[1], sys.argv[2]

FRONT_MATTER = re.compile(r"\A---\r?\n(.*?)\r?\n---\r?\n?(.*)\Z", re.S)


def unquote(text):
    if len(text) >= 2 and text[0] == text[-1] and text[0] in "\"'":
        return text[1:-1]
    return text


def parse_scalar(raw):
    raw = raw.strip()
    if raw in ("", "null", "~"):
        return None
    if raw.startswith("[") and raw.endswith("]"):
        inner = raw[1:-1].strip()
        if not inner:
            return []
        return [unquote(part.strip()) for part in inner.split(",") if part.strip()]
    return unquote(raw)


rows = []
for name in sorted(os.listdir(issues_dir)):
    if not name.endswith(".md"):
        continue
    with open(os.path.join(issues_dir, name), encoding="utf-8") as handle:
        text = handle.read()
    match = FRONT_MATTER.match(text)
    if not match:
        sys.exit(f"{name}：缺少 YAML front-matter")

    fields = {}
    for line in match.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            sys.exit(f"{name}：无法解析 front-matter 行 {line!r}")
        key, _, value = line.partition(":")
        fields[key.strip()] = parse_scalar(value)

    for required in ("id", "title", "labels", "parent"):
        if required not in fields:
            sys.exit(f"{name}：缺少字段 {required}")

    issue_id = fields["id"]
    with open(os.path.join(tmp, f"{issue_id}.body"), "w", encoding="utf-8") as handle:
        handle.write(match.group(2).strip() + "\n")

    rows.append(
        {
            "id": issue_id,
            "title": fields["title"] or "",
            "labels": fields["labels"] or [],
            "parent": fields["parent"] or "",
            "milestone": fields.get("milestone") or "",
            "blocked_by": fields.get("blocked-by") or [],
            "file": name,
            # type 是可选的。缺字段时不传 --type，兼容没有自定义类型的账号。
            "type": fields.get("type") or "",
        }
    )

# 字段分隔符用 | 而不是制表符。bash 的 read 会把连续的空白分隔符折叠成一个，
# 空字段（例如 epic 的 parent）会因此丢失。
SEP="|"


def check_separator(name, value):
    if SEP in value:
        sys.exit(f"{name}：字段值不能包含 {SEP!r}：{value!r}")
    return value


ids = [row["id"] for row in rows]
if len(ids) != len(set(ids)):
    sys.exit("存在重复的 issue 编号。")

# epic 排在前面，sub-issue 按编号排。父 issue 必须先于子 issue 创建。
rows.sort(key=lambda row: (row["parent"] != "", row["id"]))

with open(os.path.join(tmp, "index.tsv"), "w", encoding="utf-8") as handle:
    for row in rows:
        fields_out = [
            row["id"],
            row["title"],
            ",".join(row["labels"]),
            row["parent"],
            row["milestone"],
            ",".join(row["blocked_by"]),
            row["file"],
            # type 放在最后。里程碑靠 cut -f5 取，插在中间会错位。
            row["type"],
        ]
        handle.write(SEP.join(check_separator(row["id"], f) for f in fields_out) + "\n")

print(f"解析 {len(rows)} 个 issue 定义。", file=sys.stderr)
PY

INDEX="$TMP/index.tsv"

# ---- 1.5 issue type 预检 ---------------------------------------------------
# issue type 是账号级对象。gh 从账号列表解析 --type，不从仓库列表解析。
# 列表读不到时 gh 把可用类型当成空，第一个带 type 的 issue 就会失败。
# 那时前面的 issue 可能已经建出来了。所以在动 GitHub 之前先拦住。
if [ "$DRY_RUN" -eq 0 ]; then
  if cut -d"$SEP" -f8 "$INDEX" | grep -qv '^$'; then
    if ! gh auth status 2>&1 | grep -qE "'(user|read:user)'"; then
      info "错误：定义里有 type 字段，但当前 token 没有 user scope。"
      info ""
      info "gh 读不到账号级类型列表时，--type 会失败。"
      info "先运行下面两条命令，第一条按提示完成浏览器授权："
      info "  gh auth refresh -h github.com -s user"
      info "  bash scripts/sync-issue-types.sh"
      info ""
      info "本次没有写入 GitHub。"
      exit 1
    fi
  fi
fi

# ---- 2. 标签与里程碑定义 ---------------------------------------------------
# 格式：<标签名>|<颜色>|<说明>
LABELS=$(cat <<'EOF'
epic|5319E7|大颗粒工作包，带 sub-issue
research|0075CA|按 docs/research 规范产出的研究主题
spike|0075CA|一次性技术验证，产出证据而非代码
phase-0-research|C5DEF5|阶段 0 · 调研与决策
phase-1-curtain-core|C5DEF5|阶段 1 · 挂帘内核
phase-2-workspace-model|C5DEF5|阶段 2 · 工作区模型
phase-3-widgets|C5DEF5|阶段 3 · Widgets 首页
phase-4-module-panes|C5DEF5|阶段 4 · 模块工作区化
phase-5-quality|C5DEF5|阶段 5 · 质量与交付
area/trigger|D4C5F9|触发层
area/shell|D4C5F9|挂帘外壳
area/pane|D4C5F9|工作区
area/widget|D4C5F9|组件与网格
area/contract|D4C5F9|设计合同
area/kmp|D4C5F9|kmpDomain 共享层
area/swift|D4C5F9|SwiftUI 宿主
area/a11y|FBCA04|无障碍
area/perf|FBCA04|性能与资源
area/test|FBCA04|测试
area/docs|FBCA04|文档
EOF
)

# ---- 前置检查 --------------------------------------------------------------
REPO_ARGS=()
if [ -n "${ROADMAP_REPO:-}" ]; then
  REPO_ARGS=(--repo "$ROADMAP_REPO")
fi

REPO_SLUG="<owner>/<repo>"
if [ "$DRY_RUN" -eq 0 ]; then
  if ! gh auth status >/dev/null 2>&1; then
    info "错误：gh 未登录。先运行 gh auth login。"
    exit 1
  fi
  REPO_SLUG="$(gh repo view ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} --json nameWithOwner --jq .nameWithOwner)"
  info "目标仓库：$REPO_SLUG"
else
  info "dry-run：不会写入 GitHub。"
fi

matches_only() {
  [ -z "$ONLY" ] && return 0
  case "$1" in
    "$ONLY"|"$ONLY"-*) return 0 ;;
    *) return 1 ;;
  esac
}

# ---- 3. 标签 ---------------------------------------------------------------
info ""
info "1. 标签"

EXISTING_LABELS=""
if [ "$DRY_RUN" -eq 0 ]; then
  EXISTING_LABELS="$(gh label list --limit 200 ${REPO_ARGS[@]+"${REPO_ARGS[@]}"} --json name --jq '.[].name' 2>/dev/null || true)"
fi

while IFS='|' read -r label color description; do
  [ -z "$label" ] && continue
  if printf '%s\n' "$EXISTING_LABELS" | grep -qxF "$label"; then
    continue
  fi
  info "  建标签 $label"
  run gh label create "$label" --color "$color" --description "$description" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"}
done <<< "$LABELS"

# ---- 4. 里程碑 -------------------------------------------------------------
info ""
info "2. 里程碑"

EXISTING_MILESTONES=""
if [ "$DRY_RUN" -eq 0 ]; then
  EXISTING_MILESTONES="$(gh api "repos/$REPO_SLUG/milestones?state=all&per_page=100" --jq '.[].title' 2>/dev/null || true)"
fi

cut -d"$SEP" -f5 "$INDEX" | grep -v '^$' | sort -u > "$TMP/milestones.txt"
while IFS= read -r milestone; do
  [ -z "$milestone" ] && continue
  if printf '%s\n' "$EXISTING_MILESTONES" | grep -qxF "$milestone"; then
    continue
  fi
  info "  建里程碑 $milestone"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "  [dry-run] gh api repos/$REPO_SLUG/milestones -f title=$milestone"
  else
    gh api "repos/$REPO_SLUG/milestones" -f title="$milestone" >/dev/null
  fi
done < "$TMP/milestones.txt"

# ---- 5. 载入已有映射 -------------------------------------------------------
if [ -f "$CREATED_FILE" ]; then
  info ""
  info "读取已有映射：$CREATED_FILE"
  python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
for key in sorted(data):
    print(f"{key}\t{data[key]}")
' "$CREATED_FILE" >> "$MAP_FILE"
fi

# ---- 6. 创建 issue ---------------------------------------------------------
info ""
info "3. 创建 issue"

# 第一遍建 epic，第二遍建 sub-issue。父编号在第二遍开始前已知。
for pass in epic sub; do
  while IFS="$SEP" read -r id title labels parent milestone blocked_by file issue_type; do
    [ -z "$id" ] && continue
    is_sub=0
    [ -n "$parent" ] && is_sub=1
    if [ "$pass" = epic ] && [ "$is_sub" -eq 1 ]; then continue; fi
    if [ "$pass" = sub ] && [ "$is_sub" -eq 0 ]; then continue; fi
    if ! matches_only "$id"; then continue; fi

    existing="$(map_get "$id")"
    if [ -n "$existing" ]; then
      info "  跳过 ${id}（已创建，编号 #${existing}）"
      continue
    fi

    label_args=()
    if [ -n "$labels" ]; then
      IFS=',' read -r -a label_list <<< "$labels"
      for label in "${label_list[@]}"; do
        label_args+=(--label "$label")
      done
    fi

    milestone_args=()
    if [ -n "$milestone" ]; then
      milestone_args=(--milestone "$milestone")
    fi

    # 没有 type 字段就不传 --type。账号里没有自定义类型时脚本照样能跑。
    type_args=()
    if [ -n "$issue_type" ]; then
      type_args=(--type "$issue_type")
    fi

    parent_args=()
    if [ "$is_sub" -eq 1 ]; then
      parent_number="$(map_get "$parent")"
      if [ -z "$parent_number" ] || [ "$parent_number" = "-" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
          parent_number="<#$parent>"
        else
          info "  错误：$id 的父 issue $parent 尚未创建。先创建父 issue。"
          exit 1
        fi
      fi
      parent_args=(--parent "$parent_number")
    fi

    info "  创建 ${id}：$title"
    if [ "$DRY_RUN" -eq 1 ]; then
      info "    gh issue create --title \"$title\" --body-file $TMP/$id.body ${label_args[*]:-} ${milestone_args[*]:-} ${type_args[*]:-} ${parent_args[*]:-}"
      map_put "$id" "-"
      continue
    fi

    url="$(gh issue create \
      --title "$title" \
      --body-file "$TMP/$id.body" \
      ${label_args[@]+"${label_args[@]}"} \
      ${milestone_args[@]+"${milestone_args[@]}"} \
      ${type_args[@]+"${type_args[@]}"} \
      ${parent_args[@]+"${parent_args[@]}"} \
      ${REPO_ARGS[@]+"${REPO_ARGS[@]}"})"
    number="${url##*/}"
    map_put "$id" "$number"
    info "    -> #$number"

    python3 -c '
import json, sys
path, key, value = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
except FileNotFoundError:
    data = {}
data[key] = int(value)
with open(path, "w", encoding="utf-8") as handle:
    json.dump(data, handle, ensure_ascii=False, indent=2, sort_keys=True)
    handle.write("\n")
' "$CREATED_FILE" "$id" "$number"
  done < "$INDEX"
done

# ---- 7. 阻塞关系 -----------------------------------------------------------
info ""
info "4. 阻塞关系"

while IFS="$SEP" read -r id title labels parent milestone blocked_by file issue_type; do
  [ -z "$id" ] && continue
  [ -z "$blocked_by" ] && continue
  if ! matches_only "$id"; then continue; fi

  target="$(map_get "$id")"
  if [ -z "$target" ] || [ "$target" = "-" ]; then
    info "  跳过 ${id}：尚未创建"
    continue
  fi

  IFS=',' read -r -a deps <<< "$blocked_by"
  for dep in "${deps[@]}"; do
    dep_number="$(map_get "$dep")"
    if [ -z "$dep_number" ] || [ "$dep_number" = "-" ]; then
      info "  警告：$id 依赖 ${dep}，但 $dep 未创建。跳过。"
      continue
    fi
    info "  #$target 依赖 #${dep_number}（${dep}）"
    run gh issue edit "$target" --add-blocked-by "$dep_number" ${REPO_ARGS[@]+"${REPO_ARGS[@]}"}
  done
done < "$INDEX"

# ---- 8. 汇总 ---------------------------------------------------------------
info ""
if [ "$DRY_RUN" -eq 1 ]; then
  info "dry-run 完成。没有写入 GitHub。"
else
  info "完成。映射已写入 $CREATED_FILE"
fi
info ""
info "本地编号  GitHub 编号"
while IFS="$SEP" read -r id title labels parent milestone blocked_by file issue_type; do
  [ -z "$id" ] && continue
  number="$(map_get "$id")"
  if [ -z "$number" ] || [ "$number" = "-" ]; then
    number="未创建"
  else
    number="#$number"
  fi
  printf '  %-8s  %s\n' "$id" "$number" >&2
done < "$INDEX"
