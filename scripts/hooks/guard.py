#!/usr/bin/env python3
"""issue-first 守卫。检查 git commit 和 gh pr create 是否关联了 issue。

两种入口：

    python3 -I scripts/hooks/guard.py --hook-json
    python3 -I scripts/hooks/guard.py --command '<命令>' --cwd <目录>

第一种是 Claude Code 的 PreToolUse hook。命令从 stdin 的 JSON 里取。
第二种是手工验证和自测用的入口，直接吃命令字符串。

退出码 0 放行。退出码 2 拦下，stderr 是给 agent 看的修复指引。
其他退出码表示脚本自身出错，不会阻断工具调用。

规则见 docs/workflow/issue-first.md。
"""

import json
import os
import re
import shlex
import subprocess
import sys

# ---- 常量 ------------------------------------------------------------------

# 长命分支。这两条分支豁免分支名规则，但提交仍要引用 issue。
LONG_LIVED_DEFAULT = ("main", "feature/swiftui-macos")

# 短分支：<前缀>/<本地编号>-<小写描述>
BRANCH_RE = re.compile(
    r"^(?:feature|fix|design|plan|spike|docs|chore)"
    r"/(E[0-9]{2}(?:-S[0-9]{2})?)-[a-z0-9]+(?:-[a-z0-9]+)*$"
)

# 从任意分支名里抽本地编号。用于给出「当前分支缺编号」的提示。
BRANCH_ID_ANY_RE = re.compile(r"/(E[0-9]{2}(?:-S[0-9]{2})?)-")

# commit 尾行。键名不区分大小写。
TRAILER_RE = re.compile(r"^(Refs|Closes|Fixes|Resolves):[ \t]*(.+)$", re.M | re.I)

# 豁免理由。必须非空。
WAIVER_RE = re.compile(r"^Waiver:[ \t]*\S.*$", re.M)

LOCAL_ID_RE = re.compile(r"^E[0-9]{2}(?:-S[0-9]{2})?$")
GITHUB_ID_RE = re.compile(r"^#([0-9]+)$")

# 宽松的引用搜索。用于命令里的尾行不是独立一行时，以及 PR body。
LOOSE_REF_RE = re.compile(
    r"\b(refs|closes|fixes|resolves)\b:?[ \t]*(#[0-9]+|E[0-9]{2}(?:-S[0-9]{2})?)",
    re.I,
)

# 命令里出现这些说明 commit message 是运行时算出来的，守卫看不到内容。
RUNTIME_MARKERS = ("$(", "`", "<<")

# git 的全局选项。这些选项吃掉后面的一个值。
GIT_GLOBAL_TAKES_VALUE = frozenset(
    {
        "-c",
        "-C",
        "--git-dir",
        "--work-tree",
        "--namespace",
        "--exec-path",
        "--config-env",
        "--super-prefix",
    }
)

ENV_ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
WRAPPERS = frozenset({"env", "command", "nohup", "sudo", "time", "exec", "builtin"})

# 这些 commit 选项不产生提交，守卫不用检查。
# 注意：-n 是 --no-verify，仍然会产生提交，所以不在表里。
INERT_COMMIT_FLAGS = frozenset({"-h", "--help", "--dry-run"})

# 取值的短选项。用于处理 -am "x" 这类选项簇。
SHORT_VALUE_FLAGS = {"m": "message", "F": "file"}

SKIP_ENV = "COVIO_WORKFLOW_SKIP"


# ---- 命令切分 --------------------------------------------------------------


def split_segments(src):
    """按未加引号的 shell 分隔符切分命令。

    引号、$() 和反引号内部不切。
    """
    out = []
    buf = []
    subs = []  # 嵌套的替换栈，元素是 "$(" 或 "`"
    quote = None  # 当前引号字符，None 表示不在引号里
    i = 0
    n = len(src)

    while i < n:
        ch = src[i]

        if quote:
            buf.append(ch)
            if ch == "\\" and quote == '"' and i + 1 < n:
                buf.append(src[i + 1])
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue

        if subs:
            if ch in "\"'":
                quote = ch
                buf.append(ch)
                i += 1
                continue
            if src.startswith("$(", i):
                subs.append("$(")
                buf.append("$(")
                i += 2
                continue
            if ch == "`":
                if subs[-1] == "`":
                    subs.pop()
                else:
                    subs.append("`")
                buf.append(ch)
                i += 1
                continue
            if ch == ")" and subs[-1] == "$(":
                subs.pop()
                buf.append(ch)
                i += 1
                continue
            buf.append(ch)
            i += 1
            continue

        if ch == "\\" and i + 1 < n:
            buf.append(src[i : i + 2])
            i += 2
            continue
        if ch in "\"'":
            quote = ch
            buf.append(ch)
            i += 1
            continue
        if src.startswith("$(", i):
            subs.append("$(")
            buf.append("$(")
            i += 2
            continue
        if ch == "`":
            subs.append("`")
            buf.append(ch)
            i += 1
            continue
        if src.startswith("&&", i) or src.startswith("||", i):
            out.append("".join(buf))
            buf = []
            i += 2
            continue
        if ch in ";|\n&()":
            out.append("".join(buf))
            buf = []
            i += 1
            continue

        buf.append(ch)
        i += 1

    out.append("".join(buf))
    return [seg.strip() for seg in out if seg.strip()]


def parse_git_subcommand(segment):
    """返回 (子命令, 其余参数)。不是 git 命令就返回 None。"""
    try:
        tokens = shlex.split(segment, comments=False)
    except ValueError:
        return None

    i = 0
    while i < len(tokens) and (ENV_ASSIGN_RE.match(tokens[i]) or tokens[i] in WRAPPERS):
        i += 1
    if i >= len(tokens):
        return None
    if os.path.basename(tokens[i]) not in ("git", "git.exe"):
        return None

    i += 1
    while i < len(tokens):
        tok = tokens[i]
        if tok in GIT_GLOBAL_TAKES_VALUE:
            i += 2
            continue
        if tok.startswith("--") and "=" in tok:
            i += 1
            continue
        if tok.startswith("-"):
            i += 1
            continue
        break

    if i >= len(tokens):
        return None
    return tokens[i], tokens[i + 1 :]


def parse_gh_pr_create(segment):
    """判断这一段是不是 gh pr create。是就返回参数列表，否则返回 None。"""
    try:
        tokens = shlex.split(segment, comments=False)
    except ValueError:
        return None

    i = 0
    while i < len(tokens) and (ENV_ASSIGN_RE.match(tokens[i]) or tokens[i] in WRAPPERS):
        i += 1
    if i >= len(tokens) or os.path.basename(tokens[i]) not in ("gh", "gh.exe"):
        return None
    if tokens[i + 1 : i + 3] != ["pr", "create"]:
        return None
    return tokens[i + 3 :]


# ---- commit message 提取 ---------------------------------------------------


def read_text(path, cwd):
    """读文件。读不到返回 None。"""
    full = path if os.path.isabs(path) else os.path.join(cwd or os.getcwd(), path)
    try:
        with open(full, encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return None


def _short_cluster(token, args, index):
    """处理 -am / -amVALUE 这类短选项簇。

    返回 (source, value, 消耗的 token 数)，没有取值选项就返回 None。
    """
    if not token.startswith("-") or token.startswith("--") or len(token) < 2:
        return None

    body = token[1:]
    for pos, ch in enumerate(body):
        if ch in SHORT_VALUE_FLAGS:
            rest = body[pos + 1 :]
            if rest:
                return SHORT_VALUE_FLAGS[ch], rest, 1
            nxt = args[index + 1] if index + 1 < len(args) else ""
            return SHORT_VALUE_FLAGS[ch], nxt, 2
    return None


def extract_message(args, cwd):
    """从 commit 参数里提取 message。

    返回 (source, amend, no_edit, message)。
    source 取值：message / file / stdin / reuse / editor / opaque。
    """
    parts = []
    source = None
    amend = False
    no_edit = False

    i = 0
    while i < len(args):
        arg = args[i]

        if arg in ("-m", "--message"):
            if i + 1 < len(args):
                parts.append(args[i + 1])
                source = "message"
            i += 2
            continue
        if arg.startswith("--message="):
            parts.append(arg.split("=", 1)[1])
            source = "message"
            i += 1
            continue
        if arg in ("-F", "--file"):
            path = args[i + 1] if i + 1 < len(args) else ""
            if path == "-":
                source = "stdin"
            else:
                text = read_text(path, cwd)
                if text is None:
                    source = "opaque"
                else:
                    parts.append(text)
                    source = "file"
            i += 2
            continue
        if arg.startswith("--file="):
            path = arg.split("=", 1)[1]
            if path == "-":
                source = "stdin"
            else:
                text = read_text(path, cwd)
                if text is None:
                    source = "opaque"
                else:
                    parts.append(text)
                    source = "file"
            i += 1
            continue
        if arg == "--amend":
            amend = True
            i += 1
            continue
        if arg == "--no-edit":
            no_edit = True
            i += 1
            continue
        if arg in ("-C", "--reuse-message", "-c", "--reedit-message"):
            source = "reuse"
            i += 2
            continue

        cluster = _short_cluster(arg, args, i)
        if cluster:
            kind, value, consumed = cluster
            if kind == "message":
                parts.append(value)
                source = "message"
            else:
                text = read_text(value, cwd)
                if text is None:
                    source = "opaque"
                else:
                    parts.append(text)
                    source = "file"
            i += consumed
            continue

        i += 1

    if source is None:
        source = "editor"

    return source, amend, no_edit, "\n\n".join(part for part in parts if part)


# ---- 编号解析 --------------------------------------------------------------


def repo_root():
    """从脚本位置推出仓库根目录。"""
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.dirname(os.path.dirname(here))


def load_issue_map():
    """读本地编号到 GitHub 编号的映射。"""
    override = os.environ.get("COVIO_ISSUE_MAP")
    path = override or os.path.join(
        repo_root(), "docs", "roadmap", "issues", ".created.json"
    )
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return {}
    return {str(key): int(value) for key, value in data.items() if str(value).isdigit()}


def number_to_local(issue_map, number):
    for local, value in issue_map.items():
        if str(value) == str(number):
            return local
    return None


# ---- 判定 ------------------------------------------------------------------


def parse_trailer(message):
    """解析尾行。

    返回 (refs, none_flag, has_waiver)。
    refs 是 (kind, value) 的列表，kind 取 local 或 github。
    """
    refs = []
    none_flag = False

    for line in message.splitlines():
        match = TRAILER_RE.match(line.strip())
        if not match:
            continue
        value = match.group(2).strip()
        if value.lower() == "none":
            none_flag = True
            continue
        for token in value.split(","):
            token = token.strip()
            if LOCAL_ID_RE.match(token):
                refs.append(("local", token))
            else:
                gh_match = GITHUB_ID_RE.match(token)
                if gh_match:
                    refs.append(("github", gh_match.group(1)))

    return refs, none_flag, bool(WAIVER_RE.search(message))


def long_lived_branches():
    extra = os.environ.get("COVIO_LONG_LIVED_BRANCHES", "")
    names = list(LONG_LIVED_DEFAULT)
    names.extend(name.strip() for name in extra.split(",") if name.strip())
    return tuple(names)


def current_branch(cwd):
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def last_commit_message(cwd):
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%B"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if result.returncode != 0:
        return None
    return result.stdout


def check_commit(commit, raw_command, branch, issue_map):
    """检查一个 commit。返回错误字符串的列表。"""
    errors = []
    source = commit["source"]
    message = commit["message"]

    if source == "editor":
        if commit["amend"] and commit["no_edit"]:
            errors.append(
                "提交信息无法检查：--amend --no-edit 取不到原有信息。\n"
                "   改用： git commit --amend -m \"<标题>\" -m \"Refs: <编号>\""
            )
        else:
            errors.append(
                "提交信息无法检查：命令没带 -m，git 会打开编辑器。\n"
                "   改用： git commit -m \"<标题>\" -m \"Refs: <编号>\"\n"
                "   改已有提交： git commit --amend --no-edit"
            )
        return errors

    if source == "stdin":
        errors.append(
            "提交信息无法检查：-F - 从标准输入读。\n"
            "   改用： git commit -m \"<标题>\" -m \"Refs: <编号>\""
        )
        return errors

    runtime = source == "opaque" or any(marker in message for marker in RUNTIME_MARKERS)
    if runtime:
        # message 是运行时算出来的，守卫看不到内容。退回到原始命令里搜尾行。
        if not LOOSE_REF_RE.search(raw_command) and not (
            "Refs: none" in raw_command and WAIVER_RE.search(raw_command)
        ):
            errors.append(
                "提交信息由运行时计算，守卫看不到尾行。\n"
                "   把尾行写成字面量，或改用： git commit -F <文件>"
            )
            return errors
        refs, none_flag, has_waiver = parse_trailer(message)
    else:
        refs, none_flag, has_waiver = parse_trailer(message)

    # 分支名
    branch_id = None
    if branch and branch not in long_lived_branches() and branch != "HEAD":
        match = BRANCH_RE.match(branch)
        if match:
            branch_id = match.group(1)
        else:
            known = BRANCH_ID_ANY_RE.search(branch)
            hint = ""
            if known:
                hint = "   编号对了，描述部分要小写字母、数字和短横线。\n"
            errors.append(
                "分支名不合规\n"
                "   当前： %s\n"
                "   要求： <前缀>/<本地编号>-<小写描述>\n"
                "   前缀： feature fix design plan spike docs chore\n"
                "   例：   feature/E03-S02-workbench-store\n"
                "%s"
                "   修：   git switch -c feature/E03-S02-<描述> %s"
                % (branch, hint, long_lived_branches()[1])
            )

    # 尾行
    if none_flag and not has_waiver:
        errors.append(
            "Refs: none 必须配一行非空的 Waiver: 理由。\n"
            "   例： Waiver: 错别字修正，无行为变化"
        )
    elif not refs and not none_flag:
        example = branch_id or "<本地编号>"
        number = issue_map.get(branch_id, "") if branch_id else ""
        suffix = "（对应 GitHub #%s）" % number if number else ""
        errors.append(
            "提交信息缺少 issue 尾行\n"
            "   在正文最后加一行：\n"
            "     Refs: %s%s\n"
            "   映射在 docs/roadmap/issues/.created.json。" % (example, suffix)
        )
    elif refs and branch_id:
        known = set()
        for kind, value in refs:
            if kind == "local":
                known.add(value)
            else:
                local = number_to_local(issue_map, value)
                if local:
                    known.add(local)
        if known and branch_id not in known:
            errors.append(
                "尾行的编号与分支不一致\n"
                "   分支： %s\n"
                "   尾行： %s\n"
                "   在 %s 的分支上只能引用 %s。"
                % (branch, ", ".join(sorted(known)), branch_id, branch_id)
            )

    return errors


def check_pr(args, cwd):
    """检查 gh pr create。返回错误字符串的列表。"""
    errors = []

    body = None
    fills = False
    i = 0
    while i < len(args):
        arg = args[i]
        if arg in ("--body", "-b"):
            body = args[i + 1] if i + 1 < len(args) else ""
            i += 2
            continue
        if arg.startswith("--body="):
            body = arg.split("=", 1)[1]
            i += 1
            continue
        if arg in ("--body-file", "-F"):
            path = args[i + 1] if i + 1 < len(args) else ""
            body = read_text(path, cwd) or ""
            i += 2
            continue
        if arg.startswith("--body-file="):
            body = read_text(arg.split("=", 1)[1], cwd) or ""
            i += 1
            continue
        if arg in ("--fill", "-f", "--fill-verbose"):
            fills = True
        i += 1

    if body is None:
        reason = "--fill 从 commit 信息生成 body。" if fills else "命令没带 body。"
        errors.append(
            "PR 缺少 body，无法关联 issue\n"
            "   %s\n"
            "   用 --body 显式写：\n"
            "     gh pr create --base %s --body \"Closes #27\""
            % (reason, long_lived_branches()[1])
        )
        return errors

    if not LOOSE_REF_RE.search(body):
        errors.append(
            "PR body 里没有 issue 引用\n"
            "   短分支 → 集成分支写 Refs #27。\n"
            "   集成分支 → main 写 Closes #27。\n"
            "   模板见 .github/PULL_REQUEST_TEMPLATE.md。"
        )

    return errors


# ---- 主流程 ----------------------------------------------------------------


def gather(command, cwd):
    """从命令里找出全部 commit 和 pr create。"""
    commits = []
    prs = []
    for segment in split_segments(command):
        parsed = parse_git_subcommand(segment)
        if parsed and parsed[0] == "commit":
            if any(flag in INERT_COMMIT_FLAGS for flag in parsed[1]):
                continue
            source, amend, no_edit, message = extract_message(parsed[1], cwd)
            commits.append(
                {
                    "source": source,
                    "amend": amend,
                    "no_edit": no_edit,
                    "message": message,
                }
            )
            continue
        pr_args = parse_gh_pr_create(segment)
        if pr_args is not None:
            prs.append(pr_args)
    return commits, prs


def report(errors, branch, header):
    lines = ["", "⛔ issue-first 检查未通过。", "", header]
    if branch:
        lines.append("当前分支：%s" % branch)
    lines.append("")
    for index, error in enumerate(errors, start=1):
        lines.append("%d. %s" % (index, error))
        lines.append("")
    lines.append("规则见 AGENTS.md。细节见 docs/workflow/issue-first.md。")
    lines.append("改好再提交。不要用 %s 绕过。" % SKIP_ENV)
    lines.append("")
    sys.stderr.write("\n".join(lines))


def main(argv):
    command = None
    cwd = None
    hook_mode = False

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--hook-json":
            hook_mode = True
            i += 1
        elif arg == "--command":
            command = argv[i + 1] if i + 1 < len(argv) else ""
            i += 2
        elif arg == "--cwd":
            cwd = argv[i + 1] if i + 1 < len(argv) else ""
            i += 2
        elif arg in ("-h", "--help"):
            sys.stdout.write(__doc__)
            return 0
        else:
            i += 1

    if hook_mode:
        try:
            payload = json.load(sys.stdin)
        except ValueError:
            return 0
        if payload.get("tool_name") != "Bash":
            return 0
        tool_input = payload.get("tool_input") or {}
        command = tool_input.get("command") or ""
        cwd = cwd or payload.get("cwd") or os.getcwd()
    else:
        command = command or ""
        cwd = cwd or os.getcwd()

    if SKIP_ENV in command:
        sys.stderr.write(
            "[workflow] 检测到 %s，跳过 issue-first 检查。\n" % SKIP_ENV
        )
        return 0

    # 廉价预筛。绝大多数 Bash 调用在这里直接放行。
    if "commit" not in command and "pr create" not in command:
        return 0

    if not os.path.isdir(cwd):
        return 0

    commits, prs = gather(command, cwd)
    if not commits and not prs:
        return 0

    branch = current_branch(cwd)
    if branch is None:
        # 不在 git 仓库里，不拦。
        return 0

    issue_map = load_issue_map()
    errors = []

    for commit in commits:
        if commit["source"] == "editor" and commit["amend"] and commit["no_edit"]:
            existing = last_commit_message(cwd)
            if existing and existing.strip():
                commit["source"] = "reuse"
                commit["message"] = existing
        errors.extend(check_commit(commit, command, branch, issue_map))

    for pr_args in prs:
        errors.extend(check_pr(pr_args, cwd))

    if errors:
        report(errors, branch, "共 %d 处问题。" % len(errors))
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
