import AppKit
import SwiftUI

/// 菜单栏上的品牌胶囊窗口。
///
/// macOS 的状态项位置由系统排，居中不了，刘海区也放不下。所以自己画一个：
/// 一个无边框浮层窗口，`level = .statusBar`，只包住胶囊加一圈悬停余量。
///
/// **窗口只包住胶囊。** 铺满菜单栏会挡住系统菜单项与其它应用的状态项。
/// 所以这里按胶囊的实测宽度开窗，宽度取 `fittingSize`，不写死。
///
/// 它自己不接受键盘。作用有两个：报告指针进入，以及响应点击。
@MainActor
final class MenuBarCapsulePanel: ShellPanel {
    /// 指针进入胶囊。与热区同一个事件，都让挂帘展开。
    var onPointerEnter: (() -> Void)?
    /// 指针离开。用于收起悬停态。
    var onPointerExit: (() -> Void)?
    /// 点击胶囊。挂帘打开时收起，否则打开。
    var onClick: (() -> Void)?

    private let host: CapsuleHostingView
    /// 胶囊本身的尺寸，不含悬停余量。
    private(set) var capsuleSize: CGSize

    init() {
        let host = CapsuleHostingView(rootView: MenuBarCapsule(isHovered: false))
        // 宽度按实测取，不写死：胶囊里的字随语言变。
        // 实测为 0 时（视图还没上屏）回落到一个够放得下胶囊的宽度。
        let measured = host.fittingSize
        let size = CGSize(
            width: max(measured.width, Self.minimumCapsuleWidth),
            height: max(measured.height, HubMetrics.menuBarCapsuleHeight)
        )
        self.host = host
        self.capsuleSize = size
        super.init(contentRect: Self.windowRect(for: size, on: nil))

        ignoresMouseEvents = false
        contentView = host
        host.onPointerEnter = { [weak self] in self?.onPointerEnter?() }
        host.onPointerExit = { [weak self] in self?.onPointerExit?() }
        host.onClick = { [weak self] in self?.onClick?() }
    }

    /// 实测失败时的兜底宽度。「◈ Covio」加两边内边距大约 60 点，留一点余量。
    ///
    /// 窗口比胶囊宽没有代价：胶囊在窗口里居中，底色只包住内容。
    private static let minimumCapsuleWidth: CGFloat = 72

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("MenuBarCapsulePanel 只支持代码创建")
    }

    /// 胶囊不接受键盘，也不该抢走 Hub 的 key 状态。
    override var canBecomeKey: Bool { false }

    /// 换悬停态。悬停只改底色，不改尺寸。
    func setHovered(_ hovered: Bool) {
        host.rootView = MenuBarCapsule(isHovered: hovered)
    }

    /// 把窗口挪到某块屏幕的菜单栏上。显示器变化与菜单栏显隐变化时调用。
    func place(on geometry: ScreenGeometry) {
        let rect = Self.windowRect(for: capsuleSize, on: geometry)
        setFrame(rect, display: true)
    }

    /// 窗口矩形：胶囊矩形四周各外扩 `menuBarCapsuleHoverInset` 点。
    static func windowRect(for capsule: CGSize, on geometry: ScreenGeometry?) -> CGRect {
        let inset = HubMetrics.menuBarCapsuleHoverInset
        guard let geometry else {
            return CGRect(origin: .zero, size: capsule).insetBy(dx: -inset, dy: -inset)
        }
        return geometry
            .menuBarCapsuleRect(capsuleWidth: capsule.width, capsuleHeight: capsule.height)
            .insetBy(dx: -inset, dy: -inset)
    }
}

/// 胶囊的宿主视图。在跟踪区之外再补一层鼠标事件。
///
/// `NSPanel` 的 `mouseEntered` 要等指针动一次才来，而菜单栏那一条很薄，
/// 指针可能停进去就不再动。所以这里同时用 tracking area 与 `mouseMoved`。
@MainActor
private final class CapsuleHostingView: NSHostingView<MenuBarCapsule> {
    var onPointerEnter: (() -> Void)?
    var onPointerExit: (() -> Void)?
    var onClick: (() -> Void)?

    private var trackingArea: NSTrackingArea?

    /// 菜单栏那一条很薄，指针往往是从别的应用切过来时直接落上去的。
    /// 不接受「第一次点击」的话，用户得先点一下再点一下。
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onPointerEnter?()
    }

    override func mouseExited(with event: NSEvent) {
        onPointerExit?()
    }

    override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        onClick?()
    }
}
