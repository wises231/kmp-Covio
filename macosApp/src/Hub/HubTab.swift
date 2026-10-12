import Foundation

/// Hub 的六个页签。
///
/// 顺序与名称来自 `docs/covio-product-master.md` 第 4.2 节的表格。
/// `DesignContractTests` 会解析那张表并逐项比对，防止顺序被改乱。
///
/// 设计合同 `components["component/tab-bar"]` 的 `nativeSize` 是 960 × 52，
/// 与 `HubMetrics.tabBarWidth` / `tabBarHeight` 一致。
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
        case .now: ContractCopy.copyHubTabNow
        case .clipboard: ContractCopy.copyHubTabClipboard
        case .files: ContractCopy.copyHubTabFiles
        case .screenshots: ContractCopy.copyHubTabScreenshots
        case .devices: ContractCopy.copyHubTabDevices
        case .settings: ContractCopy.copyHubTabSettings
        }
    }

    /// 模块说明。逐条对应 §4.2 的"内容"列。
    var summary: LocalizedCopy {
        switch self {
        case .now: ContractCopy.copyHubTabNowSummary
        case .clipboard: ContractCopy.copyHubTabClipboardSummary
        case .files: ContractCopy.copyHubTabFilesSummary
        case .screenshots: ContractCopy.copyHubTabScreenshotsSummary
        case .devices: ContractCopy.copyHubTabDevicesSummary
        case .settings: ContractCopy.copyHubTabSettingsSummary
        }
    }

    /// 页签图标。§6.3 要求图标和文字同时显示。
    ///
    /// 合同没有给页签图标的名字，这里用通用 SF Symbol。
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
