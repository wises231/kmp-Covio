import XCTest
import AppKit

/// M0 spike：打印刘海与热区所需的屏幕量。
///
/// M1 的 NSPanel 定位要用这些值。本测试只记录事实，断言只做基本合理性检查。
/// 结果写进 docs/adr/adr-0001-macos-ui-swiftui.md 的未决事项表。
@MainActor
final class ScreenMetricsTests: XCTestCase {
    func testPrintScreenMetrics() {
        print("=== ScreenMetrics ===")
        print("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        print("screens: \(NSScreen.screens.count)")

        for (index, screen) in NSScreen.screens.enumerated() {
            print("--- screen \(index)")
            print("frame: \(screen.frame)")
            print("visibleFrame: \(screen.visibleFrame)")
            print("safeAreaInsets: \(screen.safeAreaInsets)")
            print("backingScaleFactor: \(screen.backingScaleFactor)")
            print("localizedName: \(screen.localizedName)")

            for key in [
                NSDeviceDescriptionKey("NSDeviceSize"),
                NSDeviceDescriptionKey("NSScreenNumber"),
            ] {
                if let value = screen.deviceDescription[key] {
                    print("\(key.rawValue): \(value)")
                }
            }

            if #available(macOS 12.0, *) {
                print("auxiliaryTopLeftArea: \(String(describing: screen.auxiliaryTopLeftArea))")
                print("auxiliaryTopRightArea: \(String(describing: screen.auxiliaryTopRightArea))")
            }
        }

        print("frontmostApplication: \(String(describing: NSWorkspace.shared.frontmostApplication?.bundleIdentifier))")
        print("=== end ===")

        XCTAssertFalse(NSScreen.screens.isEmpty, "至少应有一块屏幕")
        for screen in NSScreen.screens {
            XCTAssertGreaterThan(screen.frame.width, 0)
            XCTAssertGreaterThanOrEqual(screen.safeAreaInsets.top, 0)
            if #available(macOS 12.0, *) {
                XCTAssertGreaterThanOrEqual(screen.auxiliaryTopLeftArea?.width ?? 0, 0)
            }
        }
    }
}
