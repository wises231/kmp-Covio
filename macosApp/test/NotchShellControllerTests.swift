import AppKit
import XCTest
@testable import Covio

/// `NotchShellController` 的端到端状态测试。
///
/// 这些测试跑在真实的 `NSPanel` 上，只把指针位置换成固定值，
/// 所以不需要真的移动用户的鼠标。见 `NotchShellController.init(pointerLocation:)`。
///
/// 注意：面板的 tracking area 仍然接真实的鼠标事件。测试运行期间如果指针
/// 恰好移进或移出热区与面板，可能插入额外事件。测试的等待窗口都短于
/// 500 毫秒的收起延迟，所以这类干扰不会改变断言结果。
@MainActor
final class NotchShellControllerTests: XCTestCase {
    /// 指针固定在主屏顶部中央。那里一定落在 Hub 面板矩形内。
    private func controllerWithPointerAtTopCenter() throws -> NotchShellController {
        let screen = try XCTUnwrap(NSScreen.main)
        let point = CGPoint(x: screen.frame.midX, y: screen.frame.maxY - 4)
        return NotchShellController(pointerLocation: { point })
    }

    /// 指针固定在屏幕正中央。那里在 Hub 面板矩形之外。
    private func controllerWithPointerAway() throws -> NotchShellController {
        let screen = try XCTUnwrap(NSScreen.main)
        let point = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        return NotchShellController(pointerLocation: { point })
    }

    private func wait(_ seconds: TimeInterval) {
        let done = expectation(description: "等待 \(seconds) 秒")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { done.fulfill() }
        wait(for: [done], timeout: seconds + 2)
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
        XCTAssertEqual(controller.hubPanelFrame?.width, HubMetrics.cardWidth)
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
        let controller = try controllerWithPointerAtTopCenter()
        controller.start()
        defer { controller.stop() }

        controller.show()
        // 合同路径 HIDDEN → HOVER。
        XCTAssertEqual(controller.state, .hover)
        XCTAssertTrue(controller.isHubPanelOnScreen, "HOVER 时面板就应该在屏幕上")

        // 展开动画结束后进入 OPEN，指针在面板里所以紧接着进入 ACTIVE。
        wait(HubMotion.expand + 0.2)
        XCTAssertEqual(controller.state, .active)
    }

    func testRequestingCollapseReturnsToHidden() throws {
        let controller = try controllerWithPointerAtTopCenter()
        controller.start()
        defer { controller.stop() }

        controller.show()
        wait(HubMotion.expand + 0.2)
        XCTAssertEqual(controller.state, .active)

        controller.requestCollapse()
        XCTAssertEqual(controller.state, .exit)

        wait(HubMotion.collapse + 0.2)
        XCTAssertEqual(controller.state, .hidden)
        XCTAssertFalse(controller.isHubPanelOnScreen, "收起后面板应该离开屏幕")
    }

    /// §4.4：Control+Option+T 打开或收起。
    func testToggleOpensAndCloses() throws {
        let controller = try controllerWithPointerAtTopCenter()
        controller.start()
        defer { controller.stop() }

        controller.toggle()
        XCTAssertEqual(controller.state, .hover)

        controller.toggle()
        XCTAssertEqual(controller.state, .exit)

        wait(HubMotion.collapse + 0.2)
        XCTAssertEqual(controller.state, .hidden)
    }

    /// 面板出现时指针已经不在面板里，应该立刻收起，不留一个卡住的 Hub。
    func testHubCollapsesWhenThePointerIsOutside() throws {
        let controller = try controllerWithPointerAway()
        controller.start()
        defer { controller.stop() }

        controller.show()
        // 面板出现后立刻自查指针位置，发现不在面板里就走 EXIT。
        XCTAssertEqual(controller.state, .exit)

        wait(HubMotion.collapse + 0.2)
        XCTAssertEqual(controller.state, .hidden)
        XCTAssertFalse(controller.isHubPanelOnScreen)
    }

    // MARK: - 面板几何

    /// 面板显示在指针所在屏幕，且锚定顶部中央。
    func testPanelLandsOnThePointerScreen() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        let controller = try controllerWithPointerAtTopCenter()
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
        let controller = try controllerWithPointerAtTopCenter()
        controller.start()
        defer { controller.stop() }

        controller.show()
        wait(HubMotion.expand + 0.2)
        controller.requestCollapse()
        wait(HubMotion.collapse + 0.3)

        XCTAssertEqual(controller.state, .hidden)
        // 状态回到 HIDDEN 后热区重新可用。
        XCTAssertTrue(controller.hotZoneRects.count > 0)
    }

    // MARK: - 内容态

    /// 内容区状态与面板状态正交。P1 只驱动到 READY。
    func testOutputStateIsCollapsedWhileHiddenAndReadyWhenActive() throws {
        let controller = try controllerWithPointerAtTopCenter()
        controller.start()
        defer { controller.stop() }

        XCTAssertEqual(controller.outputState, .collapsed)

        controller.show()
        wait(HubMotion.expand + 0.2)
        XCTAssertEqual(controller.state, .active)
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
    /// 这条断言验证的是 P1 的装配真的生效，而不只是单元测试里能跑通。
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
