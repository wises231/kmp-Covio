#!/usr/bin/env python3
"""把 Noto Sans SC 裁成打样要用的子集。

用法：

```bash
python3 -I scripts/subset-preview-font.py <完整的 NotoSansSC-Regular.otf> <输出路径>
```

完整的字库有 8.3 MB。打样只画界面文案，用不到全部字。
本脚本留下这些范围：

1. ASCII 可打印字符与 Latin-1。
2. 常用标点、箭头、数学符号、几何图形、盲文点阵。
   打样的图标用几何图形与盲文点阵拼，见 WorkbenchShell.kt。
3. CJK 标点与全角形式。
4. GB2312 的全部汉字与符号。6763 个汉字，覆盖通用界面文案。

裁完约 2 MB。加文案时如果出现豆腐块，说明用到了 GB2312 之外的字，
把那个字加进 EXTRA_CHARS 再跑一次本脚本。

依赖 fontTools：

```bash
python3 -m venv /tmp/fontenv && /tmp/fontenv/bin/pip install fonttools brotli
```
"""

import sys

# GB2312 之外还要留的字。出现豆腐块时往这里加。
EXTRA_CHARS = ""

# 按码位保留的范围。
RANGES = [
    (0x0020, 0x007E),  # ASCII 可打印
    (0x00A0, 0x00FF),  # Latin-1 补充
    (0x2010, 0x203B),  # 连字符、引号、省略号、破折号
    (0x2044, 0x2044),  # 分数斜线
    (0x2070, 0x2079),  # 上标数字
    (0x20A0, 0x20BF),  # 货币符号
    (0x2100, 0x214F),  # 字母式符号
    (0x2190, 0x21FF),  # 箭头
    (0x2200, 0x22FF),  # 数学运算符
    (0x2460, 0x24FF),  # 带圈字母数字
    (0x2500, 0x257F),  # 制表符
    (0x25A0, 0x25FF),  # 几何图形
    (0x2600, 0x26FF),  # 杂项符号
    (0x2700, 0x27BF),  # 装饰符号
    (0x2800, 0x28FF),  # 盲文点阵
    (0x3000, 0x303F),  # CJK 标点
    (0xFF00, 0xFFEF),  # 全角与半角形式
]


def gb2312_chars() -> str:
    """GB2312 的全部字符：两级汉字加上符号区。"""
    out = []
    for hi in range(0xA1, 0xF8):
        for lo in range(0xA1, 0xFF):
            try:
                out.append(bytes([hi, lo]).decode("gb2312"))
            except UnicodeDecodeError:
                pass
    return "".join(out)


def codepoints() -> list[int]:
    points = set()
    for start, end in RANGES:
        points.update(range(start, end + 1))
    points.update(ord(c) for c in gb2312_chars())
    points.update(ord(c) for c in EXTRA_CHARS)
    return sorted(p for p in points if p > 0x1F)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2

    from fontTools import subset

    points = codepoints()
    print(f"保留 {len(points)} 个码位")

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    options.recalc_bounds = True
    options.drop_tables = ["DSIG"]

    font = subset.load_font(sys.argv[1], options)
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=points)
    subsetter.subset(font)
    subset.save_font(font, sys.argv[2], options)
    font.close()

    import os

    print(f"写出 {sys.argv[2]}，{os.path.getsize(sys.argv[2])} 字节")
    return 0


if __name__ == "__main__":
    sys.exit(main())
