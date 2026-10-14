import SwiftUI

/// Hub 顶部的悬浮紧凑胶囊。
///
/// 左边是当前页的标题，右边是当前页的动作。动作按页签区分：
/// 截图页三个动作、剪切板页两个动作、设置页六个分节。占位页只有标题。
///
/// 设置页不给标题：内容列放不下标题加六个分节，选中的分节本身就能当标题。
///
/// 高度取自 `HubMetrics`。玻璃底材由 `glassSurface` 提供。
struct HubToolbarCapsule<Actions: View>: View {
    var title: String?
    var summary: String?
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(spacing: MacTheme.space3) {
            if let title {
                HubCapsuleTitle(title: title, summary: summary)
                Spacer(minLength: MacTheme.space2)
            }
            actions
        }
        .padding(.horizontal, MacTheme.space4)
        .frame(height: HubMetrics.toolbarCapsuleHeight)
        .frame(maxWidth: .infinity, alignment: title == nil ? .center : .leading)
        .glassSurface(cornerRadius: HubMetrics.toolbarCapsuleHeight / 2, interactive: true)
    }
}

/// 胶囊里的页标题。
///
/// 标题与说明并排一行。胶囊只有 40 点高，竖排会顶掉动作的位置。
/// 说明是补充信息，宽度不够时先被截断。
struct HubCapsuleTitle: View {
    let title: String
    var summary: String?

    var body: some View {
        HStack(spacing: MacTheme.space2) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MacTheme.textPrimary)
                .lineLimit(1)
                .layoutPriority(1)
            if let summary {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundStyle(MacTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(width: HubMetrics.capsuleTitleWidth, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// 设置页胶囊里的六个分节切换。
///
/// 选中态由系统分段控件画。分节名取自 `SettingsSection`。
struct SettingsSectionSegments: View {
    @Binding var section: SettingsSection
    let language: AppLanguage

    var body: some View {
        Picker("", selection: $section) {
            ForEach(SettingsSection.allCases) { item in
                Text(item.navTitle.text(for: language)).tag(item)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .accessibilityLabel(Copy.copyHubTabSettings.text(for: language))
    }
}
