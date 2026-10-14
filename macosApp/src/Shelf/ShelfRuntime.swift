import AppKit
import Foundation
import kmpDomain

/// 晾衣线运行时读外部世界的入口。
///
/// 全部收成一个值，构造 `ShelfRuntime` 时传一次。
/// 测试可以整体换掉，不必真的读配置、动指针、等真实时间。
@MainActor
struct ShelfEnvironment {
    /// 配置里的晾衣线开关。关掉时面板不显示，监视器也停。
    var isShelfEnabled: () -> Bool = { false }
    /// 配置里的截图接管开关。
    var isTakeoverEnabled: () -> Bool = { false }
    /// 配置里的提示音开关。
    var isSoundsEnabled: () -> Bool = { false }
    /// 当前 Space 是不是全屏。全屏时 §4.4 要求工具栏让位。
    var isFullScreenSpaceActive: () -> Bool = { FullScreenSpaceDetector.isActive() }
    /// 系统是否要求减弱动态效果。
    var reduceMotion: () -> Bool = { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    var language: () -> AppLanguage = { AppLanguage.fromCode(nil) }
    /// 指针位置，屏幕坐标。
    var pointerLocation: () -> CGPoint = { NSEvent.mouseLocation }
    /// 当前时间，秒。用单调时钟，不受用户改系统时间影响。
    var now: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
}

/// 晾衣线的运行时。对应 Compose 版 `AppRuntime` 里截图相关的部分。
///
/// 职责：
/// - 持有卡片列表，读写 `shelf.json`。
/// - 监视截图目录与桌面，新截图自动上架。
/// - 按指针位置决定工具栏何时显示、何时收起。
/// - 提供复制、预览、标记、移除、拖拽这些动作。
///
/// 只跑在主线程。文件读写与 `defaults` 调用在各自的后台队列或线程里完成。
///
/// 面板由外部接线：`AppRuntime` 建好运行时之后把 `panel` 挂上。
/// 面板反向持有运行时，所以那边用 `unowned`，这里用强引用。
@MainActor
@Observable
final class ShelfRuntime {
    /// 卡片列表，最旧的在前。
    private(set) var items: [ShelfItem] = []
    /// 工具栏当前是否显示。
    private(set) var isVisible = false
    /// 工具栏是否已被用户展开过。落盘用，与 Compose 版一致。
    private(set) var isRevealed = true
    /// 截图接管当前是否开着。
    private(set) var takeoverActive = false
    /// 正在飞进工具栏的那张卡片。没有就是空。
    private(set) var flyingPath: String?
    /// 有拖拽会话在跑。跑着的时候不收起工具栏，否则用户没地方放手。
    private(set) var dragActive = false
    /// 起飞中的接管任务。停机时要撤掉它。
    private(set) var takeoverTask: Task<Void, Never>?
    /// 接管代次号。每次 `syncTakeover()` 加一，用来丢掉过期的结果。
    private var takeoverGeneration = 0

    /// 面板。接线之前是空，那时所有显示动作都不做事。
    var panel: ShelfPresenting?

    /// 时序与判定住在共享模块的 `ShelfPresencePolicy`。
    /// 这里只是转发，方便既有调用点与测试继续按 `ShelfRuntime.xxx` 读。
    static var menuBarDwellSeconds: TimeInterval { ShelfPresencePolicy.shared.MENU_BAR_DWELL_SECONDS }
    static var exitDelaySeconds: TimeInterval { ShelfPresencePolicy.shared.EXIT_DELAY_SECONDS }
    static var autoHideSeconds: TimeInterval { ShelfPresencePolicy.shared.AUTO_HIDE_SECONDS }
    static var pollIntervalSeconds: TimeInterval { ShelfPresencePolicy.shared.POLL_INTERVAL_SECONDS }
    /// 移动完成检查的节奏与飞入等待时间同样来自共享模块。
    static var flyInDelaySeconds: TimeInterval { ShelfMoveCheck.shared.FLY_IN_DELAY_SECONDS }
    static var moveCheckDelaySeconds: TimeInterval { ShelfMoveCheck.shared.plan.firstDelaySeconds }
    static var moveCheckCount: Int { Int(ShelfMoveCheck.shared.plan.checkCount) }
    static var moveCheckIntervalSeconds: TimeInterval { ShelfMoveCheck.shared.plan.intervalSeconds }

    private let environment: ShelfEnvironment
    private let store: ShelfStoreClient
    private let takeover: ScreenshotTakeoverController
    private let sound: ShelfSoundPlaying
    private let watcherFactory: ScreenshotWatcherFactory
    private let attributeReader: (String) -> Bool
    /// 出错时给用户看的一句话。由 `AppRuntime` 接到自己的 `statusMessage` 上。
    private let report: (LocalizedCopy) -> Void

    private var watchers: [ScreenshotWatching] = []
    private var pollTimer: Timer?
    private var autoHideTimer: Timer?
    private var menuBarCandidateAt: TimeInterval?
    private var exitCandidateAt: TimeInterval?
    /// 指针是不是在面板内容上。面板平时鼠标穿透，所以这个信号只在卡片上才可靠。
    private var pointerInsideContent = false

    init(
        store: ShelfStoreClient,
        takeover: ScreenshotTakeoverController,
        environment: ShelfEnvironment,
        sound: ShelfSoundPlaying = MacShelfSound(),
        watcherFactory: @escaping ScreenshotWatcherFactory = ScreenshotWatcher.make,
        attributeReader: @escaping @MainActor (String) -> Bool = hasScreenCaptureAttribute,
        report: @escaping @MainActor (LocalizedCopy) -> Void = { _ in }
    ) {
        self.store = store
        self.takeover = takeover
        self.environment = environment
        self.sound = sound
        self.watcherFactory = watcherFactory
        self.attributeReader = attributeReader
        self.report = report

        let state = store.load()
        items = state.items
        isRevealed = state.revealed
        takeoverActive = takeover.isActive
    }

    // MARK: - 生命周期

    /// 启动工具栏。可以重复调用，第二次没有副作用。
    ///
    /// 与 Compose 版 `initializeShelf` 同序：先补齐目录与接管，再起监视器与巡检。
    /// 接管本身是异步的，见 `syncTakeover()`。
    func start() {
        guard pollTimer == nil else { return }
        persist()
        try? FileManager.default.createDirectory(
            at: ShelfPaths.screenshotsDirectory, withIntermediateDirectories: true
        )
        startWatchers()
        syncTakeover()
        // 巡检要跟着拖拽与滚动一起跑，所以加进 common 模式。
        let timer = Timer(timeInterval: Self.pollIntervalSeconds, repeats: true) { _ in
            MainActor.assumeIsolated { self.updateVisibility() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    /// 停止工具栏。退出前调用。
    ///
    /// 卸载 helper 或退出应用时，系统截图设置要还原，否则用户的截图会一直落进 Covio 的目录。
    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        stopWatchers()
        // 起飞中的接管先撤掉，否则它落地后会把刚还原的设置又写回去。
        takeoverTask?.cancel()
        takeoverTask = nil
        // 快照在磁盘上时说明接管还开着。还原之后把快照清掉，避免下次重复还原。
        if takeover.isActive, store.load().preferenceSnapshot != nil {
            if !takeover.restoreOnExit() {
                report(Copy.copyTopShelfErrorRestore)
            }
        }
        panel?.dismiss()
        isVisible = false
    }

    /// 配置变化后重新读开关。截图接管开关与晾衣线开关变了都要走这里。
    func applyConfiguration() {
        guard pollTimer != nil else { return }
        startWatchers()
        syncTakeover()
        if !environment.isShelfEnabled() { hide() }
    }

    // MARK: - 显示与收起

    func show() {
        guard environment.isShelfEnabled(), !environment.isFullScreenSpaceActive() else { return }
        isRevealed = true
        isVisible = true
        exitCandidateAt = nil
        persist()
        panel?.present(reduceMotion: environment.reduceMotion())
    }

    func hide() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        isVisible = false
        exitCandidateAt = nil
        persist()
        panel?.dismiss()
    }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    /// 显示一段时间后自动收起。新截图到达时用。
    func showTemporarily(seconds: TimeInterval = ShelfRuntime.autoHideSeconds) {
        show()
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: max(0, seconds), repeats: false) { _ in
            MainActor.assumeIsolated { self.hide() }
        }
    }

    func clearItems() {
        items = []
        persist()
    }

    /// 指针是否在卡片上。巡检据此决定要不要收起。
    func setPointerInsideContent(_ inside: Bool) {
        pointerInsideContent = inside
        if inside { exitCandidateAt = nil }
    }

    /// 打开截图目录。目录不存在时先建。
    func openScreenshotDirectory() {
        let directory = ShelfPaths.screenshotsDirectory
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            report(Copy.copyTopShelfErrorDirectory)
            return
        }
        guard NSWorkspace.shared.open(directory) else {
            report(Copy.copyTopShelfErrorDirectory)
            return
        }
    }

    // MARK: - 指针巡检

    /// 按指针位置决定显示还是收起。巡检每秒调十次。
    ///
    /// 判定本身在共享模块的 `ShelfPresencePolicy`。这里只负责取信号：
    /// 指针位置、落在哪块屏、菜单栏有多高、指针是不是在卡片上。
    func updateVisibility() {
        guard environment.isShelfEnabled(), !environment.isFullScreenSpaceActive() else {
            panel?.setPassthrough(true)
            if isVisible { hide() }
            return
        }
        let pointer = environment.pointerLocation()
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) })
            ?? NSScreen.main
        else { return }

        let overCard = panel?.isPointerOverCard(pointer) ?? false
        // 只有指针在卡片上时才接管点击，其余位置让菜单栏和桌面照常收到事件。
        panel?.setPassthrough(!overCard)

        // 菜单栏的实际高度随「自动隐藏菜单栏」等设置变化，所以按当前屏幕算。
        let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        let menuBarBottom = screen.frame.maxY - menuBarHeight - 2
        let decision = ShelfPresencePolicy.shared.decide(
            input: ShelfPresenceInput(
                now: environment.now(),
                isVisible: isVisible,
                isPointerInMenuBar: pointer.y >= menuBarBottom,
                // 拖拽期间指针可能已经离开面板，但用户还需要一个放手的地方。
                isPointerOnShelf: overCard || pointerInsideContent || dragActive,
                menuBarCandidateAt: menuBarCandidateAt.map { KotlinDouble(double: $0) },
                exitCandidateAt: exitCandidateAt.map { KotlinDouble(double: $0) }
            )
        )

        menuBarCandidateAt = decision.menuBarCandidateAt?.doubleValue
        exitCandidateAt = decision.exitCandidateAt?.doubleValue
        if decision.shouldHide {
            hide()
        } else if decision.shouldShow {
            // 自动展开时要撤掉自动收起计时器，否则它到点会立刻把工具栏收掉。
            autoHideTimer?.invalidate()
            autoHideTimer = nil
            show()
        }
    }

    // MARK: - 卡片动作

    func copyItem(_ item: ShelfItem) {
        guard ShelfClipboard.copy(URL(fileURLWithPath: item.path)) else {
            report(Copy.copyTopShelfErrorCopy)
            return
        }
    }

    func openItem(_ item: ShelfItem) {
        let url = URL(fileURLWithPath: item.path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            report(Copy.copyTopShelfErrorOpen)
            return
        }
        guard NSWorkspace.shared.open(url) else {
            report(Copy.copyTopShelfErrorOpen)
            return
        }
    }

    /// 用系统标记工具打开。工具不可用时退回预览。README 第 76 行。
    func markupItem(_ item: ShelfItem) {
        let url = URL(fileURLWithPath: item.path)
        if ShelfNative.openMarkup(fileURL: url) { return }
        guard NSWorkspace.shared.open(url) else {
            report(Copy.copyTopShelfErrorMarkup)
            return
        }
    }

    /// 从工具栏移除。只改列表，不动磁盘上的文件。
    func removeItem(_ item: ShelfItem) {
        let normalized = ShelfStore.companion.canonicalPath(value: item.path)
        items = items.filter { ShelfStore.companion.canonicalPath(value: $0.path) != normalized }
        persist()
    }

    // MARK: - 拖拽

    /// 用户把卡片拖出工具栏。
    ///
    /// 拖拽会话由 AppKit 跑，结束时回调操作掩码。掩码翻成结果之后再做文件操作。
    func beginDrag(item: ShelfItem, from view: NSView, event: NSEvent) {
        let url = URL(fileURLWithPath: item.path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            removeItem(item)
            return
        }
        dragActive = true
        let started = ShelfNative.startFileDrag(from: view, fileURL: url, event: event) { [weak self] mask in
            MainActor.assumeIsolated { self?.finishDrag(item: item, operationMask: mask) }
        }
        guard started else {
            dragActive = false
            animateReturn(of: url)
            return
        }
    }

    /// 拖拽结束。按落点决定是保留、移动还是删除。
    func finishDrag(item: ShelfItem, operationMask: UInt64) {
        let url = URL(fileURLWithPath: item.path)
        switch ShelfDropResolver.result(forOperationMask: operationMask) {
        case .theCopy:
            dragActive = false
            play(.pop)
        case .move:
            // 移动是异步完成的：系统还在拷文件。轮询确认之后再动列表。
            checkMoveCompleted(item: item, url: url)
        case .delete_:
            dragActive = false
            removeItem(item)
            play(.trash)
        case .cancel:
            dragActive = false
            animateReturn(of: url)
            play(.pop)
        default:
            dragActive = false
        }
    }

    /// 拖到文件夹或桌面时，文件是移动过去的，落点那边不会回调。
    ///
    /// 先等 600 毫秒，然后每 300 毫秒看一次文件还在不在。四次都不消失
    /// 说明移动没成功，把卡片飞回工具栏。
    private func checkMoveCompleted(item: ShelfItem, url: URL) {
        Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: UInt64(Self.moveCheckDelaySeconds * 1_000_000_000)
            )
            for _ in 0..<Self.moveCheckCount {
                if !FileManager.default.fileExists(atPath: url.path) {
                    dragActive = false
                    removeItem(item)
                    play(.trash)
                    return
                }
                try? await Task.sleep(
                    nanoseconds: UInt64(Self.moveCheckIntervalSeconds * 1_000_000_000)
                )
            }
            dragActive = false
            animateReturn(of: url)
            play(.pop)
        }
    }

    /// 拖到别的应用或文件夹时的落点处理。
    ///
    /// `action` 来自落点类型。除了「复制并保留」，其余都要把卡片摘掉。
    func handleDrop(
        item: ShelfItem,
        action: ShelfDropAction,
        destination: URL?
    ) {
        let url = URL(fileURLWithPath: item.path)
        guard ShelfFileOperations.perform(action: action, source: url, destination: destination) else {
            if action != .cancel { report(Copy.copyTopShelfErrorMove) }
            return
        }
        if action != .theCopyAndKeep { removeItem(item) }
        play(action == .trashAndRemove ? .trash : .pop)
    }

    private func animateReturn(of url: URL) {
        ShelfNative.animateImage(fileURL: url, to: panel?.window, returning: true)
    }

    // MARK: - 自动上架

    /// 新截图落盘。加进列表、落盘、飞进来、自动收起。
    ///
    /// 去重与上限规则住在 `kmpDomain` 的 `ShelfStore.normalizeItems` 里。
    /// 它保留先出现的那条，所以先摘掉同路径的旧记录，再把新记录放到末尾。
    ///
    /// `exists` 传常量真：上面已经查过这一个文件，而且列表里其它卡片
    /// 可能是桌面上的文件，不能在主线程上查（见 `refreshExistingFiles`）。
    ///
    /// Kotlin 的函数类型参数在 Swift 侧收 `KotlinBoolean`（ADR-001 实测 20）。
    func addItem(at url: URL) {
        guard environment.isShelfEnabled() else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let normalized = ShelfStore.companion.canonicalPath(value: url.path)
        let item = ShelfItem(path: normalized, addedAtEpochSeconds: Int64(environment.now()))
        let kept = items.filter {
            ShelfStore.companion.canonicalPath(value: $0.path) != normalized
        }
        let updated = ShelfStore.companion.normalizeItems(
            items: kept + [item],
            limit: Int32(ShelfStoreClient.maxItems),
            exists: { _ in KotlinBoolean(bool: true) }
        )
        guard updated.map(\.path) != items.map(\.path) else { return }

        items = updated
        flyingPath = normalized
        persist()
        showTemporarily()
        play(.pop)

        Task { @MainActor in
            // 系统写完文件要一点时间，等一等等再读图。
            try? await Task.sleep(nanoseconds: UInt64(Self.flyInDelaySeconds * 1_000_000_000))
            ShelfNative.animateImage(
                fileURL: URL(fileURLWithPath: normalized),
                to: panel?.window,
                returning: false
            )
            try? await Task.sleep(
                nanoseconds: UInt64(ShelfMotionSpec.flyInSeconds * 1_000_000_000)
            )
            if flyingPath == normalized { flyingPath = nil }
        }
    }

    /// 文件被外部删掉了。把它们从列表里摘掉。
    ///
    /// **存在性检查放后台。** 卡片可能是桌面上的文件。桌面在 iCloud 里、
    /// 家里目录在网络上、或者系统正在等用户的隐私授权时，
    /// `fileExists` 都会一直不返回。这个方法每次目录变动都会被调到，
    /// 不能让主线程等它。
    func refreshExistingFiles() {
        let snapshot = items
        guard !snapshot.isEmpty else { return }
        let paths = snapshot.map(\.path)
        Task { @MainActor in
            let surviving = await Task.detached(priority: .utility) {
                Set(paths.filter { FileManager.default.fileExists(atPath: $0) })
            }.value
            // 等结果的这段时间列表可能已经变了，所以按当前列表过一遍。
            // 去重与上限规则住在 kmpDomain 的 ShelfStore.normalizeItems 里。
            let trimmed = ShelfStore.companion.normalizeItems(
                items: items,
                limit: Int32(ShelfStoreClient.maxItems),
                exists: { surviving.contains($0) ? KotlinBoolean(bool: true) : KotlinBoolean(bool: false) }
            )
            guard trimmed.map(\.path) != items.map(\.path) else { return }
            items = trimmed
            persist()
        }
    }

    // MARK: - 监视器

    /// 起两个监视器：截图目录一个，桌面一个。
    ///
    /// 桌面那一个只在截图接管开着时才起，因为那时截图才可能落到桌面上。
    private func startWatchers() {
        stopWatchers()
        guard environment.isShelfEnabled() else { return }
        let directory = ShelfPaths.screenshotsDirectory
        var created: [ScreenshotWatching] = [
            watcherFactory(
                directory,
                directory,
                false,
                { [weak self] url in self?.addItem(at: url) },
                { [weak self] in self?.refreshExistingFiles() }
            )
        ]
        if takeover.isActive {
            created.append(
                watcherFactory(
                    ShelfPaths.desktopDirectory,
                    directory,
                    true,
                    { [weak self] url in self?.addItem(at: url) },
                    { [weak self] in self?.refreshExistingFiles() }
                )
            )
        }
        created.forEach { $0.start() }
        watchers = created
    }

    private func stopWatchers() {
        watchers.forEach { $0.close() }
        watchers = []
    }

    /// 按配置打开或还原截图接管。
    /// 让系统截图设置与本应用的开关一致。
    ///
    /// **不在主线程上等。** 这一步要跑 `defaults` 子进程，正常毫秒级返回，
    /// 但被系统对话框挡住时没有上限。以前同步跑，启动流程就被它挂住过。
    /// 所以子进程放后台，结果回主 actor 收尾。
    ///
    /// 结果用代次号判断：期间又调过一次或已经停机时，旧结果作废。
    /// 作废时如果刚把接管打开，还要把系统设置收回来，见下面的注释。
    private func syncTakeover() {
        takeoverGeneration += 1
        let generation = takeoverGeneration
        let enabling = environment.isTakeoverEnabled()
        // 关掉接管且磁盘上没有快照时无事可做，不必起子进程。
        guard enabling || store.load().preferenceSnapshot != nil else {
            applyTakeoverState(takeover.isActive)
            return
        }

        takeoverTask?.cancel()
        takeoverTask = Task { [takeover] in
            let succeeded = await Task.detached(priority: .utility) {
                enabling ? takeover.enable() : takeover.disable()
            }.value
            // 已经在停机，或者期间又读了一次配置：结果作废。
            //
            // **如果刚打开接管，还要把设置收回来。** 取消只作用于这个任务，
            // 后台那次 `enable()` 已经跑完了，系统设置已经改掉。
            // 不收回的话，用户退出应用之后截图仍然落进 Covio 的目录。
            guard !Task.isCancelled, self.takeoverGeneration == generation else {
                if succeeded, enabling { _ = takeover.disable() }
                return
            }
            guard succeeded else {
                self.report(enabling ? Copy.copyTopShelfErrorTakeover : Copy.copyTopShelfErrorRestore)
                return
            }
            self.applyTakeoverState(takeover.isActive)
        }
    }

    /// 接管状态落地。变了就重排监视器。
    ///
    /// **不能只在 `syncTakeover()` 的开头重排监视器。** 接管是异步落地的，
    /// 所以那一刻的状态还是旧的：
    /// 用户刚打开接管时，桌面监视器起不来，桌面上的截图收不到；
    /// 用户刚关掉接管时，桌面监视器还开着，会一直盯着桌面。
    private func applyTakeoverState(_ active: Bool) {
        guard active != takeoverActive else { return }
        takeoverActive = active
        startWatchers()
    }

    // MARK: - 内部

    /// 落盘。只写 `items` 与 `revealed`，快照由接管控制器维护。
    private func persist() {
        let state = store.load()
        store.save(state.doCopy(items: items, revealed: isRevealed, preferenceSnapshot: state.preferenceSnapshot))
    }

    private func play(_ name: ShelfSound) {
        guard environment.isSoundsEnabled() else { return }
        sound.play(name)
    }
}

/// 监视器的接口。测试传假的，就不必真的动文件系统。
@MainActor
protocol ScreenshotWatching: AnyObject {
    func start()
    func close()
}

extension ScreenshotWatcher: ScreenshotWatching {}

/// 造监视器。参数依次是监视目录、专用目录、是否要求截图属性、两个回调。
typealias ScreenshotWatcherFactory = @MainActor (
    URL,
    URL,
    Bool,
    @escaping (URL) -> Void,
    @escaping () -> Void
) -> ScreenshotWatching

extension ScreenshotWatcher {
    /// 默认的监视器工厂。
    static let make: ScreenshotWatcherFactory = { directory, dedicated, requireAttribute, onNew, onChange in
        ScreenshotWatcher(
            directory: directory,
            dedicatedDirectory: dedicated,
            requireScreenCaptureAttribute: requireAttribute,
            onNew: onNew,
            onChange: onChange
        )
    }
}

/// 工具栏的提示音。
enum ShelfSound: Sendable {
    case pop
    case trash
}

@MainActor
protocol ShelfSoundPlaying: AnyObject {
    func play(_ sound: ShelfSound)
}

/// 用 AppKit 播系统音效。
///
/// Compose 版走 `/usr/bin/afplay`，每次起一个进程。`NSSound` 是同一批音频文件，
/// 不必起进程，音量也一样。
@MainActor
final class MacShelfSound: ShelfSoundPlaying {
    /// 音量。与 Compose 版的 `playSound` 一致。
    static let volume: Float = 0.35

    private var playing: [NSSound] = []

    func play(_ sound: ShelfSound) {
        let name = sound == .pop ? "Pop" : "Submarine"
        guard let created = NSSound(named: name) else { return }
        created.volume = Self.volume
        // `NSSound` 自己不持有正在播的实例，不留一份引用会被提前释放。
        playing.append(created)
        created.play()
        playing.removeAll { !$0.isPlaying }
    }
}

/// 当前 Space 是不是全屏。
///
/// 只能问 WindowServer，没有公开接口。`CGSCopyManagedDisplaySpaces` 是
/// Compose 版已经在用的私有接口，这里用同一个，行为才对得上。
///
/// 拿不到符号或者结构变了都返回假：让工具栏显示出来，比让它永远不显示好。
enum FullScreenSpaceDetector {
    /// 全屏 Space 的类型编号，来自 `MacShelfNative.FULL_SCREEN_SPACE_TYPE`。
    static let fullScreenSpaceType = 4

    private typealias MainConnectionIDFunction = @convention(c) () -> Int32
    private typealias CopyManagedDisplaySpacesFunction =
        @convention(c) (Int32) -> Unmanaged<CFArray>?

    private static let symbols: (main: MainConnectionIDFunction, spaces: CopyManagedDisplaySpacesFunction)? = {
        guard let handle = dlopen(
            "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
            RTLD_LAZY
        ) else { return nil }
        guard let main = dlsym(handle, "CGSMainConnectionID"),
              let spaces = dlsym(handle, "CGSCopyManagedDisplaySpaces")
        else { return nil }
        return (
            unsafeBitCast(main, to: MainConnectionIDFunction.self),
            unsafeBitCast(spaces, to: CopyManagedDisplaySpacesFunction.self)
        )
    }()

    static func isActive() -> Bool {
        guard let symbols else { return false }
        guard let displays = symbols.spaces(symbols.main())?.takeRetainedValue() else { return false }
        for index in 0..<CFArrayGetCount(displays) {
            guard let raw = CFArrayGetValueAtIndex(displays, index) else { continue }
            let display = Unmanaged<CFDictionary>.fromOpaque(raw).takeUnretainedValue()
            guard let currentRaw = rawValue(in: display, key: "Current Space") else { continue }
            let current = Unmanaged<CFDictionary>.fromOpaque(currentRaw).takeUnretainedValue()
            guard let typeRaw = rawValue(in: current, key: "type") else { continue }
            let type = Unmanaged<NSNumber>.fromOpaque(typeRaw).takeUnretainedValue().intValue
            if type == fullScreenSpaceType { return true }
        }
        return false
    }

    /// 从字典里取一个键。返回的是借用指针，调用方马上转成具体类型。
    private static func rawValue(in dictionary: CFDictionary, key: String) -> UnsafeRawPointer? {
        let cfKey = key as CFString
        return CFDictionaryGetValue(dictionary, Unmanaged.passUnretained(cfKey).toOpaque())
    }
}
