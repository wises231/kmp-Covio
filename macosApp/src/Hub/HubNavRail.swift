import SwiftUI

/// Hub 左侧的悬浮导航栏。
///
/// 顶部是搜索栏，中间是六个页签，底部是运行状态、设置、语言与退出。
/// 对应合同 `component/tab-bar`，`nativeSize` 是 200 × 370。
///
/// 高度是固定值：内容用 `Spacer` 撑开，所以内容再少也不会缩。
struct HubNavRail: View {
    @Binding var selection: HubTab
    @Bindable var chrome: HubChromeModel
    let language: AppLanguage
    /// 引擎在跑。呼吸灯用它。
    let isActive: Bool
    let reduceMotion: Bool
    let onLanguage: (AppLanguage) -> Void
    let onQuit: () -> Void

    @Namespace private var selectionNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
            Spacer(minLength: 0).frame(height: HubMetrics.railSectionGap)
            navItems
            Spacer(minLength: HubMetrics.railSectionGap)
            bottomGroup
        }
        .padding(HubMetrics.railPadding)
        .frame(width: HubMetrics.navRailWidth, height: HubMetrics.navRailHeight, alignment: .top)
        .glassSurface(cornerRadius: MacTheme.cardRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ContractCopy.copyNavRailLabel.text(for: language))
    }

    // MARK: - 搜索

    private var searchField: some View {
        HStack(spacing: MacTheme.space1) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(MacTheme.textSecondary)
                .accessibilityHidden(true)
            TextField(placeholder, text: $chrome.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, MacTheme.space2)
        .frame(height: HubMetrics.railSearchHeight)
        .background(
            MacTheme.elevated,
            in: RoundedRectangle(cornerRadius: MacTheme.compactRadius, style: .continuous)
        )
        .accessibilityLabel(placeholder)
    }

    private var placeholder: String {
        ContractCopy.copyNavSearchPlaceholder.text(for: language)
    }

    // MARK: - 页签

    private var navItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(HubTab.allCases) { tab in
                navItem(tab)
            }
        }
    }

    private func navItem(_ tab: HubTab) -> some View {
        let isSelected = tab == selection
        return Button {
            select(tab)
        } label: {
            HStack(spacing: MacTheme.space2) {
                Image(systemName: tab.symbolName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .frame(width: 16)
                    .accessibilityHidden(true)
                Text(tab.title.text(for: language))
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? MacTheme.textPrimary : MacTheme.textSecondary)
            .padding(.horizontal, MacTheme.space2)
            .frame(height: HubMetrics.railItemHeight)
            .contentShape(Rectangle())
            .background(selectionBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title.text(for: language))
        .accessibilityHint(tab.summary.text(for: language))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// 选中态是一块滑块。页签切换时滑块滑到新位置，所以用 `matchedGeometryEffect`。
    @ViewBuilder
    private func selectionBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: MacTheme.controlRadius, style: .continuous)
                .fill(MacTheme.elevated)
                .matchedGeometryEffect(id: Self.selectionID, in: selectionNamespace)
        } else {
            Color.clear
        }
    }

    private func select(_ tab: HubTab) {
        guard tab != selection else { return }
        if reduceMotion {
            selection = tab
        } else {
            withAnimation(.easeOut(duration: HubMotion.tabSwitch)) {
                selection = tab
            }
        }
    }

    // MARK: - 底部组

    private var bottomGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            RuntimePulse(isActive: isActive, label: statusText, reduceMotion: reduceMotion)
            Spacer(minLength: 0).frame(height: HubMetrics.railRowGap)
            settingsRow
            Spacer(minLength: 0).frame(height: HubMetrics.railRowGap)
            languageRow
            Spacer(minLength: 0).frame(height: HubMetrics.railRowGap)
            quitRow
        }
    }

    private var statusText: String {
        let copy = isActive ? ContractCopy.copyNavStatusRunning : ContractCopy.copyNavStatusPaused
        return copy.text(for: language)
    }

    private var settingsRow: some View {
        bottomButton(
            symbolName: "gearshape",
            title: ContractCopy.copyHubTabSettings.text(for: language),
            isSelected: selection == .settings
        ) {
            select(.settings)
        }
    }

    private var languageRow: some View {
        Menu {
            ForEach(AppLanguage.allCases, id: \.self) { option in
                Button(languageName(option)) { onLanguage(option) }
            }
        } label: {
            HStack(spacing: MacTheme.space2) {
                Image(systemName: "globe")
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .accessibilityHidden(true)
                Text(languageName(language))
                    .font(.system(size: 12))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(MacTheme.textSecondary)
            .padding(.horizontal, MacTheme.space2)
            .frame(height: HubMetrics.railItemHeight)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .accessibilityLabel(ContractCopy.copyGeneralLanguage.text(for: language))
    }

    /// 退出是不可逆动作，所以排在底部组最后一项。
    private var quitRow: some View {
        bottomButton(symbolName: "power", title: ContractCopy.copyNavQuit.text(for: language)) {
            onQuit()
        }
    }

    private func bottomButton(
        symbolName: String,
        title: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: MacTheme.space2) {
                Image(systemName: symbolName)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? MacTheme.textPrimary : MacTheme.textSecondary)
            .padding(.horizontal, MacTheme.space2)
            .frame(height: HubMetrics.railItemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    /// 语言名用当前界面语言显示。
    private func languageName(_ display: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese: ContractCopy.copyGeneralLanguageChinese.text(for: display)
        case .english: ContractCopy.copyGeneralLanguageEnglish.text(for: display)
        }
    }

    /// 选中滑块的身份。同一个命名空间里只能有一块。
    private static let selectionID = "hub-rail-selection"
}
