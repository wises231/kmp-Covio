import AppKit
import SwiftUI
import kmpDomain

/// 工具栏面板。
///
/// 与 Hub 面板同为无边框浮层，区别有两点：
/// - 不接受键盘。工具栏里没有输入框，`canBecomeKey` 关掉，点它不抢前台应用的焦点。
/// - 平时鼠标穿透。只有指针落在某张卡片上时才接管点击，这样底下的菜单栏照常可用。
@MainActor
final class ShelfPanel: ShellPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(rect: CGRect) {
        super.init(contentRect: rect)
        ignoresMouseEvents = true
    }
}

/// 工具栏面板的显示、定位与命中判定。
///
/// 只管「面板在哪、显示没有、指针有没有落在卡片上」。
/// 什么时候该显示由 `ShelfRuntime` 决定，这里不判断。
///
/// **与 Compose 版的差别：** Compose 版把面板放在屏幕左上角，
/// 上面 24 点压在菜单栏底下，绳子两端因此被菜单栏挡住。
/// 这里把面板顶边放在菜单栏下沿，菜单栏和绳子都完整可见。
@MainActor
protocol ShelfPresenting: AnyObject {
    /// 面板当前是否在屏幕上。
    var isVisible: Bool { get }
    /// 面板所在的窗口。拖拽失败时的飞回动画要以它为目标。
    var window: NSWindow? { get }

    /// 把面板移到指针所在屏幕并显示。
    func present(reduceMotion: Bool)
    func dismiss()
    /// 开关鼠标穿透。传假表示指针正落在卡片上，面板要接管点击。
    func setPassthrough(_ enabled: Bool)
    /// 指针是否落在某张卡片上。坐标是屏幕坐标。
    func isPointerOverCard(_ point: CGPoint) -> Bool
}

/// 真正建窗口的实现。
@MainActor
final class ShelfPanelController: ShelfPresenting {
    /// 反过来的持有会让两边都活不了。运行时持有面板，所以这里用 `unowned`。
    private unowned let runtime: ShelfRuntime
    private let pointerLocation: () -> CGPoint
    private let language: () -> AppLanguage
    private var panel: ShelfPanel?
    private var host: NSHostingView<ShelfPanelContent>?
    /// 面板当前的矩形。判定卡片命中时要用它换算坐标。
    private var frame: CGRect = .zero

    /// `pointerLocation` 是唯一为测试留的接缝，默认读真实指针位置。
    init(
        runtime: ShelfRuntime,
        pointerLocation: @escaping () -> CGPoint = { NSEvent.mouseLocation },
        language: @escaping () -> AppLanguage
    ) {
        self.runtime = runtime
        self.pointerLocation = pointerLocation
        self.language = language
    }

    var isVisible: Bool { panel?.isVisible ?? false }
    var window: NSWindow? { panel }

    func present(reduceMotion: Bool) {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(pointerLocation()) })
            ?? NSScreen.main
        else { return }
        let geometry = ScreenGeometry(screen: screen)
        let rect = Self.panelRect(geometry: geometry)

        let panel = panel ?? makePanel(rect: rect, reduceMotion: reduceMotion)
        frame = rect
        panel.setFrame(rect, display: true)
        // 内容宽度变了要重建，卡片位置按宽度重算。
        host?.rootView = ShelfPanelContent(
            runtime: runtime,
            containerWidth: rect.width,
            language: language(),
            reduceMotion: reduceMotion
        )
        // `orderFrontRegardless` 不激活 Covio，前台应用不变。
        panel.orderFrontRegardless()
    }

    func dismiss() {
        panel?.orderOut(nil)
    }

    func setPassthrough(_ enabled: Bool) {
        panel?.ignoresMouseEvents = enabled
    }

    func isPointerOverCard(_ point: CGPoint) -> Bool {
        guard let panel, panel.isVisible else { return false }
        let rect = panel.frame
        guard rect.contains(point) else { return false }
        let count = Int32(runtime.items.count)
        guard count > 0 else { return false }
        // 面板坐标：原点在左上角，y 向下。`ShelfLayout` 用的是这一套。
        let index = ShelfLayout.shared.cardIndexAt(
            x: Float(point.x - rect.minX),
            y: Float(rect.maxY - point.y),
            count: count,
            screenWidth: Float(rect.width)
        )
        return index != nil
    }

    /// 面板矩形：指针所在屏幕的整宽，高度是 `ShelfLayout.PANEL_HEIGHT`。
    ///
    /// 顶边贴菜单栏下沿。README 要求工具栏在屏幕顶部，没有要求压住菜单栏。
    static func panelRect(geometry: ScreenGeometry) -> CGRect {
        let height = CGFloat(ShelfLayout.shared.PANEL_HEIGHT)
        return CGRect(
            x: geometry.frame.minX,
            y: geometry.visibleFrame.maxY - height,
            width: geometry.frame.width,
            height: height
        )
    }

    private func makePanel(rect: CGRect, reduceMotion: Bool) -> ShelfPanel {
        let panel = ShelfPanel(rect: rect)
        let host = NSHostingView(
            rootView: ShelfPanelContent(
                runtime: runtime,
                containerWidth: rect.width,
                language: language(),
                reduceMotion: reduceMotion
            )
        )
        // 背景透明，绳子和卡片之间的空隙要让桌面透出来。
        host.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = host
        self.host = host
        self.panel = panel
        return panel
    }
}

/// 面板里装的内容。
///
/// 读 `ShelfRuntime` 的可观察属性，所以卡片增减、飞行状态变化都会自动重画。
struct ShelfPanelContent: View {
    let runtime: ShelfRuntime
    let containerWidth: CGFloat
    let language: AppLanguage
    let reduceMotion: Bool

    var body: some View {
        ClotheslineView(
            items: runtime.items,
            containerWidth: containerWidth,
            reduceMotion: reduceMotion,
            language: language,
            flyingPath: runtime.flyingPath,
            onCopy: { runtime.copyItem($0) },
            onPreview: { runtime.openItem($0) },
            onMarkup: { runtime.markupItem($0) },
            onRemove: { runtime.removeItem($0) },
            onDragBegin: { item, view, event in
                runtime.beginDrag(item: item, from: view, event: event)
            },
            onPointerInside: { runtime.setPointerInsideContent($0) }
        )
    }
}
