import Foundation

/// 设置页签里的六个分节。
///
/// 名称与顺序固定。每节的标题与说明来自 `Copy`。
///
/// 切换由顶部胶囊里的分段控件驱动，状态住在 `HubChromeModel.settingsSection`。
enum SettingsSection: String, CaseIterable, Identifiable, Sendable {
    case overview
    case battery
    case lid
    case idle
    case topShelf
    case general

    var id: String { rawValue }

    /// 分节导航上的短名称。
    var navTitle: LocalizedCopy {
        switch self {
        case .overview: Copy.copyNavOverview
        case .battery: Copy.copyNavBattery
        case .lid: Copy.copyNavLid
        case .idle: Copy.copyNavIdle
        case .topShelf: Copy.copyNavTopShelf
        case .general: Copy.copyNavGeneral
        }
    }

    /// 页标题。
    var pageTitle: LocalizedCopy {
        switch self {
        case .overview: Copy.copyPageOverviewTitle
        case .battery: Copy.copyPageBatteryTitle
        case .lid: Copy.copyPageLidTitle
        case .idle: Copy.copyPageIdleTitle
        case .topShelf: Copy.copyPageTopShelfSettingsTitle
        case .general: Copy.copyPageGeneralTitle
        }
    }

    /// 页说明。
    var pageSummary: LocalizedCopy {
        switch self {
        case .overview: Copy.copyPageOverviewSummary
        case .battery: Copy.copyPageBatterySummary
        case .lid: Copy.copyPageLidSummary
        case .idle: Copy.copyPageIdleSummary
        case .topShelf: Copy.copyPageTopShelfSettingsSummary
        case .general: Copy.copyPageGeneralSummary
        }
    }
}
