import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

/// 粘贴回填：把条目写回系统剪贴板，再朝前台应用合成一次 ⌘V。
///
/// **必须在显示 Hub 之前抓住前台应用。** 计划把这条列成警告：
/// Hub 面板一旦激活就把前台应用换成了 Covio，⌘V 就没有收件人了。
/// 本版 Hub 用的是非激活面板（`ShellPanels.swift` 的 `styleMask` 里有
/// `.nonactivatingPanel`），所以前台应用不会变。这里再加一层保险：
/// 记住最后一个「不是 Covio」的前台应用，粘贴时优先用它。
///
/// 合成按键要辅助功能权限。没有权限时 [paste] 返回 false，
/// 界面据此引导用户去系统设置，而不是静默失败。
enum ClipboardPaste {
    /// 合成一次 ⌘V，发给指定进程。
    ///
    /// 用 `postToPid` 而不是 `post(tap:)`：前者把事件直接投给目标进程，
    /// 不依赖谁在最前面，也就不会因为 Hub 一闪而发错人。
    @discardableResult
    static func paste(into pid: pid_t) -> Bool {
        guard AXIsProcessTrusted() else { return false }
        return synthesize(keyCode: UInt16(kVK_ANSI_V), into: pid)
    }

    /// 辅助功能权限是否已给。
    static var hasAccessibilityPermission: Bool { AXIsProcessTrusted() }

    /// 合成一次 ⌘C，让前台应用把它自己的选中内容放进剪贴板。
    ///
    /// 本应用不直接读别人的选中内容：那同样要辅助功能权限，
    /// 而且拿到的是一份拷贝。让应用自己复制，随后监视器会收到它。
    @discardableResult
    static func copySelection(in pid: pid_t) -> Bool {
        guard AXIsProcessTrusted() else { return false }
        return synthesize(keyCode: UInt16(kVK_ANSI_C), into: pid)
    }

    /// 合成一次带 ⌘ 的按键，发给指定进程。
    private static func synthesize(keyCode: UInt16, into pid: pid_t) -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return false }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.postToPid(pid)
        up.postToPid(pid)
        return true
    }

    /// 弹出系统的授权引导。
    ///
    /// 只弹一次由系统管：带 prompt 键调用时，系统只在用户还没回应过时弹窗。
    static func requestAccessibilityPermission() {
        _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    /// `kAXTrustedCheckOptionPrompt` 的字面量。
    ///
    /// 不直接用那个常量：Swift 6 把它当成共享可变全局变量，引用会报错。
    /// 它在 `AXUIElement.h` 里导成 `var`，值本身是稳定的。
    private static let promptKey = "AXTrustedCheckOptionPrompt"

    /// 打开「隐私与安全性 → 辅助功能」。
    static func openAccessibilitySettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}
