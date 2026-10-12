import AppKit
import SwiftUI
import kmpDomain

/// 拖拽与窗口动画的原生部分。
///
/// 对应 Compose 版依赖的 `native/CovioDrag.m`。那一份通过 JNA 调用，
/// 需要随包发一个 `libCovioDrag.dylib`。这里直接用 Swift 写，
/// 不再需要动态库，也不再需要 JNA。
///
/// 三件事：把卡片拖出去、让图片从鼠标位置飞到工具栏、打开系统标记工具。
///
/// 全部在主线程跑：拖拽会话、窗口动画、共享服务都只能在主线程碰。
@MainActor
enum ShelfNative {
    /// 拖拽时跟着鼠标的那张缩略图尺寸。
    ///
    /// 长边不超过 150 × 158，短边不小于 36。读不出图片尺寸时用整个上限。
    /// 数值来自 `CovioDrag.m` 的 `CovioImageSize`。
    static func dragThumbnailSize(for image: NSImage?) -> NSSize {
        let fallback = NSSize(width: 150, height: 158)
        guard let image, image.size.width > 0, image.size.height > 0 else { return fallback }
        let scale = min(150 / image.size.width, 158 / image.size.height)
        return NSSize(
            width: max(36, image.size.width * scale),
            height: max(36, image.size.height * scale)
        )
    }

    /// 开始一次文件拖拽。
    ///
    /// 拖到应用外面时，落点可以要求复制、移动或删除。
    /// 落点要求删除时先把文件放进废纸篓，然后把操作结果回调出去。
    ///
    /// - Parameters:
    ///   - view: 发起拖拽的视图。原生拖拽会话由它开始。
    ///   - fileURL: 要拖的文件。
    ///   - event: 触发这次拖拽的鼠标事件。
    ///   - completion: 拖拽结束时回调。参数是 `NSDragOperation` 的位掩码。
    @discardableResult
    static func startFileDrag(
        from view: NSView,
        fileURL: URL,
        event: NSEvent,
        completion: @escaping (UInt64) -> Void
    ) -> Bool {
        guard view.window != nil, let image = dragImage(for: fileURL) else {
            completion(0)
            return false
        }

        let source = ShelfDraggingSource(fileURL: fileURL) { mask in
            // 会话结束后就不必再保住委托了。
            releaseSource(for: view)
            completion(mask)
        }
        retain(source, for: view)

        let item = NSDraggingItem(pasteboardWriter: fileURL as NSURL)

        // 拖拽起点是鼠标当前位置。`NSEvent.mouseLocation` 是屏幕坐标。
        let mouse = NSEvent.mouseLocation
        let size = dragThumbnailSize(for: image)
        let frame = NSRect(
            x: mouse.x - size.width / 2,
            y: mouse.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        item.setDraggingFrame(frame, contents: image)

        let session = view.beginDraggingSession(with: [item], event: event, source: source)
        // 取消或失败时让缩略图滑回原处，这样用户知道拖拽没生效。
        session.animatesToStartingPositionsOnCancelOrFail = true
        return true
    }

    /// 会话期间保住委托。
    ///
    /// `beginDraggingSession` 不持有委托，委托被释放就收不到结束回调，
    /// 卡片会一直停在拖拽态。所以按发起拖拽的视图存一份，结束时删掉。
    private static func retain(_ source: ShelfDraggingSource, for view: NSView) {
        sourceLock.lock()
        draggingSources[ObjectIdentifier(view)] = source
        sourceLock.unlock()
    }

    private static func releaseSource(for view: NSView) {
        sourceLock.lock()
        draggingSources[ObjectIdentifier(view)] = nil
        sourceLock.unlock()
    }

    private static let sourceLock = NSLock()

    /// 两个静态成员都由 `sourceLock` 保护，但 Swift 看不出来。
    /// 拖拽会话在拖拽开始与结束都发生在主线程。
    private nonisolated(unsafe) static var draggingSources: [ObjectIdentifier: ShelfDraggingSource] = [:]

    /// 一张截图飞进工具栏，或者没拖成时飞回原处。
    ///
    /// 对应 `CovioDrag.m` 的 `CVStartFlight`。时长 0.65 秒，与产品文档第 6.4 节
    /// 的「截图捕获 650 毫秒」一致。缓动是 `1 - (1 - t)^3`。
    ///
    /// - Parameters:
    ///   - fileURL: 要飞的图片。
    ///   - targetWindow: 目标窗口，也就是工具栏面板。
    ///   - returning: 真表示拖拽失败，飞回工具栏；假表示新截图飞进工具栏。
    static func animateImage(
        fileURL: URL,
        to targetWindow: NSWindow?,
        returning: Bool
    ) {
        guard let targetWindow, let image = NSImage(contentsOf: fileURL) else { return }

        let size = dragThumbnailSize(for: image)
        let mouse = NSEvent.mouseLocation
        let initialFrame = NSRect(
            x: mouse.x - size.width / 2,
            y: mouse.y - size.height / 2,
            width: size.width,
            height: size.height
        )

        let panel = NSPanel(
            contentRect: initialFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isReleasedWhenClosed = false

        let imageView = NSImageView(frame: NSRect(origin: .zero, size: size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 10
        imageView.layer?.masksToBounds = true
        panel.contentView = imageView
        panel.orderFrontRegardless()

        let windowFrame = targetWindow.frame
        let target = NSPoint(x: windowFrame.midX, y: windowFrame.maxY - 58)
        let start = NSPoint(x: initialFrame.midX, y: initialFrame.midY)
        // 动画状态放在一个主 actor 对象上。计时器的闭包是 `@Sendable`，
        // 既改不了局部 `var`，也不能把非 Sendable 的 `Timer` 带进去。
        // 让对象自己收着计时器，闭包里只留一个 Sendable 的 `self`。
        let flight = FlightAnimation(
            panel: panel,
            origin: start,
            target: target,
            lift: returning ? 8 : 34,
            returning: returning,
            size: size
        )
        flight.begin()
    }

    /// 用系统标记工具打开一张截图。
    ///
    /// 标记工具不可用时返回假，调用方据此退回预览。
    /// README 第 76 行要求「标记不可用时打开预览」。
    @MainActor
    static func openMarkup(fileURL: URL) -> Bool {
        let name = NSSharingService.Name("com.apple.MarkupUI.Markup")
        guard let service = NSSharingService(named: name),
              service.canPerform(withItems: [fileURL])
        else { return false }
        service.perform(withItems: [fileURL])
        return true
    }

    /// 读缩略图。读不出时用应用图标，与 `CovioDrag.m` 一致。
    private static func dragImage(for fileURL: URL) -> NSImage? {
        NSImage(contentsOf: fileURL) ?? NSImage(named: NSImage.applicationIconName)
    }
}

/// 拖拽会话的委托。
///
/// 对应 `CovioDrag.m` 的 `CovioDragSource`。
/// 拖到应用外面时允许复制、移动、删除三种落点；拖回应用内部不接受。
/// 落点是废纸篓时，系统给出删除操作，这里先把文件真的放进废纸篓。
final class ShelfDraggingSource: NSObject, NSDraggingSource {
    private let fileURL: URL
    private let completion: (UInt64) -> Void
    private var completed = false

    init(fileURL: URL, completion: @escaping (UInt64) -> Void) {
        self.fileURL = fileURL
        self.completion = completion
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        guard context == .outsideApplication else { return [] }
        return [.copy, .move, .delete]
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        // 结束回调可能来两次，只认第一次。
        guard !completed else { return }
        completed = true

        if operation.contains(.delete) {
            try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
        }
        completion(UInt64(operation.rawValue))
    }
}

/// 落点的判定。
///
/// 把系统的拖拽操作掩码翻成 `kmpDomain` 的 `ShelfDragResult`，
/// 再把结果翻成要执行的文件操作。两个映射都在 `kmpDomain` 里，与 Compose 版共用。
enum ShelfDropResolver {
    /// 拖拽结束后该做什么。
    static func result(forOperationMask mask: UInt64) -> ShelfDragResult {
        ShelfLogicKt.shelfDragResultFor(operationMask: Int64(mask))
    }

    /// 落点类型对应的文件操作。
    static func action(forTarget target: ShelfDropTarget) -> ShelfDropAction {
        ShelfLogicKt.dropActionFor(target: target)
    }
}

/// 卡片上的鼠标交互。
///
/// 对应 Compose 版挂在卡片上的那一串 `onPointerEvent` 与 `detectDragGestures`。
/// SwiftUI 的手势识别在这里不够用：拖拽要交给 AppKit 才开始得了原生拖拽会话，
/// 长按要自己计时，右键要弹原生菜单。所以这一层直接用 `NSView`。
struct CardInteractionView: NSViewRepresentable {
    let onPress: (Bool) -> Void
    let onHover: (Bool) -> Void
    let onClick: () -> Void
    let onDoubleClick: () -> Void
    let onLongPress: () -> Void
    let onDragBegin: (NSView, NSEvent) -> Void
    /// 右键菜单。每次右键时现取一份，所以菜单项的文字能跟着语言变。
    let menuProvider: () -> NSMenu

    func makeNSView(context: Context) -> InteractionView {
        let view = InteractionView()
        apply(to: view)
        return view
    }

    func updateNSView(_ view: InteractionView, context: Context) {
        apply(to: view)
    }

    private func apply(to view: InteractionView) {
        view.onPress = onPress
        view.onHover = onHover
        view.onClick = onClick
        view.onDoubleClick = onDoubleClick
        view.onLongPress = onLongPress
        view.onDragBegin = onDragBegin
        view.menuProvider = menuProvider
    }

    /// 交互视图本体。
    ///
    /// 长按与拖拽的分界是 `NSEvent.draggingThreshold`：鼠标移动超过这个距离
    /// 就算拖拽，停住不动到 `longPressSeconds` 就算长按。
    final class InteractionView: NSView {
        /// 按住多久算长按。Compose 版用系统默认的长按时间，约半秒。
        static let longPressSeconds: TimeInterval = 0.45

        var onPress: ((Bool) -> Void)?
        var onHover: ((Bool) -> Void)?
        var onClick: (() -> Void)?
        var onDoubleClick: (() -> Void)?
        var onLongPress: (() -> Void)?
        var onDragBegin: ((NSView, NSEvent) -> Void)?
        var menuProvider: (() -> NSMenu)?

        private var trackingArea: NSTrackingArea?
        private var longPressTimer: Timer?
        private var pressEvent: NSEvent?
        private var longPressFired = false
        private var dragging = false

        override var acceptsFirstResponder: Bool { false }

        /// 只处理鼠标按下与拖动，其余交给 SwiftUI。
        ///
        /// 返回真表示这一层吃掉了事件。空白处返回假，让菜单之类的上层还能收到。
        override func hitTest(_ point: NSPoint) -> NSView? {
            bounds.contains(convert(point, from: superview)) ? self : nil
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let trackingArea { removeTrackingArea(trackingArea) }
            let area = NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self
            )
            addTrackingArea(area)
            trackingArea = area
        }

        override func mouseEntered(with event: NSEvent) {
            onHover?(true)
        }

        override func mouseExited(with event: NSEvent) {
            onHover?(false)
        }

        override func mouseDown(with event: NSEvent) {
            longPressFired = false
            dragging = false
            pressEvent = event
            onPress?(true)

            longPressTimer?.invalidate()
            longPressTimer = Timer(timeInterval: Self.longPressSeconds, repeats: false) { [weak self] _ in
                // 计时器挂在主运行循环上，所以一定在主线程。
                // 不写这一句，下面的主 actor 属性就落在非隔离上下文里。
                MainActor.assumeIsolated {
                    guard let self, !self.dragging else { return }
                    self.longPressFired = true
                    self.onPress?(false)
                    self.onLongPress?()
                }
            }
            RunLoop.main.add(longPressTimer!, forMode: .common)
        }

        override func mouseUp(with event: NSEvent) {
            longPressTimer?.invalidate()
            longPressTimer = nil
            defer { pressEvent = nil }

            guard !dragging else {
                dragging = false
                return
            }
            onPress?(false)
            // 长按已经处理过这次按下，松开时不再算点击。
            guard !longPressFired else {
                longPressFired = false
                return
            }
            if event.clickCount >= 2 {
                onDoubleClick?()
            } else {
                onClick?()
            }
        }

        override func mouseDragged(with event: NSEvent) {
            guard !dragging, !longPressFired, let start = pressEvent else { return }
            // 位移超过系统阈值才算拖拽，否则只是手抖。
            let dx = event.locationInWindow.x - start.locationInWindow.x
            let dy = event.locationInWindow.y - start.locationInWindow.y
            guard dx * dx + dy * dy >= 9 else { return }

            dragging = true
            longPressTimer?.invalidate()
            longPressTimer = nil
            onPress?(false)
            onDragBegin?(self, event)
        }

        override func rightMouseDown(with event: NSEvent) {
            guard let menu = menuProvider?() else { return }
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }
}

/// 一张飞进或飞回工具栏的截图。
///
/// 自己收着计时器与已播时长。计时器的闭包只捕获这个对象，
/// 不捕获 `Timer` 本身，也不改局部变量。
@MainActor
private final class FlightAnimation {
    private let panel: NSPanel
    private let origin: NSPoint
    private let target: NSPoint
    private let lift: CGFloat
    private let returning: Bool
    private let size: CGSize

    private var timer: Timer?
    private var elapsed: TimeInterval = 0

    /// 一帧的时长。60 帧每秒。
    private static let step = 1.0 / 60.0

    init(panel: NSPanel, origin: NSPoint, target: NSPoint, lift: CGFloat, returning: Bool, size: CGSize) {
        self.panel = panel
        self.origin = origin
        self.target = target
        self.lift = lift
        self.returning = returning
        self.size = size
    }

    /// 开始播放。每帧推进一次，到点自己收尾。
    func begin() {
        let timer = Timer(timeInterval: Self.step, repeats: true) { [weak self] _ in
            // 计时器挂在主运行循环上，所以一定在主线程。
            MainActor.assumeIsolated { self?.advance() }
        }
        // 用 common modes，这样拖拽或滚动时动画也不会停。
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func advance() {
        elapsed += Self.step
        let raw = CGFloat(min(1, elapsed / ShelfMotionSpec.flyInSeconds))
        let eased = 1 - pow(1 - raw, 3)
        // 抛物线的顶点在中间，所以乘 4 * raw * (1 - raw)。
        let arc = lift * 4 * raw * (1 - raw)
        let x = origin.x + (target.x - origin.x) * eased
        let y = origin.y + (target.y - origin.y) * eased + arc
        panel.setFrameOrigin(NSPoint(x: x - size.width / 2, y: y - size.height / 2))
        panel.alphaValue = returning ? 1 - 0.65 * raw : min(1, 0.25 + raw * 0.75)

        guard raw >= 1 else { return }
        timer?.invalidate()
        timer = nil
        panel.orderOut(nil)
        panel.alphaValue = 1
    }
}
