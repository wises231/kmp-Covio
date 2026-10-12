import SwiftUI

/// 玻璃底材的模式。
///
/// macOS 26 的 Liquid Glass 会采样背后的内容。Hub 面板是无边框透明窗口，
/// 卡片自身是 `.regularMaterial`，所以玻璃采样到的是卡片底材。
/// `.material` 模式用于真机对照与预览：两种模式的圆角与描边一致。
enum GlassSurfaceMode: String, CaseIterable, Sendable {
    /// Liquid Glass。
    case glass
    /// 常规毛玻璃。对照用。
    case material

    /// 当前生效的模式。改这里可以整站切换，便于截图对照。
    ///
    /// 只在主线程改：界面全部在主线程构建。
    @MainActor static var current: GlassSurfaceMode = .glass
}

extension View {
    /// 给视图加一层玻璃底材与圆角。
    ///
    /// 圆角由调用方从 `MacTheme` 取，不在这里写数值。
    @MainActor
    func glassSurface(
        cornerRadius: CGFloat,
        interactive: Bool = false,
        mode: GlassSurfaceMode = GlassSurfaceMode.current
    ) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, interactive: interactive, mode: mode))
    }
}

/// 玻璃底材。两种模式共用圆角。
private struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool
    let mode: GlassSurfaceMode

    @ViewBuilder
    func body(content: Content) -> some View {
        switch mode {
        case .glass:
            content.glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
        case .material:
            content.background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
            )
        }
    }
}
