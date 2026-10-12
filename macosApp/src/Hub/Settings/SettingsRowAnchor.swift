import SwiftUI

/// 当前要突出的设置行。搜索跳转后高亮 1.2 秒。
private struct HighlightedSettingsRowKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// 要高亮的行锚点。没有搜索跳转时是 nil。
    var highlightedSettingsRow: String? {
        get { self[HighlightedSettingsRowKey.self] }
        set { self[HighlightedSettingsRowKey.self] = newValue }
    }
}

extension View {
    /// 给一行设置加锚点。搜索跳转靠它滚动与高亮。
    ///
    /// 用修饰器而不是直接写 `.id(_:)`，是为了让高亮也只写一处：
    /// 各页只管给出锚点，不必知道当前有没有搜索跳转。
    func settingsRowAnchor(_ rowID: String) -> some View {
        modifier(SettingsRowAnchor(rowID: rowID))
    }
}

private struct SettingsRowAnchor: ViewModifier {
    let rowID: String

    @Environment(\.highlightedSettingsRow) private var highlighted

    private var isHighlighted: Bool { highlighted == rowID }

    func body(content: Content) -> some View {
        content
            .id(rowID)
            .padding(MacTheme.space1)
            .background(
                RoundedRectangle(cornerRadius: MacTheme.compactRadius, style: .continuous)
                    .fill(isHighlighted ? MacTheme.elevated : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MacTheme.compactRadius, style: .continuous)
                    .strokeBorder(isHighlighted ? MacTheme.brand : .clear, lineWidth: 1)
            )
    }
}
