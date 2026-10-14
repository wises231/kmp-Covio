import AppKit

/// 无边框浮层面板的共同配置。
///
/// 设置顺序有硬性要求。`isFloatingPanel = true` 会把 `level` 重置为 `.floating`（3）。
/// M0 实测：
///
/// | 顺序 | 读回的 `level.rawValue` |
/// | --- | --- |
/// | 先 `isFloatingPanel`，再 `level` | 25 |
/// | 先 `level`，再 `isFloatingPanel` | 3 |
///
/// 见 `doc/adr/adr-0001-macos-ui-swiftui.md` 实测 9。
/// 现有 Compose 版的 `FLOATING_WINDOW_LEVEL = 3` 就是踩了这个坑。
@MainActor
class ShellPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // 顺序不能换。先 isFloatingPanel，再 level。
        isFloatingPanel = true
        level = .statusBar

        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        // 编辑输入或拖动文件时 Hub 不自动收起。
        hidesOnDeactivate = false
        isMovable = false
        isMovableByWindowBackground = false
        // 阴影要轻量。窗口阴影关掉，改由 SwiftUI 侧画，控制更直接。
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        animationBehavior = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ShellPanel 只支持代码创建")
    }

    override var canBecomeMain: Bool { false }
}

/// 顶部热区面板。每块屏幕一个，常驻。
///
/// 它自己不激活应用、不接受键盘。作用只有一个：报告指针何时进入热区。
@MainActor
final class HotZonePanel: ShellPanel {
    init(rect: CGRect) {
        super.init(contentRect: rect)
        // 热区必须能收到鼠标事件，否则 tracking area 不会触发。
        ignoresMouseEvents = false
    }

    /// 热区面板永远不能成为 key window。它只是触发器。
    override var canBecomeKey: Bool { false }
}

/// Hub 面板。整个进程只有一个。
///
/// `.nonactivatingPanel` 让点击不激活 Covio，`canBecomeKey = true` 让面板能收到键盘。
/// 两者合起来是 M4 粘贴回填需要的行为：Hub 显示后前台应用不改变，但 Escape 仍然可用。
@MainActor
final class HubPanel: ShellPanel {
    /// Escape 的处理。`cancelOperation` 与 `keyDown` 都会走到这里。
    var onCancel: (() -> Void)?

    private static let escapeKeyCode: UInt16 = 53

    init(rect: CGRect) {
        super.init(contentRect: rect)
        ignoresMouseEvents = false
        // 默认值为 true，面板只在有视图需要键盘时才成为 key window。
        // Escape 要立即收起，所以这里关掉这个优化。
        becomesKeyOnlyIfNeeded = false
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == Self.escapeKeyCode {
            onCancel?()
            return
        }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
