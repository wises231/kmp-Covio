import SwiftUI

/// 导航栏底部的呼吸灯。
///
/// 亮起表示引擎在跑，暗下表示已暂停。这是状态指示，不是按钮。
/// 「减弱动态效果」打开时不脉冲，只显示静止圆点。
struct RuntimePulse: View {
    let isActive: Bool
    let label: String
    let reduceMotion: Bool

    @State private var isDim = false

    /// 圆点直径。比导航栏行高小，不抢行内文字的位置。
    private let dotSize: CGFloat = 8

    var body: some View {
        HStack(spacing: MacTheme.space2) {
            Circle()
                .fill(isActive ? MacTheme.successText : MacTheme.textSecondary)
                .frame(width: dotSize, height: dotSize)
                .opacity(opacity)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(MacTheme.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(height: HubMetrics.railStatusHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .onAppear { syncAnimation() }
        .onChange(of: reduceMotion) { syncAnimation() }
        .onChange(of: isActive) { syncAnimation() }
    }

    /// 亮灭的两种不透明度。暗态不为零，否则看着像坏了。
    private var opacity: Double {
        guard isActive else { return 0.45 }
        return isDim ? 0.35 : 1
    }

    private func syncAnimation() {
        guard isActive, !reduceMotion else {
            withAnimation(.linear(duration: 0)) { isDim = false }
            return
        }
        withAnimation(
            .easeInOut(duration: HubMotion.pulse).repeatForever(autoreverses: true)
        ) {
            isDim = true
        }
    }
}
