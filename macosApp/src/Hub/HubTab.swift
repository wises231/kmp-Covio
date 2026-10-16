import Foundation

/// Hub 的六个页签。
///
/// 文案键与顺序由 `DesignContractTests` 守住。
///
/// 设计合同 `components["component/tab-bar"]` 的 `nativeSize` 是 960 × 52，
/// 与 `HubMetrics.tabBarWidth` / `tabBarHeight` 一致。
enum HubTab: String, CaseIterable, Identifiable, Sendable {
    case now = "Now"
    case clipboard = "Clipboard"
    case files = "Files"
    case screenshots = "Screenshots"
    case monitor = "Monitor"
    case settings = "Settings"

    var id: String { rawValue }

    /// 页签标题。
    var title: LocalizedCopy {
        switch self {
        case .now: ContractCopy.copyHubTabNow
        case .clipboard: ContractCopy.copyHubTabClipboard
        case .files: ContractCopy.copyHubTabFiles
        case .screenshots: ContractCopy.copyHubTabScreenshots
        case .monitor: ContractCopy.copyHubTabMonitor
        case .settings: ContractCopy.copyHubTabSettings
        }
    }

    /// 模块说明。
    var summary: LocalizedCopy {
        switch self {
        case .now: ContractCopy.copyHubTabNowSummary
        case .clipboard: ContractCopy.copyHubTabClipboardSummary
        case .files: ContractCopy.copyHubTabFilesSummary
        case .screenshots: ContractCopy.copyHubTabScreenshotsSummary
        case .monitor: ContractCopy.copyHubTabMonitorSummary
        case .settings: ContractCopy.copyHubTabSettingsSummary
        }
    }

    /// 页签图标。图标和文字同时显示。
    ///
    /// 合同没有给页签图标的名字，这里用通用 SF Symbol。
    var symbolName: String {
        switch self {
        case .now: "power"
        case .clipboard: "doc.on.clipboard"
        case .files: "folder"
        case .screenshots: "camera.viewfinder"
        case .monitor: "gauge.medium"
        case .settings: "gearshape"
        }
    }
}
