import XCTest
@testable import Covio

/// `ScreenGeometry` 的几何测试。
///
/// 用手写的屏幕数值，不依赖运行测试的机器。
/// 数值取自 P0 在本机内建视网膜屏上的实测：1728 × 1117，顶部安全区 32 点，
/// 刘海占 x 从 771.5 到 956.5。见 `docs/adr/ADR-001-macos-ui-swiftui.md` 实测 8。
final class ScreenGeometryTests: XCTestCase {
    /// 本机实测的刘海屏。
    private let notched = ScreenGeometry(
        frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
        visibleFrame: CGRect(x: 0, y: 0, width: 1728, height: 1085),
        safeAreaTop: 32,
        notch: CGRect(x: 771.5, y: 1085, width: 185, height: 32)
    )

    /// 一台 1920 × 1080 的非刘海屏。
    private let notchless = ScreenGeometry(
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055),
        safeAreaTop: 0,
        notch: nil
    )

    // MARK: - 刘海屏

    func testNotchedHotZoneIsTheNotchItself() {
        XCTAssertTrue(notched.hasNotch)
        XCTAssertEqual(notched.hotZoneRect, notched.notch)
    }

    func testNotchedPanelHangsFromTheScreenTop() {
        XCTAssertEqual(notched.panelTop, 1117)
        XCTAssertEqual(notched.panelTopInset, 32)
    }

    func testNotchedExpandedRectIsCenteredAndTopAligned() {
        let rect = notched.expandedRect
        XCTAssertEqual(rect.width, 960)
        XCTAssertEqual(rect.maxY, 1117)
        XCTAssertEqual(rect.midX, 864)
        // 高度是顶部安全区加「现在」页的内容高度。
        XCTAssertEqual(rect.height, 32 + HubMetrics.contentHeight(for: .now), accuracy: 0.001)
    }

    func testNotchedCollapsedRectMatchesTheNotch() {
        let rect = notched.collapsedRect
        XCTAssertEqual(rect.size, notched.hotZoneRect.size)
        XCTAssertEqual(rect.maxY, 1117)
        XCTAssertEqual(rect.midX, 864)
    }

    /// 面板矩形必须完全落在屏幕内，否则窗口会跑到屏幕外面。
    func testExpandedRectStaysInsideTheScreen() {
        for geometry in [notched, notchless] {
            let rect = geometry.expandedRect
            XCTAssertTrue(geometry.frame.contains(rect), "面板矩形超出了屏幕")
        }
    }

    // MARK: - 非刘海屏

    func testNotchlessHotZoneSitsBelowTheMenuBar() {
        XCTAssertFalse(notchless.hasNotch)
        let zone = notchless.hotZoneRect
        XCTAssertEqual(zone.width, HubMetrics.notchlessHotZoneWidth)
        XCTAssertEqual(zone.height, HubMetrics.notchlessHotZoneHeight)
        // 上沿贴菜单栏下沿。
        XCTAssertEqual(zone.maxY, notchless.visibleFrame.maxY)
        XCTAssertEqual(zone.midX, 960)
    }

    func testNotchlessPanelStartsAtTheMenuBarBottom() {
        XCTAssertEqual(notchless.panelTop, 1055)
        XCTAssertEqual(notchless.panelTopInset, 0)
        XCTAssertEqual(notchless.expandedRect.maxY, 1055)
        XCTAssertEqual(notchless.expandedRect.height, HubMetrics.contentHeight(for: .now), accuracy: 0.001)
    }

    // MARK: - 全屏 Space

    func testMenuBarVisibilityDrivesTheHotZoneRule() {
        XCTAssertTrue(notched.isMenuBarVisible)
        XCTAssertTrue(notchless.isMenuBarVisible)

        // 全屏 Space 里菜单栏自动隐藏，可见区等于完整区。§4.4 要求此时隐藏热区。
        let fullScreen = ScreenGeometry(
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            safeAreaTop: 0,
            notch: nil
        )
        XCTAssertFalse(fullScreen.isMenuBarVisible)
    }

    // MARK: - 宽度限制

    func testHubWidthRespectsMinimumAndMaximum() {
        // 宽屏：用页签栏宽度 960。
        XCTAssertEqual(HubMetrics.hubWidth(screenWidth: 1728), 960)
        // 窄屏：屏幕宽度减 80 小于 960，取屏幕宽度减 80。
        XCTAssertEqual(HubMetrics.hubWidth(screenWidth: 900), 820)
        // 极窄屏：不低于最小宽度 720。
        XCTAssertEqual(HubMetrics.hubWidth(screenWidth: 700), 720)
    }

    func testHubMaxHeightLeavesRoomForTheDesktop() {
        XCTAssertEqual(HubMetrics.hubMaxHeight(screenHeight: 1117), 997)
        XCTAssertEqual(HubMetrics.hubMaxHeight(screenHeight: 100), 0)
    }

    // MARK: - 真实屏幕

    /// 真实屏幕上算出的热区必须落在该屏幕内。
    func testLiveScreenGeometryIsSelfConsistent() throws {
        let screen = try XCTUnwrap(NSScreen.main)
        let geometry = ScreenGeometry(screen: screen)

        let zone = geometry.hotZoneRect
        XCTAssertTrue(screen.frame.contains(zone), "热区超出了屏幕")
        XCTAssertTrue(screen.frame.contains(geometry.expandedRect), "面板矩形超出了屏幕")
        XCTAssertEqual(geometry.hasNotch, geometry.notch != nil)

        // 把实测值打出来，方便与 P0 的记录比对。
        print("""
        [P1] screen frame=\(screen.frame) visible=\(screen.visibleFrame)
        [P1] safeAreaTop=\(geometry.safeAreaTop) notch=\(String(describing: geometry.notch))
        [P1] hotZone=\(zone) expandedRect=\(geometry.expandedRect)
        [P1] menuBarVisible=\(geometry.isMenuBarVisible)
        """)
    }
}
