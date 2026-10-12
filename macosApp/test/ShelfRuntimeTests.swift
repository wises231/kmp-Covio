import AppKit
import XCTest
import kmpDomain
@testable import Covio

/// `ShelfRuntime` 的行为测试。
///
/// 面板、指针、时钟、提示音、监视器全部换成假的，所以用例不碰真实屏幕、
/// 不动真实文件，也不等真实时间。文件操作那几条用临时目录里的真文件，
/// 因为 `ShelfFileOperations` 就该真的搬文件。
@MainActor
final class ShelfRuntimeTests: XCTestCase {
    private var directory: URL!
    private var store: ShelfStoreClient!
    private var panel: FakeShelfPanel!
    private var sound: FakeShelfSound!
    private var watchers: FakeWatcherFactory!
    private var reported: [String] = []
    /// 假时钟。用例自己往前推。
    private var clock: TimeInterval = 1_000
    private var pointer = CGPoint(x: 100, y: 100)
    private var fullScreen = false
    private var shelfEnabled = true
    private var takeoverEnabled = false
    private var soundsEnabled = true
    private var runtime: ShelfRuntime!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("covio-shelf-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = ShelfStoreClient(path: directory.appendingPathComponent("shelf.json").path)
        panel = FakeShelfPanel()
        sound = FakeShelfSound()
        watchers = FakeWatcherFactory()
        reported = []
        clock = 1_000
        fullScreen = false
        shelfEnabled = true
        takeoverEnabled = false
        soundsEnabled = true
        runtime = nil
    }

    override func tearDownWithError() throws {
        runtime?.stop()
        runtime = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeRuntime(preferences: ScreenshotPreferenceStore? = nil) -> ShelfRuntime {
        let store = store!
        let created = ShelfRuntime(
            store: store,
            takeover: ScreenshotTakeoverController(
                store: preferences ?? FakeShelfPreferences(),
                directory: directory.appendingPathComponent("Screenshots", isDirectory: true),
                shelfStore: store
            ),
            environment: ShelfEnvironment(
                isShelfEnabled: { [weak self] in self?.shelfEnabled ?? false },
                isTakeoverEnabled: { [weak self] in self?.takeoverEnabled ?? false },
                isSoundsEnabled: { [weak self] in self?.soundsEnabled ?? false },
                isFullScreenSpaceActive: { [weak self] in self?.fullScreen ?? false },
                reduceMotion: { false },
                language: { .english },
                pointerLocation: { [weak self] in self?.pointer ?? .zero },
                now: { [weak self] in self?.clock ?? 0 }
            ),
            sound: sound,
            watcherFactory: watchers.factory,
            report: { [weak self] entry in self?.reported.append(entry.text(for: .english)) }
        )
        created.panel = panel
        runtime = created
        return created
    }

    /// 造一个真实存在的文件，用作卡片指向的目标。
    private func makeFile(_ name: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data("x".utf8).write(to: url)
        return url
    }

    /// 等条件成立。存在性检查现在跑在后台，所以有几条用例要等它落地。
    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    // MARK: - 持久化

    func testItemsSurviveARestart() throws {
        let first = makeRuntime()
        first.addItem(at: try makeFile("a.png"))
        first.addItem(at: try makeFile("b.png"))
        XCTAssertEqual(first.items.count, 2)

        // 换一个运行时读同一个文件。
        let second = makeRuntime()
        XCTAssertEqual(second.items.map(\.path), first.items.map(\.path))
    }

    func testAddingTheSamePathTwiceKeepsOneCard() throws {
        let runtime = makeRuntime()
        let file = try makeFile("a.png")
        runtime.addItem(at: file)
        runtime.addItem(at: file)
        XCTAssertEqual(runtime.items.count, 1)
    }

    func testTheOldestCardFallsOffWhenTheListIsFull() throws {
        let runtime = makeRuntime()
        var paths: [String] = []
        for index in 0...ShelfStoreClient.maxItems {
            let file = try makeFile("shot-\(index).png")
            paths.append(file.path)
            runtime.addItem(at: file)
        }
        XCTAssertEqual(runtime.items.count, ShelfStoreClient.maxItems)
        // 最旧的那张被挤掉了。
        XCTAssertFalse(runtime.items.contains { $0.path == paths[0] })
        XCTAssertTrue(runtime.items.contains { $0.path == paths.last! })
    }

    func testAMissingFileIsNeverAdded() {
        let runtime = makeRuntime()
        runtime.addItem(at: directory.appendingPathComponent("nope.png"))
        XCTAssertTrue(runtime.items.isEmpty)
    }

    func testRemovingMatchesCanonicalPaths() throws {
        let runtime = makeRuntime()
        let file = try makeFile("a.png")
        runtime.addItem(at: file)
        // 同一个文件，路径里多一层没用的 `..`。
        let twisted = directory.appendingPathComponent("sub/../a.png")
        runtime.removeItem(ShelfItem(path: twisted.path, addedAtEpochSeconds: 0))
        XCTAssertTrue(runtime.items.isEmpty, "规范化之后的路径应当能匹配上")
    }

    // MARK: - 显示与收起

    func testShowDoesNothingWhenTheShelfIsOff() {
        shelfEnabled = false
        let runtime = makeRuntime()
        runtime.show()
        XCTAssertFalse(runtime.isVisible)
        XCTAssertEqual(panel.presentCount, 0)
    }

    func testShowDoesNothingInAFullScreenSpace() {
        fullScreen = true
        let runtime = makeRuntime()
        runtime.show()
        XCTAssertFalse(runtime.isVisible)
        XCTAssertEqual(panel.presentCount, 0)
    }

    func testShowAndHideDriveThePanel() {
        let runtime = makeRuntime()
        runtime.show()
        XCTAssertTrue(runtime.isVisible)
        XCTAssertEqual(panel.presentCount, 1)

        runtime.hide()
        XCTAssertFalse(runtime.isVisible)
        XCTAssertEqual(panel.dismissCount, 1)
    }

    func testToggleFlipsTheVisibility() {
        let runtime = makeRuntime()
        runtime.toggle()
        XCTAssertTrue(runtime.isVisible)
        runtime.toggle()
        XCTAssertFalse(runtime.isVisible)
    }

    // MARK: - 指针巡检

    /// 指针进菜单栏要停留 250 毫秒才展开。
    func testTheMenuBarDwellIsRequiredBeforeShowing() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        // 菜单栏那一条：屏幕顶边往下 4 点。
        pointer = CGPoint(x: screen.frame.midX, y: screen.frame.maxY - 4)
        let runtime = makeRuntime()

        runtime.updateVisibility()
        XCTAssertFalse(runtime.isVisible, "刚进菜单栏就展开，缺了停留时间")

        clock += ShelfRuntime.menuBarDwellSeconds
        runtime.updateVisibility()
        XCTAssertTrue(runtime.isVisible, "停留够了应当展开")
    }

    /// 指针离开后要等 500 毫秒才收起。
    func testTheExitDelayIsRequiredBeforeHiding() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        pointer = CGPoint(x: screen.frame.midX, y: screen.frame.maxY - 4)
        let runtime = makeRuntime()
        runtime.updateVisibility()
        clock += ShelfRuntime.menuBarDwellSeconds
        runtime.updateVisibility()
        XCTAssertTrue(runtime.isVisible)

        // 指针离开菜单栏，移到屏幕正中。
        pointer = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        runtime.updateVisibility()
        XCTAssertTrue(runtime.isVisible, "刚离开就收起，缺了离开延迟")

        clock += ShelfRuntime.exitDelaySeconds
        runtime.updateVisibility()
        XCTAssertFalse(runtime.isVisible, "离开够久应当收起")
    }

    /// 回到卡片上就不再收起。
    func testComingBackInsideClearsTheExitCandidate() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        pointer = CGPoint(x: screen.frame.midX, y: screen.frame.maxY - 4)
        let runtime = makeRuntime()
        runtime.updateVisibility()
        clock += ShelfRuntime.menuBarDwellSeconds
        runtime.updateVisibility()

        pointer = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        runtime.updateVisibility()
        clock += ShelfRuntime.exitDelaySeconds - 0.1
        // 又回到菜单栏。
        pointer = CGPoint(x: screen.frame.midX, y: screen.frame.maxY - 4)
        runtime.updateVisibility()
        clock += ShelfRuntime.exitDelaySeconds
        runtime.updateVisibility()
        XCTAssertTrue(runtime.isVisible, "离开计时应当被清掉")
    }

    func testVisibilityFallsBackWhenTheShelfIsSwitchedOff() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        pointer = CGPoint(x: screen.frame.midX, y: screen.frame.maxY - 4)
        let runtime = makeRuntime()
        runtime.updateVisibility()
        clock += ShelfRuntime.menuBarDwellSeconds
        runtime.updateVisibility()
        XCTAssertTrue(runtime.isVisible)

        shelfEnabled = false
        runtime.updateVisibility()
        XCTAssertFalse(runtime.isVisible, "开关关掉后工具栏必须让位")
        XCTAssertTrue(panel.passthrough, "关掉后要放开鼠标穿透，让菜单栏能用")
    }

    /// 指针不在卡片上时面板鼠标穿透。命中判定交给面板，这里只测转发。
    func testPassthroughFollowsTheCardHitTest() throws {
        let runtime = makeRuntime()
        panel.overCard = false
        runtime.updateVisibility()
        XCTAssertTrue(panel.passthrough)

        panel.overCard = true
        runtime.updateVisibility()
        XCTAssertFalse(panel.passthrough, "指针在卡片上时面板要接管点击")
    }

    /// 新截图到达后自动收起的时长。
    func testTemporarilyShownThenAutoHidden() {
        let runtime = makeRuntime()
        runtime.showTemporarily(seconds: 0)
        // 0 秒的计时器也要等一轮运行循环。它落到哪一轮，取决于主队列上还排着哪些块，
        // 所以不能靠一次 `async` 跳转的次序来断言。这里转运行循环等它落地。
        let deadline = Date().addingTimeInterval(1)
        while runtime.isVisible && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertFalse(runtime.isVisible)
    }

    func testClearRemovesEveryCardAndPersists() throws {
        let runtime = makeRuntime()
        runtime.addItem(at: try makeFile("a.png"))
        runtime.clearItems()
        XCTAssertTrue(runtime.items.isEmpty)
        XCTAssertTrue(makeRuntime().items.isEmpty)
    }

    // MARK: - 拖拽结果

    func testCopyKeepsTheCard() throws {
        let runtime = makeRuntime()
        runtime.addItem(at: try makeFile("a.png"))
        // 上架本身会响一声，这里只看拖拽这一声。
        sound.forget()
        runtime.finishDrag(item: runtime.items[0], operationMask: UInt64(NSDragOperation.copy.rawValue))
        XCTAssertEqual(runtime.items.count, 1)
        XCTAssertEqual(sound.played, [.pop])
        XCTAssertFalse(runtime.dragActive)
    }

    func testDeleteDropsTheCardAndTrashes() throws {
        let runtime = makeRuntime()
        let file = try makeFile("a.png")
        runtime.addItem(at: file)
        sound.forget()
        runtime.finishDrag(item: runtime.items[0], operationMask: UInt64(NSDragOperation.delete.rawValue))
        XCTAssertTrue(runtime.items.isEmpty)
        XCTAssertEqual(sound.played, [.trash])
    }

    func testCancelKeepsTheCard() throws {
        let runtime = makeRuntime()
        runtime.addItem(at: try makeFile("a.png"))
        sound.forget()
        runtime.finishDrag(item: runtime.items[0], operationMask: 0)
        XCTAssertEqual(runtime.items.count, 1)
        XCTAssertEqual(sound.played, [.pop])
    }

    /// 移动是异步的：文件还在就先不摘卡片，等轮询确认。
    func testMoveKeepsTheCardWhileTheFileIsStillThere() async throws {
        let runtime = makeRuntime()
        let file = try makeFile("a.png")
        runtime.addItem(at: file)
        runtime.finishDrag(item: runtime.items[0], operationMask: UInt64(NSDragOperation.move.rawValue))
        XCTAssertEqual(runtime.items.count, 1, "刚拖完文件还在，不能立刻摘卡片")
    }

    /// 落点处理：复制并保留不摘卡片，取消什么都不做。
    func testDropActionsDecideWhetherTheCardStays() throws {
        let runtime = makeRuntime()
        let file = try makeFile("a.png")
        runtime.addItem(at: file)
        let destination = directory.appendingPathComponent("target", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        runtime.handleDrop(item: runtime.items[0], action: .theCopyAndKeep, destination: destination)
        XCTAssertEqual(runtime.items.count, 1, "复制并保留不该摘卡片")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: destination.appendingPathComponent("a.png").path
            )
        )

        runtime.handleDrop(item: runtime.items[0], action: .moveAndRemove, destination: destination)
        XCTAssertTrue(runtime.items.isEmpty, "移动之后卡片要摘掉")
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    /// 取消不该动卡片，也不该报错。
    func testACancelledDropLeavesEverythingAlone() throws {
        let runtime = makeRuntime()
        let file = try makeFile("a.png")
        runtime.addItem(at: file)
        runtime.handleDrop(item: runtime.items[0], action: .cancel, destination: nil)
        XCTAssertEqual(runtime.items.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(reported.isEmpty)
    }

    /// 目标目录里已经有同名文件时，复制过去的那份要改名，不能覆盖。
    func testCopyingDoesNotOverwriteAnExistingFile() throws {
        let runtime = makeRuntime()
        let file = try makeFile("a.png")
        runtime.addItem(at: file)
        let destination = directory.appendingPathComponent("target", isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        try Data("already here".utf8).write(to: destination.appendingPathComponent("a.png"))

        runtime.handleDrop(item: runtime.items[0], action: .theCopyAndKeep, destination: destination)
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: destination.appendingPathComponent("a 2.png").path
            ),
            "同名文件要顺延成「a 2.png」"
        )
    }

    // MARK: - 提示音

    func testSoundsAreSilentWhenTheSwitchIsOff() throws {
        soundsEnabled = false
        let runtime = makeRuntime()
        runtime.addItem(at: try makeFile("a.png"))
        XCTAssertTrue(sound.played.isEmpty)
    }

    // MARK: - 监视器

    func testWatchersStartOnlyWhenTheShelfIsOn() {
        shelfEnabled = false
        let off = makeRuntime()
        off.start()
        XCTAssertTrue(watchers.created.isEmpty)

        shelfEnabled = true
        let on = makeRuntime()
        on.start()
        // 接管关着时只看截图目录，一个监视器。
        XCTAssertEqual(watchers.created.count, 1)
        XCTAssertTrue(watchers.created[0].started)
    }

    /// 接管开着时多看一个桌面，因为截图这时会落到桌面上。
    ///
    /// 桌面监视器由接管落地后补上，所以要等接管跑完再数。
    func testTakeoverAddsADesktopWatcher() async {
        takeoverEnabled = true
        let runtime = makeRuntime()
        runtime.start()
        await runtime.takeoverTask?.value
        let open = openWatchers
        XCTAssertEqual(open.count, 2)
        XCTAssertEqual(open[0].directory, ShelfPaths.screenshotsDirectory)
        XCTAssertEqual(open[1].directory, ShelfPaths.desktopDirectory)
        XCTAssertTrue(open[1].requireScreenCaptureAttribute)
    }

    /// 关掉接管要撤掉桌面监视器，否则工具栏会一直盯着桌面。
    func testTurningTakeoverOffClosesTheDesktopWatcher() async {
        takeoverEnabled = true
        let runtime = makeRuntime()
        runtime.start()
        await runtime.takeoverTask?.value
        XCTAssertEqual(openWatchers.count, 2)

        takeoverEnabled = false
        runtime.applyConfiguration()
        await runtime.takeoverTask?.value

        let open = openWatchers
        XCTAssertEqual(open.count, 1)
        XCTAssertEqual(open[0].directory, ShelfPaths.screenshotsDirectory)
    }

    func testStoppingClosesEveryWatcher() {
        let runtime = makeRuntime()
        runtime.start()
        runtime.stop()
        XCTAssertTrue(watchers.created.allSatisfy(\.closed))
    }

    /// 重新读配置会重排监视器：旧的关掉，按新的接管状态起一批。
    func testApplyConfigurationRestartsTheWatchers() async {
        let runtime = makeRuntime()
        runtime.start()
        XCTAssertEqual(watchers.created.count, 1)

        takeoverEnabled = true
        runtime.applyConfiguration()
        await runtime.takeoverTask?.value

        XCTAssertTrue(watchers.created[0].closed, "旧的要先关掉")
        XCTAssertEqual(openWatchers.count, 2, "接管开了，看两个目录")
    }

    /// 这一轮还没被关掉的监视器。
    private var openWatchers: [FakeWatching] {
        watchers.created.filter { !$0.closed }
    }

    // MARK: - 文件消失

    /// 文件被外部删掉后要从列表里摘掉。
    ///
    /// 存在性检查跑在后台，所以要等它落地。
    func testRefreshRemovesAVanishedFile() async throws {
        let runtime = makeRuntime()
        let kept = try makeFile("kept.png")
        let gone = try makeFile("gone.png")
        runtime.addItem(at: kept)
        runtime.addItem(at: gone)
        XCTAssertEqual(runtime.items.count, 2)

        try FileManager.default.removeItem(at: gone)
        runtime.refreshExistingFiles()

        await waitUntil { runtime.items.count == 1 }
        XCTAssertEqual(
            runtime.items.map(\.path),
            [ShelfStore.companion.canonicalPath(value: kept.path)]
        )
    }

    /// 文件都还在时什么都不改，也不写盘。
    func testRefreshKeepsExistingFiles() async throws {
        let runtime = makeRuntime()
        runtime.addItem(at: try makeFile("a.png"))
        runtime.addItem(at: try makeFile("b.png"))
        let before = runtime.items.map(\.path)

        runtime.refreshExistingFiles()
        // 给后台检查留出跑完的时间，再确认列表没变。
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(runtime.items.map(\.path), before)
    }
    /// 接管打不开时要报出来，而不是静静地不生效。
    ///
    /// 接管跑在后台，所以要等它落地再看结果。
    func testAFailedTakeoverIsReported() async {
        takeoverEnabled = true
        let preferences = FakeShelfPreferences()
        preferences.applySucceeds = false
        let runtime = makeRuntime(preferences: preferences)
        runtime.start()
        // 启动本身不能被接管挡住：这一刻任务还在飞。
        XCTAssertEqual(reported, [], "start() 不该等接管跑完")
        await runtime.takeoverTask?.value
        XCTAssertEqual(reported, [ContractCopy.copyTopShelfErrorTakeover.text(for: .english)])
        XCTAssertFalse(runtime.takeoverActive)
    }

    func testTakeoverStateIsReadBack() async {
        takeoverEnabled = true
        let runtime = makeRuntime()
        runtime.start()
        await runtime.takeoverTask?.value
        XCTAssertTrue(runtime.takeoverActive)
    }

    /// 停机要撤掉起飞中的接管，否则它落地后会把刚还原的设置又写回去。
    ///
    /// 停机时任务会被置空，所以要先把引用抓在手里再等它跑完。
    /// 不等的话它会在用例清掉临时目录之后才落盘。
    func testStopCancelsAPendingTakeover() async {
        takeoverEnabled = true
        let runtime = makeRuntime()
        runtime.start()
        let pending = runtime.takeoverTask
        XCTAssertNotNil(pending)

        runtime.stop()

        XCTAssertNil(runtime.takeoverTask)
        await pending?.value
    }

    /// 接管在停机之后才落地时，要把已经改掉的系统设置收回来。
    ///
    /// 取消只作用于任务本身，后台那次 `enable()` 已经跑完了。
    /// 不收回的话，用户退出应用之后截图仍然落进 Covio 的目录。
    func testStopUndoesATakeoverThatLandedAfterTheStop() async {
        takeoverEnabled = true
        let preferences = FakeShelfPreferences()
        let runtime = makeRuntime(preferences: preferences)
        runtime.start()
        // 接管还在飞的时候就停机。先把任务抓在手里，停机时它会被置空。
        let pending = runtime.takeoverTask
        runtime.stop()
        await pending?.value

        XCTAssertTrue(preferences.restored, "停机后系统设置要还原")
        XCTAssertFalse(runtime.takeoverActive)
    }

    // MARK: - 预览与标记

    func testOpeningAMissingFileReportsAnError() {
        let runtime = makeRuntime()
        runtime.openItem(ShelfItem(path: directory.appendingPathComponent("gone.png").path, addedAtEpochSeconds: 0))
        XCTAssertEqual(reported, [ContractCopy.copyTopShelfErrorOpen.text(for: .english)])
    }
}

// MARK: - 假的依赖。`AppRuntimeTests` 也复用这几个。

@MainActor
final class FakeShelfPanel: ShelfPresenting {
    var isVisible = false
    var window: NSWindow?
    var presentCount = 0
    var dismissCount = 0
    var passthrough = true
    /// 命中判定的返回值。用例直接设。
    var overCard = false

    func present(reduceMotion: Bool) {
        presentCount += 1
        isVisible = true
    }

    func dismiss() {
        dismissCount += 1
        isVisible = false
    }

    func setPassthrough(_ enabled: Bool) { passthrough = enabled }

    func isPointerOverCard(_ point: CGPoint) -> Bool { overCard }
}

@MainActor
final class FakeShelfSound: ShelfSoundPlaying {
    private(set) var played: [ShelfSound] = []

    func play(_ sound: ShelfSound) { played.append(sound) }

    /// 清空记录。上架本身会响一声，只看之后那一声时要先清掉。
    func forget() { played.removeAll() }
}

@MainActor
final class FakeWatching: ScreenshotWatching {
    let directory: URL
    let dedicatedDirectory: URL
    let requireScreenCaptureAttribute: Bool
    let onNew: (URL) -> Void
    private(set) var started = false
    private(set) var closed = false

    init(
        directory: URL,
        dedicatedDirectory: URL,
        requireScreenCaptureAttribute: Bool,
        onNew: @escaping (URL) -> Void
    ) {
        self.directory = directory
        self.dedicatedDirectory = dedicatedDirectory
        self.requireScreenCaptureAttribute = requireScreenCaptureAttribute
        self.onNew = onNew
    }

    func start() { started = true }
    func close() { closed = true }
}

@MainActor
final class FakeWatcherFactory {
    private(set) var created: [FakeWatching] = []

    var factory: ScreenshotWatcherFactory {
        { directory, dedicated, requireAttribute, onNew, _ in
            // 工厂是 `@MainActor` 的，这里直接建。
            let watcher = FakeWatching(
                directory: directory,
                dedicatedDirectory: dedicated,
                requireScreenCaptureAttribute: requireAttribute,
                onNew: onNew
            )
            self.created.append(watcher)
            return watcher
        }
    }
}

/// 假的系统截图偏好。不跑 `defaults`。
final class FakeShelfPreferences: ScreenshotPreferenceStore, @unchecked Sendable {
    var applySucceeds = true
    var restoreSucceeds = true
    private let lock = NSLock()
    private var stored = ScreenshotInboxSnapshot(
        location: nil, locationScreenshot: nil, showThumbnail: nil
    )
    private(set) var applied: URL?
    private(set) var restored = false

    func read() -> ScreenshotInboxSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func apply(directory: URL) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard applySucceeds else { return false }
        applied = directory
        return true
    }

    func restore(snapshot: ScreenshotInboxSnapshot) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard restoreSucceeds else { return false }
        stored = snapshot
        restored = true
        return true
    }
}
