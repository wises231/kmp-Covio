import SwiftUI

/// 玻璃底材的模式。
///
/// macOS 26 的 Liquid Glass 会采样背后的内容。Hub 面板是无边框透明窗口，
/// 所以玻璃采样到的就是桌面。
///
/// 这几个模式用于真机对照：同一个面板换底材截图，挑出最接近控制中心的那个。
/// 圆角、间距与排版在几种模式下完全一致，只有底材不同。
///
/// 真机取值（`x=800` 那条竖线，同一张截图里比对板内与板间的缝）：
///
/// | 底材 | 深色桌面上抬起 |
/// | --- | --- |
/// | `.regular` | 约 +44 |
/// | 控制中心模块 | 约 +24 |
/// | `.regularMaterial` | 约 +1 |
/// | `.ultraThinMaterial` | 约 +3 |
///
/// 控制中心落在 `.regular` 与毛玻璃之间，所以取更透的 `.clear`。
/// 它同时满足两条要求：板的填充更淡，亮边更细。
enum GlassSurfaceMode: String, CaseIterable, Sendable {
    /// Liquid Glass 的标准材质。填充最重，亮边最宽。
    case glass
    /// Liquid Glass 的清透材质。比 `glass` 更透，亮边更细。当前取值。
    case clear
    /// 常规毛玻璃。对照用。深色桌面上几乎看不出板。
    case material
    /// 超薄毛玻璃。对照用。没有亮边。
    case ultraThin

    /// 当前生效的模式。
    ///
    /// 只在主线程改：界面全部在主线程构建。
    /// 调试构建可以用环境变量 `COVIO_GLASS_SURFACE` 覆盖，便于同一次构建换材质截图。
    @MainActor static var current: GlassSurfaceMode = .clear

    /// 从环境变量取覆盖值。取值不认识时保持原样。
    @MainActor static func applyEnvironmentOverride() {
        #if DEBUG
        guard let raw = ProcessInfo.processInfo.environment["COVIO_GLASS_SURFACE"],
              let mode = GlassSurfaceMode(rawValue: raw) else { return }
        current = mode
        NSLog("Covio 玻璃底材被环境变量改成 \(mode.rawValue)。")
        #endif
    }
}

extension View {
    /// 给视图加一层玻璃底材与圆角。
    ///
    /// 圆角由调用方从 `MacTheme` 取，不在这里写数值。
    @MainActor
    func glassSurface(
        cornerRadius: CGFloat,
        interactive: Bool = false,
        mode: GlassSurfaceMode? = nil
    ) -> some View {
        // 默认值在主线程取：`current` 是主线程隔离的，不能写在默认参数里。
        modifier(
            GlassSurfaceModifier(
                cornerRadius: cornerRadius,
                interactive: interactive,
                mode: mode ?? GlassSurfaceMode.current
            )
        )
    }
}

/// 玻璃底材。所有模式共用圆角。
private struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let interactive: Bool
    let mode: GlassSurfaceMode

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch mode {
        case .glass:
            content.glassEffect(
                interactive ? .regular.interactive() : .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
        case .clear:
            content.glassEffect(
                interactive ? .clear.interactive() : .clear,
                in: .rect(cornerRadius: cornerRadius)
            )
        case .material:
            content.background(shape.fill(.regularMaterial))
        case .ultraThin:
            content.background(shape.fill(.ultraThinMaterial))
        }
    }
}
