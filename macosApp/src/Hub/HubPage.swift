import Foundation

/// 面板当前要画的一页。
///
/// 首页不是工作区，网格行数要现算，所以它带一个参数。
/// 几何函数（`HubMetrics`）与视图都从这一个值取高度，两边不会算岔。
enum HubPage: Equatable, Sendable {
    /// 首页。参数是组件网格的行数，零表示没有组件。
    case home(rows: Int)
    /// 一个工作区。
    case pane(HubTab)

    /// 从目的地与工作台模型取当前页。
    @MainActor
    static func current(_ workbench: WorkbenchModel) -> HubPage {
        switch workbench.destination {
        case .home: .home(rows: workbench.homeRows)
        case .pane: .pane(workbench.tab(for: workbench.destination))
        }
    }
}
