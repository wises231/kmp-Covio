import Foundation

/// 设置页签里的六个分节。
///
/// 名称与顺序来自设计合同 `copy/nav/*`。
/// 每节的标题与说明来自 `copy/page/*/title` 与 `copy/page/*/summary`。
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

    /// 分节导航上的短名称。合同 `copy/nav/*`。
    var navTitle: LocalizedCopy {
        switch self {
        case .overview: ContractCopy.copyNavOverview
        case .battery: ContractCopy.copyNavBattery
        case .lid: ContractCopy.copyNavLid
        case .idle: ContractCopy.copyNavIdle
        case .topShelf: ContractCopy.copyNavTopShelf
        case .general: ContractCopy.copyNavGeneral
        }
    }

    /// 页标题。合同 `copy/page/*/title`。
    var pageTitle: LocalizedCopy {
        switch self {
        case .overview: ContractCopy.copyPageOverviewTitle
        case .battery: ContractCopy.copyPageBatteryTitle
        case .lid: ContractCopy.copyPageLidTitle
        case .idle: ContractCopy.copyPageIdleTitle
        case .topShelf: ContractCopy.copyPageTopShelfSettingsTitle
        case .general: ContractCopy.copyPageGeneralTitle
        }
    }

    /// 页说明。合同 `copy/page/*/summary`。
    var pageSummary: LocalizedCopy {
        switch self {
        case .overview: ContractCopy.copyPageOverviewSummary
        case .battery: ContractCopy.copyPageBatterySummary
        case .lid: ContractCopy.copyPageLidSummary
        case .idle: ContractCopy.copyPageIdleSummary
        case .topShelf: ContractCopy.copyPageTopShelfSettingsSummary
        case .general: ContractCopy.copyPageGeneralSummary
        }
    }
}
