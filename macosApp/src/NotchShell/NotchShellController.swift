import AppKit
import SwiftUI

/// Notch Shell 的控制器。
///
/// 职责：
/// - 为每块屏幕维护一个热区面板。
/// - 维护唯一的 Hub 面板，显示时移动到指针所在屏幕。
/// - 驱动 `HubStateMachine`，执行计时与面板显示。
///
/// 状态词汇全部来自设计合同，不造新词。
@MainActor
@Observable
final class NotchShellController {
    /// 面板生命周期状态。来源是合同 `states.menuBarAndNotchHub.hubStates`。
    private(set) var state: HubState = .hidden
    /// 内容区状态。来源是合同 `states.notchOutputHub.states`。P1 固定为 collapsed。
    private(set) var outputState: HubOutputState = .collapsed
    /// 当前页签。设置页比占位页高，所以换页签要重排面板。
    var selection: HubTab = .now {
        didSet {
            guard selection != oldValue else { return }
            refreshLayout()
        }
    }

    /// Hub 外壳的共享状态。搜索文字与设置分节住在这里。
    ///
    /// 由控制器持有，所以面板收起再展开时搜索文字与分节不丢。
    let chrome = HubChromeModel()

    /// 当前页签需要的内容高度。
    private var contentHeight: CGFloat { HubMetrics.contentHeight(for: selection) }
    /// 当前面板所在的屏幕几何。
    private(set) var geometry: ScreenGeometry?
    /// 系统是否要求减弱动态效果。
    private(set) var reduceMotion = false

    private var machine = HubStateMachine()
    private var hotZonePanels: [HotZonePanel] = []
    private var hubPanel: HubPanel?
    private var expandTimer: Timer?
    private var collapseTimer: Timer?
    private var observers: [NSObjectProtocol] = []
    private let pointerLocation: @MainActor () -> CGPoint

    /// 运行时。Hub 的设置页读它。测试与预览里可以是 nil，那时设置页显示占位。
    var runtime: AppRuntime?

    /// `pointerLocation` 是唯一为了测试留的接缝。默认读真实指针位置。
    /// 测试注入固定坐标，就不必真的移动用户的鼠标。
    init(pointerLocation: @escaping @MainActor () -> CGPoint = { NSEvent.mouseLocation }) {
        self.pointerLocation = pointerLocation
    }

    /// 面板是否处于展开态。视图用它驱动窗帘动画。
    var isExpanded: Bool { state != .hidden && state != .exit }

    // MARK: - 只读状态。供测试与手工验证使用。

    /// 每块屏幕一个热区面板的矩形。
    var hotZoneRects: [CGRect] { hotZonePanels.map(\.frame) }

    /// Hub 面板当前是否在屏幕上。
    var isHubPanelOnScreen: Bool { hubPanel?.isVisible ?? false }

    /// Hub 面板当前的矩形。
    var hubPanelFrame: CGRect? { hubPanel?.frame }

    /// 菜单栏当前是否可见。全屏 Space 里为 false，此时热区隐藏。
    var isHotZoneEnabled: Bool { geometry?.isMenuBarVisible ?? true }

    // MARK: - 生命周期

    func start() {
        reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        makeHubPanel()
        rebuildHotZones()
        observeSystemChanges()
        applyVisibility()
    }

    func stop() {
        cancelTimers()
        let center = NSWorkspace.shared.notificationCenter
        observers.forEach { center.removeObserver($0) }
        observers.removeAll()
        hotZonePanels.forEach { $0.orderOut(nil) }
        hotZonePanels.removeAll()
        hubPanel?.orderOut(nil)
        hubPanel = nil
    }

    // MARK: - 外部入口

    /// `Control+Option+T` 与菜单栏菜单都走这里。Hub 打开时收起，否则打开。
    func toggle() {
        if state == .hidden || state == .exit {
            show()
        } else {
            requestCollapse()
        }
    }

    func show() {
        guard state == .hidden || state == .exit else {
            // 已经打开。刷新几何，指针可能换了屏幕。
            if state != .exit { relocateIfNeeded() }
            return
        }
        send(.pointerEnteredHotZone)
    }

    func requestCollapse() {
        send(.collapseRequested)
    }

    // MARK: - 状态机

    private func send(_ event: HubEvent) {
        guard machine.canHandle(event) else { return }
        let previous = machine.state
        machine.handle(event)
        state = machine.state
        react(to: event, from: previous)
        applyVisibility()
    }

    private func react(to event: HubEvent, from previous: HubState) {
        // 目标状态自身的副作用。收起动画从进入 .exit 开始计时。
        if state == .exit, previous != .exit {
            beginCollapse()
        }

        switch event {
        case .pointerEnteredHotZone:
            // 必须先取消旧的计时，再展开。展开过程中可能因为指针不在面板里
            // 立刻又启动收起计时，那个计时不能被这里清掉。
            cancelCollapseTimer()
            if state == .hover { presentHub() }

        case .pointerEnteredHub:
            // 指针进入面板。取消待收起计时，内容区进入就绪。
            cancelCollapseTimer()
            if state == .active, outputState == .collapsed {
                outputState = .ready
            }

        case .pointerExitedHub:
            guard state != .exit else { break }
            outputState = .collapsed
            startCollapseTimer()

        case .expandFinished:
            // 展开结束时指针可能已经在面板里。
            if state == .open, pointerIsInsideHubPanel {
                send(.pointerEnteredHub)
            }

        case .collapseRequested:
            // 只取消展开计时。收起计时是上面 beginCollapse() 刚启动的，不能动。
            cancelExpandTimer()
            outputState = .collapsed

        case .collapseFinished:
            outputState = .collapsed

        case .failureRaised:
            cancelCollapseTimer()
            outputState = .error

        case .failureCleared:
            outputState = .ready

        case .pointerExitedHotZone:
            break
        }
    }

    // MARK: - 面板动作

    private func presentHub() {
        guard let hubPanel else { return }
        guard let geometry = ScreenGeometry.current(location: pointerLocation()) else { return }
        self.geometry = geometry

        hubPanel.setFrame(geometry.expandedRect(contentHeight: contentHeight), display: true)
        hubPanel.orderFrontRegardless()
        hubPanel.makeKey()
        if let host = hubPanel.contentView {
            hubPanel.makeFirstResponder(host)
        }

        cancelExpandTimer()
        let duration = HubMotion.expandDuration(reduceMotion: reduceMotion)
        expandTimer = schedule(after: duration) { [weak self] in
            self?.send(.expandFinished)
        }

        // 面板出现时指针可能已经在外面。tracking area 的 mouseEntered 要等下一次鼠标移动，
        // 所以在建立面板后主动查一次真实指针位置，避免 Hub 卡在展开态。
        if !pointerIsInsideHubPanel {
            send(.pointerExitedHub)
        }
    }

    private func beginCollapse() {
        cancelExpandTimer()
        let duration = HubMotion.collapseDuration(reduceMotion: reduceMotion)
        collapseTimer = schedule(after: duration) { [weak self] in
            self?.send(.collapseFinished)
        }
    }

    /// 状态变化后同步窗口的可见性。
    ///
    /// 热区面板可见当且仅当 Hub 收起。这样两个面板不会互相遮挡，
    /// 也不会出现热区的 `mouseExited` 把刚展开的 Hub 关掉。
    private func applyVisibility() {
        let hubVisible = state.isPanelVisible
        for panel in hotZonePanels {
            let shouldShow = !hubVisible && (geometryFor(panel)?.isMenuBarVisible ?? false)
            if shouldShow {
                panel.orderFrontRegardless()
            } else {
                panel.orderOut(nil)
            }
        }
        if !hubVisible {
            hubPanel?.orderOut(nil)
        }
    }

    private func relocateIfNeeded() {
        guard let hubPanel, let geometry = ScreenGeometry.current(location: pointerLocation()) else { return }
        guard geometry != self.geometry else { return }
        self.geometry = geometry
        hubPanel.setFrame(geometry.expandedRect(contentHeight: contentHeight), display: true)
    }

    private var pointerIsInsideHubPanel: Bool {
        guard let hubPanel else { return false }
        return hubPanel.frame.contains(pointerLocation())
    }

    // MARK: - 计时

    private func schedule(after delay: TimeInterval, _ body: @escaping @MainActor () -> Void) -> Timer {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            MainActor.assumeIsolated { body() }
        }
    }

    private func startCollapseTimer() {
        cancelCollapseTimer()
        collapseTimer = schedule(after: HubMotion.pointerExitCollapseDelay) { [weak self] in
            self?.send(.collapseRequested)
        }
    }

    private func cancelExpandTimer() {
        expandTimer?.invalidate()
        expandTimer = nil
    }

    private func cancelCollapseTimer() {
        collapseTimer?.invalidate()
        collapseTimer = nil
    }

    private func cancelTimers() {
        cancelExpandTimer()
        cancelCollapseTimer()
    }

    // MARK: - 面板与屏幕

    private func makeHubPanel() {
        let initial = ScreenGeometry.current(location: pointerLocation())?
            .expandedRect(contentHeight: contentHeight)
            ?? CGRect(x: 0, y: 0, width: HubMetrics.cardWidth, height: contentHeight)
        let panel = HubPanel(rect: initial)

        let host = PointerTrackingHost(rootView: hubContentView())
        host.onPointerEnter = { [weak self] in self?.send(.pointerEnteredHub) }
        host.onPointerExit = { [weak self] in self?.send(.pointerExitedHub) }
        panel.contentView = host
        // Escape 先清搜索：用户在搜索时按 Escape 想关掉结果，不是收起整个面板。
        panel.onCancel = { [weak self] in
            guard let self else { return }
            if self.chrome.searchText.isEmpty {
                self.requestCollapse()
            } else {
                self.chrome.clearSearch()
            }
        }


        hubPanel = panel
    }

    private func hubContentView() -> some View {
        // 面板尺寸固定，内容只改高度。这里用一个稳定的几何快照，
        // 屏幕变化时由 rebuild 重建面板。
        let snapshot = geometry ?? ScreenGeometry.current(location: pointerLocation())
        return HubContentRoot(controller: self, initialGeometry: snapshot, runtime: runtime)
    }

    /// 重建热区面板。显示器变化与全屏 Space 切换时调用。
    private func rebuildHotZones() {
        hotZonePanels.forEach { $0.orderOut(nil) }
        hotZonePanels.removeAll()

        for screen in NSScreen.screens {
            let geometry = ScreenGeometry(screen: screen)
            let panel = HotZonePanel(rect: geometry.hotZoneRect)
            let host = PointerTrackingHost(rootView: Color.clear)
            host.onPointerEnter = { [weak self] in self?.send(.pointerEnteredHotZone) }
            host.onPointerExit = { [weak self] in self?.send(.pointerExitedHotZone) }
            panel.contentView = host
            panel.orderFrontRegardless()
            hotZonePanels.append(panel)
        }
    }

    /// 找回某个热区面板对应的屏幕几何。面板顺序与 `NSScreen.screens` 一致。
    private func geometryFor(_ panel: HotZonePanel) -> ScreenGeometry? {
        guard let index = hotZonePanels.firstIndex(where: { $0 === panel }) else { return nil }
        let screens = NSScreen.screens
        guard index < screens.count else { return nil }
        return ScreenGeometry(screen: screens[index])
    }

    /// 刷新全部几何。显示器配置或菜单栏可见性变化后调用。
    func refreshLayout() {
        geometry = ScreenGeometry.current(location: pointerLocation())
        if state == .hidden {
            rebuildHotZones()
        } else {
            // 展开中换屏：把面板移到新屏幕，热区跟着重建。
            rebuildHotZones()
            if let hubPanel, let geometry {
                hubPanel.setFrame(geometry.expandedRect(contentHeight: contentHeight), display: true)
            }
        }
        applyVisibility()
    }

    private func observeSystemChanges() {
        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshLayout() }
        })
        observers.append(workspace.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshLayout() }
        })
    }
}
