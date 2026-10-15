import AppKit
import XCTest
@testable import Covio

/// 菜单栏胶囊的落位。
///
/// 位置由系统给不出：状态项由系统排，居中不了，刘海区也放不下，所以自己开窗。
/// 这里守的是「窗口落在屏幕内、让开刘海、菜单栏不可见时不出现」。
@MainActor
final class MenuBarCapsuleTests: XCTestCase {
    /// 本机内建屏的实测值。见 `docs/adr/adr-0001-macos-ui-swiftui.md` 实测 8。
    private let notched = ScreenGeometry(
        frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
        visibleFrame: CGRect(x: 0, y: 0, width: 1728, height: 1085),
        safeAreaTop: 32,
        notch: CGRect(x: 771.5, y: 1085, width: 185, height: 32)
    )

    private let notchless = ScreenGeometry(
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1055),
        safeAreaTop: 0,
        notch: nil
    )

    /// 全屏 Space：菜单栏藏起来了。
    private let fullScreen = ScreenGeometry(
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        safeAreaTop: 0,
        notch: nil
    )

    private let capsule = CGSize(width: 60, height: HubMetrics.menuBarCapsuleHeight)

    // MARK: - 落位

    /// 刘海屏上胶囊贴在刘海右侧，让开刘海那一条。
    func testTheCapsuleSitsBesideTheNotch() throws {
        let rect = notched.menuBarCapsuleRect(capsuleWidth: capsule.width, capsuleHeight: capsule.height)
        let notch = try XCTUnwrap(notched.notch)
        XCTAssertGreaterThanOrEqual(rect.minX, notch.maxX)
        XCTAssertEqual(rect.minX, notch.maxX + ScreenGeometry.capsuleNotchGap, accuracy: 0.001)
    }

    /// 非刘海屏上胶囊居中。
    func testTheCapsuleIsCenteredOnANotchlessScreen() {
        let rect = notchless.menuBarCapsuleRect(capsuleWidth: capsule.width, capsuleHeight: capsule.height)
        XCTAssertEqual(rect.midX, notchless.frame.midX, accuracy: 0.001)
    }

    /// 胶囊必须落在屏幕内，否则窗口会跑到屏幕外面。
    func testTheCapsuleStaysInsideTheScreen() {
        for geometry in [notched, notchless] {
            let rect = geometry.menuBarCapsuleRect(capsuleWidth: capsule.width, capsuleHeight: capsule.height)
            XCTAssertTrue(geometry.frame.contains(rect), "胶囊超出了屏幕")
        }
    }

    /// 胶囊竖直居中在菜单栏那一条里，不压到下面的窗口。
    func testTheCapsuleSitsInsideTheMenuBar() {
        for geometry in [notched, notchless] {
            let rect = geometry.menuBarCapsuleRect(capsuleWidth: capsule.width, capsuleHeight: capsule.height)
            XCTAssertLessThanOrEqual(rect.maxY, geometry.frame.maxY + 0.001)
            XCTAssertGreaterThanOrEqual(rect.minY, geometry.visibleFrame.maxY - 0.001)
            // 居中：上下留的空一样。
            XCTAssertEqual(
                geometry.frame.maxY - rect.maxY,
                rect.minY - geometry.visibleFrame.maxY,
                accuracy: 0.001
            )
        }
    }

    /// 刘海很宽、右边放不下时改放左边。
    func testAWideNotchPushesTheCapsuleToTheLeft() {
        let geometry = ScreenGeometry(
            frame: CGRect(x: 0, y: 0, width: 900, height: 800),
            visibleFrame: CGRect(x: 0, y: 0, width: 900, height: 768),
            safeAreaTop: 32,
            notch: CGRect(x: 380, y: 768, width: 460, height: 32)
        )
        let rect = geometry.menuBarCapsuleRect(capsuleWidth: capsule.width, capsuleHeight: capsule.height)
        XCTAssertLessThanOrEqual(rect.maxX, 380)
        XCTAssertTrue(geometry.frame.contains(rect))
    }

    // MARK: - 菜单栏高度

    /// 菜单栏高度从 `visibleFrame` 与 `frame` 的差算出来，不写死。
    func testTheMenuBarHeightIsMeasuredFromTheScreen() {
        XCTAssertEqual(notched.menuBarHeight, 32, accuracy: 0.001)
        XCTAssertEqual(notchless.menuBarHeight, 25, accuracy: 0.001)
    }

    /// 全屏 Space 里量不出菜单栏高度，回落到一个至少放得下胶囊的值。
    func testTheMenuBarHeightFallsBackWhenItIsHidden() {
        XCTAssertFalse(fullScreen.isMenuBarVisible)
        XCTAssertGreaterThanOrEqual(fullScreen.menuBarHeight, HubMetrics.menuBarCapsuleHeight)
    }

    // MARK: - 窗口矩形

    /// 窗口比胶囊大一圈悬停余量，指针滑到边上也算进来了。
    func testTheWindowIsLargerThanTheCapsuleByTheHoverInset() {
        let rect = MenuBarCapsulePanel.windowRect(for: capsule, on: notched)
        XCTAssertEqual(rect.width, capsule.width + HubMetrics.menuBarCapsuleHoverInset * 2, accuracy: 0.001)
        XCTAssertEqual(rect.height, capsule.height + HubMetrics.menuBarCapsuleHoverInset * 2, accuracy: 0.001)
    }

    /// 拿不到屏幕几何时窗口仍然有尺寸，不至于开出一个零大小的窗口。
    func testTheWindowHasASizeWithoutGeometry() {
        let rect = MenuBarCapsulePanel.windowRect(for: capsule, on: nil)
        XCTAssertGreaterThan(rect.width, 0)
        XCTAssertGreaterThan(rect.height, 0)
    }

    /// 窗口只包住胶囊，不铺满菜单栏。铺满会挡住菜单栏项与别的状态项。
    func testTheWindowDoesNotCoverTheWholeMenuBar() {
        for geometry in [notched, notchless] {
            let rect = MenuBarCapsulePanel.windowRect(for: capsule, on: geometry)
            XCTAssertLessThan(rect.width, geometry.frame.width / 4, "胶囊窗口太宽，会挡住别的菜单栏项")
        }
    }
}
