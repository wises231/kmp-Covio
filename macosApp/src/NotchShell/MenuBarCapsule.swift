import SwiftUI

/// 菜单栏上的品牌胶囊。合同 `component/tray-icon` 的收起态。
///
/// 高 20 点，胶囊圆角，底色 `token/color/brand`，横向内边距 8 点。
/// 内容是一个菱形加 `Covio` 五个字母，间距 5 点。
///
/// 指针悬停时底色变淡一点，给一个「能点」的反馈。
struct MenuBarCapsule: View {
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text("◈")
                .font(.system(size: 9))
                .accessibilityHidden(true)
            Text(Self.brandName)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .frame(height: HubMetrics.menuBarCapsuleHeight)
        .background(
            MacTheme.brand.opacity(isHovered ? 0.82 : 1),
            in: Capsule(style: .continuous)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.brandName)
    }

    /// 品牌名是专有名词，不进合同。合同里 `copy/tray/*` 是菜单项的文案。
    static let brandName = "Covio"
}
