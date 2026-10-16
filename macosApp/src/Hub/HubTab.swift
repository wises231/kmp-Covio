import Foundation

/// Hub 的六个页签。
///
/// 顺序即声明顺序，文案取自 `Copy`。
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

    /// 模块说明。
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

    /// 页签图标。图标和文字同时显示。
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
