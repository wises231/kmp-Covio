import SwiftUI

/// 编辑模式的提示条。
///
/// 一行说明加一句计数，右端一个「完成」。底色取合同 `token/color/info-bg`。
///
/// 它只在编辑模式里出现，所以高度算进 `HubMetrics.editBannerHeight`。
struct EditBanner: View {
    let paneCount: Int
    let widgetCount: Int
    let language: AppLanguage
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: MacTheme.space3) {
            Text(ContractCopy.copyHubEditBanner.text(for: language))
                .font(.system(size: 11))
                .foregroundStyle(MacTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            Text(counter)
                .font(.system(size: 11))
                .foregroundStyle(MacTheme.textSecondary)
                .lineLimit(1)
                .layoutPriority(1)

            MacButton(title: ContractCopy.copyHubActionDone.text(for: language), action: onDone)
        }
        .padding(.horizontal, MacTheme.space3)
        .frame(height: HubMetrics.editBannerHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            MacTheme.infoBackground,
            in: RoundedRectangle(cornerRadius: MacTheme.controlRadius, style: .continuous)
        )
        .accessibilityElement(children: .contain)
    }

    /// 「6 个工作区 · 6 块组件」。
    private var counter: String {
        let panes = "\(paneCount) \(ContractCopy.copyHubEditWorkspaceCount.text(for: language))"
        let widgets = "\(widgetCount) \(ContractCopy.copyHubEditWidgetCount.text(for: language))"
        return "\(panes) · \(widgets)"
    }
}
