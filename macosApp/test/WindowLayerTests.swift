import XCTest
import AppKit
import ApplicationServices

/// M0 spike：窗口层级与事件权限。
///
/// 三个问题：
/// 1. NSPanel 相对系统 UI 的正确 `level`。
/// 2. `isFloatingPanel` 与 `level` 的设置顺序是否有影响。
/// 3. 全局鼠标监听与合成事件是否需要辅助功能权限。
@MainActor
final class WindowLayerTests: XCTestCase {
    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle,
        ]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        return panel
    }

    /// 读系统 UI 窗口的实际层级，作为选 `level` 的依据。
    func testPrintSystemWindowLayers() {
        print("=== system window layers ===")
        print("NSWindow.Level.mainMenu  = \(NSWindow.Level.mainMenu.rawValue)")
        print("NSWindow.Level.statusBar = \(NSWindow.Level.statusBar.rawValue)")
        print("NSWindow.Level.popUpMenu = \(NSWindow.Level.popUpMenu.rawValue)")
        print("NSWindow.Level.screenSaver = \(NSWindow.Level.screenSaver.rawValue)")

        guard let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
            as? [[String: Any]] else {
            print("CGWindowListCopyWindowInfo returned nothing")
            return
        }
        let owners = [
            "Window Server", "Dock", "Control Center", "Notification Center",
            "SystemUIServer", "Spotlight",
        ]
        for window in info {
            guard let owner = window[kCGWindowOwnerName as String] as? String,
                  owners.contains(owner) else { continue }
            let layer = window[kCGWindowLayer as String] as? Int ?? -1
            let name = window[kCGWindowName as String] as? String ?? ""
            print("\(owner) layer=\(layer) name=\(name)")
        }
        print("=== end ===")
    }

    /// 顺序陷阱：`isFloatingPanel = true` 会把 `level` 重置为 `.floating`。
    func testFloatingPanelResetsLevel() {
        _ = NSApplication.shared

        let levelFirst = makePanel()
        levelFirst.isFloatingPanel = true
        levelFirst.level = .statusBar
        print("isFloatingPanel then level -> \(levelFirst.level.rawValue)")

        let floatingLast = makePanel()
        floatingLast.level = .statusBar
        floatingLast.isFloatingPanel = true
        print("level then isFloatingPanel -> \(floatingLast.level.rawValue)")

        let withoutFloating = makePanel()
        withoutFloating.level = .statusBar
        print("level without isFloatingPanel -> \(withoutFloating.level.rawValue)")

        // 这是 M1 必须遵守的顺序。
        XCTAssertEqual(
            levelFirst.level.rawValue,
            NSWindow.Level.statusBar.rawValue,
            "先设 isFloatingPanel 再设 level，level 才是 .statusBar"
        )
    }

    /// 全局鼠标监听与合成事件的权限现状。
    func testEventPermissions() {
        print("=== event permissions ===")
        print("AXIsProcessTrusted = \(AXIsProcessTrusted())")
        print("CGPreflightPostEventAccess = \(CGPreflightPostEventAccess())")

        let mouse = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in }
        print("global mouseMoved monitor registered = \(mouse != nil)")
        if let mouse { NSEvent.removeMonitor(mouse) }

        let key = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { _ in }
        print("global keyDown monitor registered = \(key != nil)")
        if let key { NSEvent.removeMonitor(key) }

        print("=== end ===")
    }
}
