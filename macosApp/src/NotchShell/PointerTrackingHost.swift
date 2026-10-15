import AppKit
import SwiftUI

/// 把 SwiftUI 内容装进窗口，并报告指针进出。
///
/// 为什么不用全局鼠标监听：M0 实测在 `AXIsProcessTrusted = false` 时
/// `NSEvent.addGlobalMonitorForEvents` 仍然返回非 nil 的 token。
/// 注册成功不能作为拿到权限的依据。窗口自己的 tracking area 不依赖辅助功能权限。
/// 见 `docs/adr/adr-0001-macos-ui-swiftui.md` 实测 10。
@MainActor
final class PointerTrackingHost<Content: View>: NSView {
    var onPointerEnter: (() -> Void)?
    var onPointerExit: (() -> Void)?

    let hosting: NSHostingView<Content>
    private var pointerArea: NSTrackingArea?

    init(rootView: Content) {
        self.hosting = NSHostingView(rootView: rootView)
        super.init(frame: .zero)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.topAnchor.constraint(equalTo: topAnchor),
            hosting.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PointerTrackingHost 只支持代码创建")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let pointerArea {
            removeTrackingArea(pointerArea)
        }
        // .inVisibleRect 让 tracking area 跟随窗口尺寸变化，不用手工重算。
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        pointerArea = area
    }

    /// 跟踪区的 owner 是 `self`，事件就送到这两个方法。
    ///
    /// 不写这两个覆写的话，`NSView` 的默认实现只是把事件往下一环传，
    /// `onPointerEnter` 与 `onPointerExit` 永远不会被调用：
    /// 热区收不到进入，悬停刘海打不开挂帘（需求 R2）。
    override func mouseEntered(with event: NSEvent) {
        onPointerEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        onPointerExit?()
    }
}
