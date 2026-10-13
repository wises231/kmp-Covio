#!/bin/bash
# SessionStart hook。把当前分支和对应 issue 打进会话上下文。
#
# 不调网络，不调 gh。读本地文件，几毫秒返回。
# 任何失败都不阻断会话，始终 exit 0。
#
# 输出格式见 docs/workflow/issue-first.md。

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

if [ ! -d "$ROOT/docs/roadmap/issues" ]; then
  exit 0
fi

command -v python3 >/dev/null 2>&1 || exit 0

python3 -I - "$ROOT" <<'PY' || true
import json
import os
import re
import subprocess
import sys

root = sys.argv[1]

# 长命分支。和 scripts/hooks/guard.py 的 LONG_LIVED_DEFAULT 保持一致。
LONG_LIVED = ("main", "feature/swiftui-macos")

BRANCH_RE = re.compile(
    r"^(?:feature|fix|design|plan|spike|docs|chore)/(E[0-9]{2}(?:-S[0-9]{2})?)-"
)


def git(*args):
    try:
        result = subprocess.run(
            ["git"] + list(args),
            cwd=root,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def load_issue_map():
    path = os.path.join(root, "docs", "roadmap", "issues", ".created.json")
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return {}
    return {str(key): value for key, value in data.items()}


def find_issue_file(local_id):
    """按编号找 issue 文件。文件名形如 E01-S01-<slug>.md。"""
    folder = os.path.join(root, "docs", "roadmap", "issues")
    try:
        names = os.listdir(folder)
    except OSError:
        return None
    for name in sorted(names):
        if not name.endswith(".md"):
            continue
        if name == local_id + ".md" or name.startswith(local_id + "-"):
            return os.path.join(folder, name)
    return None


def read_front_matter(path):
    """读 issue 文件的 front-matter。返回字段字典。"""
    try:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return {}
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}
    fields = {}
    for line in parts[1].splitlines():
        key, sep, value = line.partition(":")
        if not sep:
            continue
        fields[key.strip().lower()] = value.strip()
    return fields


def unquote(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


branch = git("rev-parse", "--abbrev-ref", "HEAD")
if not branch or branch == "HEAD":
    sys.exit(0)

lines = ["issue-first：当前分支 %s" % branch]

match = BRANCH_RE.match(branch)
local_id = match.group(1) if match else None

if local_id is None:
    if branch in LONG_LIVED:
        lines.append("长命分支。提交仍要写 issue 尾行。")
    else:
        lines.append("分支名不含 issue 编号。开工前先建分支：")
        lines.append("  git switch -c feature/<本地编号>-<描述> feature/swiftui-macos")
else:
    number = load_issue_map().get(local_id)
    title = None
    blocked = None

    path = find_issue_file(local_id)
    if path:
        fields = read_front_matter(path)
        title = unquote(fields.get("title", "")) or None
        raw = unquote(fields.get("blocked-by", "") or fields.get("blocked_by", ""))
        blocked = raw.strip("[]").strip().replace("'", "").replace('"', "")
        blocked = blocked or None

    label = local_id
    if title:
        label = "%s %s" % (local_id, title)
    if number:
        label = "%s（GitHub #%s）" % (label, number)
    lines.append("对应 issue：%s" % label)

    if blocked:
        lines.append("前置依赖：%s" % blocked)
    if not path:
        lines.append("警告：docs/roadmap/issues/ 里找不到 %s 的定义文件。" % local_id)

lines.append("集成分支：feature/swiftui-macos")
lines.append("issue 索引：docs/roadmap/issues/")
lines.append("工作流规范：docs/workflow/issue-first.md")

sys.stdout.write("\n".join(lines) + "\n")
PY

exit 0
