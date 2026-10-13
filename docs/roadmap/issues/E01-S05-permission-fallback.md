---
id: E01-S05
title: "权限降级与触发冲突处理"
labels: [enhancement, phase-1-curtain-core, area/trigger, area/swift]
type: Task
parent: E01
milestone: "P1 · 挂帘内核"
blocked-by: [E01-S01]
---

## 背景

手势与全局事件需要输入监控或辅助功能权限。
本仓库已在 `PointerTrackingHost.swift:6` 记录过教训：
未获授权时 `NSEvent.addGlobalMonitorForEvents` 也返回非空对象，失败是静默的。

剪切板粘贴已有权限处理样例：`macosApp/src/Clipboard/ClipboardPaste.swift:23`。

## 目标

权限被拒时给出明确提示和降级路径。应用的核心功能不依赖任何权限。

## 实施要点

1. 每个触发源声明自己的权限需求。
2. 权限缺失时该触发源标记为不可用，但不影响其他触发源。
3. 在触发设置里显示权限状态和“打开系统设置”入口。
4. 从系统设置返回后重新检查权限，不要求重启应用。
5. 权限被拒时写一条日志。
6. 冲突处理：同一快捷键已被占用时给出“注册失败”提示，与现有剪切板快捷键行为一致。

## 验收标准

1. 拒绝输入监控权限后，快捷键与菜单栏仍能打开挂帘。
2. 设置页显示权限状态与系统设置入口。
3. 授权后无需重启即可生效。
4. 快捷键冲突时界面显示注册失败。
5. 权限检查失败不会静默通过。

## 依赖

`E01-S01`。
