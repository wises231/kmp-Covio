import SwiftUI

/// 玻璃底材的模式。
///
/// macOS 26 的 Liquid Glass 会采样背后的内容。Hub 面板是无边框透明窗口，
/// 所以玻璃采样到的就是桌面。
///
/// 这几个模式用于真机对照：同一个面板换底材截图，挑出最接近控制中心的那个。
/// 圆角、间距与排版在几种模式下完全一致，只有底材不同。
///
/// 真机取值：把面板开在一个带文字的窗口上，同一次会话内截收起态与展开态两张图，
/// 逐像素比对同一测点。先确认面板下方 `y=1200..2200` 全段相同，证明壁纸没变。
///
/// | 底材 | 同一测点抬起 | 卡片背后的文字 |
/// | --- | --- | --- |
/// | `.clear` | 约 +116 | 字形仍然是锐的，只是对比度降低 |
/// | `.regular` | 约 +165 | 完全读不出来 |
///
/// 只比抬起量会选 `.clear`，那是错的。决定能不能看清的是**模糊**，不是填充重量。
///
/// 控制中心的模块抬起只有 5 到 25 级，比 `.regular` 轻得多，但它模糊：
/// 模块之间那条缝在开态下亮度改变 29 到 30 级，放大 6 倍看，地形细节消失。
/// 工作台复现的是这一层模糊。填充的轻重是另一件事，见 `MacTheme.tintedCardOpacity`。
///
/// 所以取 `.regular`。它是 Liquid Glass 的标准材质，模糊足够强，
/// 也是能模糊的底材里填充最轻的一档。
enum GlassSurfaceMode: String, CaseIterable, Sendable {
    /// Liquid Glass 的标准材质。填充最重，亮边最宽。当前取值。
    case glass
    /// Liquid Glass 的清透材质。比 `glass` 更透，亮边更细，但几乎不模糊。
    case clear
    /// 常规毛玻璃。对照用。深色桌面上几乎看不出板。
    case material
    /// 超薄毛玻璃。对照用。没有亮边。
    case ultraThin

    /// 当前生效的模式。
    ///
    /// 只在主线程改：界面全部在主线程构建。
    /// 调试构建可以用环境变量 `COVIO_GLASS_SURFACE` 覆盖，便于同一次构建换材质截图。
    @MainActor static var current: GlassSurfaceMode = .glass

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
    /// `tint` 给玻璃上色，用于首页的彩色卡片。
    @MainActor
    func glassSurface(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        interactive: Bool = false,
        mode: GlassSurfaceMode? = nil
    ) -> some View {
        // 默认值在主线程取：`current` 是主线程隔离的，不能写在默认参数里。
        modifier(
            GlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                interactive: interactive,
                mode: mode ?? GlassSurfaceMode.current
            )
        )
    }
}

/// 玻璃底材。所有模式共用圆角。
private struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool
    let mode: GlassSurfaceMode

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// 把着色与交互开关套到玻璃变体上。
    private func variant(_ base: Glass) -> Glass {
        let tinted = tint.map { base.tint($0) } ?? base
        return interactive ? tinted.interactive() : tinted
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch mode {
        case .glass:
            content.glassEffect(variant(.regular), in: .rect(cornerRadius: cornerRadius))
        case .clear:
            content.glassEffect(variant(.clear), in: .rect(cornerRadius: cornerRadius))
        case .material:
            // 毛玻璃模式没有原生着色，用一层半透明填充代替。
            content
                .background(shape.fill(tint ?? .clear))
                .background(shape.fill(.regularMaterial))
        case .ultraThin:
            content
                .background(shape.fill(tint ?? .clear))
                .background(shape.fill(.ultraThinMaterial))
        }
    }
}
