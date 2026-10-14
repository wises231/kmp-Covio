import Foundation

/// Hub 的六个页签。
///
/// 顺序与名称来自 `docs/covio-product-master.md` 第 4.2 节的表格。
///
/// 导航栏是 960 × 52，与 `HubMetrics.tabBarWidth` / `tabBarHeight` 一致。
enum HubTab: String, CaseIterable, Identifiable, Sendable {
    case now = "Now"
    case clipboard = "Clipboard"
    case files = "Files"
    case screenshots = "Screenshots"
    case devices = "Devices"
    case settings = "Settings"

    var id: String { rawValue }

    /// 页签标题。
    var title: LocalizedCopy {
        switch self {
        case .now: Copy.copyHubTabNow
        case .clipboard: Copy.copyHubTabClipboard
        case .files: Copy.copyHubTabFiles
        case .screenshots: Copy.copyHubTabScreenshots
        case .devices: Copy.copyHubTabDevices
        case .settings: Copy.copyHubTabSettings
        }
    }

    /// 模块说明。逐条对应 §4.2 的"内容"列。
    var summary: LocalizedCopy {
        switch self {
        case .now: Copy.copyHubTabNowSummary
        case .clipboard: Copy.copyHubTabClipboardSummary
        case .files: Copy.copyHubTabFilesSummary
        case .screenshots: Copy.copyHubTabScreenshotsSummary
        case .devices: Copy.copyHubTabDevicesSummary
        case .settings: Copy.copyHubTabSettingsSummary
        }
    }

    /// 页签图标。§6.3 要求图标和文字同时显示。
    ///
    /// 页签图标用通用 SF Symbol。
    var symbolName: String {
        switch self {
        case .now: "power"
        case .clipboard: "doc.on.clipboard"
        case .files: "folder"
        case .screenshots: "camera.viewfinder"
        case .devices: "laptopcomputer.and.iphone"
        case .settings: "gearshape"
        }
    }
}
