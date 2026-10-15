import SwiftUI

/// 顶栏上的一个工作区。
///
/// 视图不直接拿 `PaneInstance`：那是 Kotlin 的类，名字随时可能被配置改掉。
/// 这里只留画一条页签要用的三样。
struct PaneItem: Identifiable, Equatable, Sendable {
    let id: String
    let tab: HubTab
    /// 已经解析好的显示名。用户改过名就是用户的名字。
    let title: String

    var glyph: String { tab.glyph }
}

/// 挂帘顶部的横向页签栏。合同 `component/tab-bar`，`nativeSize` 是 960 × 46。
///
/// 左端固定是首页入口，紧挨着搜索框，中间是工作区页签，右端是当前页的动作。
/// 选中态由一块胶囊滑块画，160 毫秒横向滑动。
/// 编辑模式里页签前面加拖动把手，横向拖过 84 点换一次位置。
struct WorkbenchTabBar: View {
    let panes: [PaneItem]
    let destination: HubDestination
    let isEditing: Bool
    @Binding var searchText: String
    let language: AppLanguage
    let pageAction: LocalizedCopy
    let onHome: () -> Void
    let onSelect: (String) -> Void
    let onReorder: (Int, Int) -> Void
    let onPageAction: () -> Void

    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: HubMetrics.tabBarItemGap) {
            homeEntry
            searchField
            tabStrip
            pageActionButton
        }
        .padding(.horizontal, HubMetrics.tabBarHPadding)
        .frame(width: HubMetrics.tabBarWidth, height: HubMetrics.tabBarHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ContractCopy.copyNavRailLabel.text(for: language))
    }

    // MARK: - 首页入口

    /// 固定在左端，不参与排序，也不随页签滚动。
    private var homeEntry: some View {
        let isSelected = destination == .home
        return Button(action: onHome) {
            Text("▦")
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? MacTheme.color(ContractColors.tokenColorTextOnAccent) : MacTheme.textPrimary)
                .frame(width: HubMetrics.homeEntryWidth, height: HubMetrics.homeEntryHeight)
                .background(
                    isSelected ? MacTheme.accent : Color.primary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: MacTheme.controlRadius, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ContractCopy.copyHubActionHome.text(for: language))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - 搜索

    private var searchField: some View {
        HStack(spacing: MacTheme.space1) {
            Text("⌕")
                .font(.system(size: 13))
                .foregroundStyle(MacTheme.textSecondary)
                .accessibilityHidden(true)
            TextField(placeholder, text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .disabled(isEditing)
        }
        .padding(.horizontal, MacTheme.space2)
        .frame(width: HubMetrics.searchFieldWidth, height: HubMetrics.searchFieldHeight)
        .background(
            isEditing ? Color.primary.opacity(0.06) : MacTheme.elevated,
            in: RoundedRectangle(cornerRadius: MacTheme.controlRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MacTheme.controlRadius, style: .continuous)
                .strokeBorder(MacTheme.divider, lineWidth: 1)
        )
        .accessibilityLabel(placeholder)
    }

    private var placeholder: String {
        ContractCopy.copyNavSearchPlaceholder.text(for: language)
    }

    // MARK: - 页签

    private var tabStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: HubMetrics.tabGap) {
                ForEach(Array(panes.enumerated()), id: \.element.id) { index, pane in
                    tab(pane, at: index)
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.never)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tab(_ pane: PaneItem, at index: Int) -> some View {
        let isSelected = destination == .pane(id: pane.id)
        return Button {
            guard !isEditing else { return }
            onSelect(pane.id)
        } label: {
            HStack(spacing: MacTheme.space1) {
                if isEditing {
                    Text("⣿")
                        .font(.system(size: 11))
                        .foregroundStyle(MacTheme.textSecondary)
                        .accessibilityHidden(true)
                }
                Text(pane.glyph)
                    .font(.system(size: 11))
                    .foregroundStyle(isSelected ? onAccent : MacTheme.textSecondary)
                    .accessibilityHidden(true)
                Text(pane.title)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? onAccent : MacTheme.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, HubMetrics.tabHPadding)
            .frame(height: HubMetrics.tabHeight)
            .background(selectionPill(isSelected: isSelected))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pane.title)
        .accessibilityHint(pane.tab.summary.text(for: language))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .gesture(isEditing ? reorderGesture(index: index) : nil)
    }

    /// 选中态是一块胶囊滑块。页签切换时滑块滑到新位置。
    @ViewBuilder
    private func selectionPill(isSelected: Bool) -> some View {
        if isSelected {
            Capsule(style: .continuous)
                .fill(MacTheme.accent)
                .matchedGeometryEffect(id: Self.selectionID, in: selectionNamespace)
        } else {
            Color.clear
        }
    }

    private var onAccent: Color {
        MacTheme.color(ContractColors.tokenColorTextOnAccent)
    }

    /// 编辑模式里的拖动排序。跨过一条页签的宽度就换一次位置。
    private func reorderGesture(index: Int) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                let moves = Int(value.translation.width / HubMetrics.tabReorderStep)
                guard moves != 0 else { return }
                onReorder(index, index + moves)
            }
    }

    // MARK: - 当前页的动作

    private var pageActionButton: some View {
        Button(action: onPageAction) {
            Text(pageAction.text(for: language))
                .font(.system(size: 12))
                .foregroundStyle(MacTheme.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, HubMetrics.actionHPadding)
                .frame(minWidth: HubMetrics.actionButtonMinWidth, minHeight: HubMetrics.tabHeight)
                .background(
                    Color.primary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: MacTheme.controlRadius, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pageAction.text(for: language))
    }

    /// 选中滑块的身份。同一个命名空间里只能有一块。
    private static let selectionID = "workbench-tab-selection"
}
