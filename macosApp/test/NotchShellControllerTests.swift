import AppKit
import XCTest
@testable import Covio

/// `NotchShellController` 的端到端状态测试。
///
/// 这些测试跑在真实的 `NSPanel` 上，只把指针位置换成固定值，
/// 所以不需要真的移动用户的鼠标。见 `NotchShellController.init(pointerLocation:)`。
///
/// 注意：面板的 tracking area 仍然接真实的鼠标事件。测试运行期间如果指针
/// 恰好移进或移出热区与面板，会插入额外事件，断言因此可能失败。
/// 跑这个套件时不要动鼠标。
///
/// 指针与期望值都从 `ScreenGeometry` 推导，不写死屏幕坐标。
/// 面板几何随屏幕变化：刘海屏贴顶边，非刘海屏让开菜单栏；窄屏收窄宽度。
/// CI 运行器是 1024 × 768 的无刘海屏，写死坐标的断言在那里会失败。
@MainActor
final class NotchShellControllerTests: XCTestCase {
    /// 展开态 Hub 面板在屏幕坐标里的矩形。
    ///
    /// 指针位置与宽度期望都由它推导，这样断言与实现看的是同一份几何。
    private func hubPanelRect() throws -> CGRect {
        let screen = try XCTUnwrap(NSScreen.main)
        return ScreenGeometry(screen: screen).expandedRect
    }

    /// 指针固定在 Hub 面板内部靠上处。那里一定落在面板矩形内。
    private func controllerWithPointerInsideHub() throws -> NotchShellController {
        let rect = try hubPanelRect()
        let point = CGPoint(x: rect.midX, y: rect.maxY - 4)
        return NotchShellController(pointerLocation: { point })
    }

    /// 指针固定在面板正下方。那里在面板矩形之外，也在热区之外。
    private func controllerWithPointerAway() throws -> NotchShellController {
        let rect = try hubPanelRect()
        let point = CGPoint(x: rect.midX, y: rect.minY - 20)
        return NotchShellController(pointerLocation: { point })
    }

    /// 等到条件成立。
    ///
    /// 不用固定等待。机器被别的编译占满时，动画计时器与等待窗口一起延后，
    /// 固定等待会报出与实现无关的失败，本机已经误报过三次。
    /// 轮询仍然有上限：状态一直不成立时照样失败。
    private func waitUntil(
        _ message: String,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ condition: () -> Bool
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }
        XCTAssertTrue(condition(), message, file: file, line: line)
    }

    // MARK: - 启动

    func testStartCreatesOneHotZonePerScreenAndKeepsTheHubHidden() throws {
        let controller = try controllerWithPointerAway()
        controller.start()
        defer { controller.stop() }

        XCTAssertEqual(controller.state, .hidden)
        XCTAssertEqual(controller.hotZoneRects.count, NSScreen.screens.count)
        // 面板先按展开矩形建好，但不在屏幕上。
        XCTAssertFalse(controller.isHubPanelOnScreen)
        // 窄屏上面板比 cardWidth 窄，所以比展开矩形，不比 cardWidth。
        let expectedWidth = try hubPanelRect().width
        XCTAssertEqual(controller.hubPanelFrame?.width, expectedWidth)
        XCTAssertLessThanOrEqual(expectedWidth, HubMetrics.cardWidth)
    }

    /// 非刘海屏降级热区：每块屏幕的热区都必须落在该屏幕内，且贴在该屏幕顶部。
    func testHotZonesStayInsideTheirScreens() throws {
        let controller = try controllerWithPointerAway()
        controller.start()
        defer { controller.stop() }

        for (index, rect) in controller.hotZoneRects.enumerated() {
            let screen = NSScreen.screens[index]
            XCTAssertTrue(screen.frame.contains(rect), "第 \(index) 块屏幕的热区超出了屏幕")
            // 热区贴在屏幕顶部：从顶边往下不超过一条菜单栏加一点余量。
            XCTAssertLessThan(screen.frame.maxY - rect.minY, 64, "热区离屏幕顶部太远")
        }
    }

    // MARK: - 展开与收起

    func testHoverOpensTheHubThenBecomesActive() throws {
        let controller = try controllerWithPointerInsideHub()
        controller.start()
        defer { controller.stop() }

        controller.show()
        // 合同路径 HIDDEN → HOVER。
        XCTAssertEqual(controller.state, .hover)
        XCTAssertTrue(controller.isHubPanelOnScreen, "HOVER 时面板就应该在屏幕上")

        // 展开动画结束后进入 OPEN，指针在面板里所以紧接着进入 ACTIVE。
        waitUntil("展开后应该进入 ACTIVE") { controller.state == .active }
    }

    func testRequestingCollapseReturnsToHidden() throws {
        let controller = try controllerWithPointerInsideHub()
        controller.start()
        defer { controller.stop() }

        controller.show()
        waitUntil("展开后应该进入 ACTIVE") { controller.state == .active }

        controller.requestCollapse()
        XCTAssertEqual(controller.state, .exit)

        waitUntil("收起后应该回到 HIDDEN") { controller.state == .hidden }
        XCTAssertFalse(controller.isHubPanelOnScreen, "收起后面板应该离开屏幕")
    }

    /// Control+Option+T 打开或收起。
    func testToggleOpensAndCloses() throws {
        let controller = try controllerWithPointerInsideHub()
        controller.start()
        defer { controller.stop() }

        controller.toggle()
        XCTAssertEqual(controller.state, .hover)

        controller.toggle()
        XCTAssertEqual(controller.state, .exit)

        waitUntil("收起后应该回到 HIDDEN") { controller.state == .hidden }
    }

    /// 面板出现时指针已经不在面板里，应该立刻收起，不留一个卡住的 Hub。
    func testHubCollapsesWhenThePointerIsOutside() throws {
        let controller = try controllerWithPointerAway()
        controller.start()
        defer { controller.stop() }

        controller.show()
        // 面板出现后立刻自查指针位置，发现不在面板里就走 EXIT。
        XCTAssertEqual(controller.state, .exit)

        waitUntil("收起后应该回到 HIDDEN") { controller.state == .hidden }
        XCTAssertFalse(controller.isHubPanelOnScreen)
    }

    // MARK: - 面板几何

    /// 面板显示在指针所在屏幕，且锚定顶部中央。
    func testPanelLandsOnThePointerScreen() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        let controller = try controllerWithPointerInsideHub()
        controller.start()
        defer { controller.stop() }

        controller.show()
        let frame = try XCTUnwrap(controller.hubPanelFrame)
        let expected = ScreenGeometry(screen: screen).expandedRect

        XCTAssertEqual(frame.midX, expected.midX, accuracy: 0.5)
        XCTAssertEqual(frame.maxY, expected.maxY, accuracy: 0.5)
        XCTAssertEqual(frame.width, expected.width, accuracy: 0.5)
    }

    /// 收起后热区面板回到屏幕上，Hub 让位。
    func testHotZoneComesBackAfterCollapse() throws {
        let controller = try controllerWithPointerInsideHub()
        controller.start()
        defer { controller.stop() }

        controller.show()
        waitUntil("展开后应该进入 ACTIVE") { controller.state == .active }
        controller.requestCollapse()
        waitUntil("收起后应该回到 HIDDEN") { controller.state == .hidden }

        // 状态回到 HIDDEN 后热区重新可用。
        XCTAssertTrue(controller.hotZoneRects.count > 0)
    }

    // MARK: - 内容态

    /// 内容区状态与面板状态正交。M1 只驱动到 READY。
    func testOutputStateIsCollapsedWhileHiddenAndReadyWhenActive() throws {
        let controller = try controllerWithPointerInsideHub()
        controller.start()
        defer { controller.stop() }

        XCTAssertEqual(controller.outputState, .collapsed)

        controller.show()
        waitUntil("展开后应该进入 ACTIVE") { controller.state == .active }
        XCTAssertEqual(controller.outputState, .ready)

        controller.requestCollapse()
        XCTAssertEqual(controller.outputState, .collapsed)
    }

    func testSelectingATabDoesNotChangeTheHubState() throws {
        let controller = try controllerWithPointerAway()
        controller.start()
        defer { controller.stop() }

        controller.selection = .screenshots
        XCTAssertEqual(controller.selection, .screenshots)
        XCTAssertEqual(controller.state, .hidden)
    }

    // MARK: - 宿主进程

    /// 测试是跑在被测应用进程里的，`AppDelegate` 已经启动了真正的 shell。
    /// 这条断言验证的是 M1 的装配真的生效，而不只是单元测试里能跑通。
    func testHostApplicationRunsTheShell() throws {
        let hotZones = NSApp.windows.compactMap { $0 as? HotZonePanel }
        let hubs = NSApp.windows.compactMap { $0 as? HubPanel }

        XCTAssertEqual(hotZones.count, NSScreen.screens.count, "宿主进程里每块屏幕应该有一个热区面板")
        XCTAssertEqual(hubs.count, 1, "宿主进程里应该只有一个 Hub 面板")

        for panel in hotZones {
            XCTAssertEqual(panel.level, .statusBar, "热区面板的层级必须高于菜单栏")
        }
        XCTAssertEqual(hubs.first?.level, .statusBar, "Hub 面板的层级必须高于菜单栏")
        XCTAssertFalse(try XCTUnwrap(hubs.first).isVisible, "启动时 Hub 应该收起")
    }
}
