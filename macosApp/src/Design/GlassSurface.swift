import AppKit
import SwiftUI

/// 玻璃底材的模式。
///
/// macOS 26 的 Liquid Glass 会采样背后的内容。Hub 面板是无边框透明窗口，
/// 所以玻璃采样到的就是桌面。
///
/// 控制中心是两层：
///
/// 1. 一块面板级的**模糊底板**，把桌面与工作区分开。
/// 2. 模块叠在底板上，自己走 **clear**，只加一层薄高光，不再重复模糊。
///
/// 真机对照：把一个带文字的 TextEdit 窗口摆在面板下面。控制中心打开后，
/// 整片面板区域（模块内部、模块之间、模块周围）的文字全被抹成灰条。
/// 模糊来自底板，不是来自模块本身。
///
/// 所以 `.clear` 只有在**底下已经有模糊**时才成立。单独把 `.clear` 压在桌面上，
/// 背后窗口的文字会原样透上来，与卡片自己的正文撞在一起。
///
/// 现在的分派：
///
/// | 位置 | 底材 | 理由 |
/// | --- | --- | --- |
/// | 内容区底板 | `.ultraThin` | 模糊层，不带边框，与控制中心的底板一致 |
/// | 内容区的卡片 | `.clear` | 叠在底板上，不重复模糊，保留 Liquid Glass 的亮边 |
/// | 顶栏板 | `.glass` | 它是独立胶囊，保留亮边 |
///
/// 底板不带边框是有意的：控制中心的**模块**有亮边，**底板**没有。
/// 两块板的区别在真机上放大左上角就能看出来，见 [plateMode]。
///
/// 两块板都不加着色：真机实测，压平传递曲线的是那层黑色着色，见 [plateTintOpacity]。
/// 卡片只带一点点色相，见 `MacTheme.tintedCardOpacity`。
///
/// 这几个模式也用于真机对照：同一个面板换底材截图，挑出最接近控制中心的那个。
/// 圆角、间距与排版在几种模式下完全一致，只有底材不同。
enum GlassSurfaceMode: String, CaseIterable, Sendable {
    /// Liquid Glass 的标准材质。模糊到位，自带一圈镜面亮边。卡片用它。
    ///
    /// 真机实测（2026-10-17，满量程渐变垫在背后，浅色外观，着色 0）：
    /// 桌面亮度从 24 级变到 207 级，面板从 152 级走到 243 级，斜率 0.50。
    /// 加一层黑 0.4 着色以后曲线被压到 62 到 118 级，斜率掉到 0.28 —— 那才是死灰板。
    case glass
    /// Liquid Glass 的清透材质。几乎不模糊，只加薄高光。叠在模糊上面的模块用它。
    case clear
    /// 常规毛玻璃。对照用。斜率 0.34。
    case material
    /// 超薄毛玻璃。斜率 0.49，亮度范围 132 到 221。不带边框。底板用它。
    case ultraThin
    /// 系统材质（`NSVisualEffectView`）。只做半透明模糊，不自适应。对照用。
    ///
    /// 材质种类由 [plateMaterial] 定。它和 `.ultraThin` 是同一类东西，
    /// 只是能换的材质更多，扫值的时候用它。
    case system

    /// 当前生效的模式。
    ///
    /// 只在主线程改：界面全部在主线程构建。
    /// 调试构建可以用环境变量 `COVIO_GLASS_SURFACE` 覆盖，便于同一次构建换材质截图。
    ///
    /// 这里只影响没显式传 `mode` 的调用点，也就是叠在底板上的那些卡片。
    @MainActor static var current: GlassSurfaceMode = .clear

    /// `.system` 模式用的材质。
    ///
    /// 取值是 `NSVisualEffectView.Material` 的名字。真机对照用它扫值。
    @MainActor static var plateMaterial: NSVisualEffectView.Material = .hudWindow

    /// 材质名字到系统材质的对照。认不出的名字返回 nil。
    static func material(named name: String) -> NSVisualEffectView.Material? {
        switch name {
        case "hudWindow": return .hudWindow
        case "popover": return .popover
        case "menu": return .menu
        case "sidebar": return .sidebar
        case "fullScreenUI": return .fullScreenUI
        case "contentBackground": return .contentBackground
        case "windowBackground": return .windowBackground
        case "underWindowBackground": return .underWindowBackground
        case "underPageBackground": return .underPageBackground
        case "titlebar": return .titlebar
        case "headerView": return .headerView
        case "sheet": return .sheet
        case "toolTip": return .toolTip
        default: return nil
        }
    }

    /// 底板的着色不透明度。取 0 到 1 的黑色。默认 0，不加着色。
    ///
    /// 为什么取 0：真机实测（2026-10-17，满量程黑白渐变垫在面板背后，浅色外观）。
    /// 同一种 Liquid Glass，加一层黑 0.4 着色以后曲线被压到 62 到 118 级，
    /// 斜率从 0.50 掉到 0.28。工作台此前看起来像一块死灰板，压平曲线的是这层着色。
    ///
    /// 取值由**传递曲线**定，不由单点差定。桌面亮度分箱，取每箱里面板的平均亮度，
    /// 得到一条线。线的斜率就是底材的有效透明度，与桌面内容无关。
    ///
    /// | 底材 | 斜率 | 面板亮度范围 |
    /// | --- | --- | --- |
    /// | 控制中心 | 0.71 | 66 → 196 |
    /// | `.glass`，不着色 | 0.50 | 152 → 243 |
    /// | `.ultraThin` | 0.49 | 132 → 221 |
    /// | `.glass`，黑 0.4 着色 | 0.28 | 62 → 118 |
    ///
    /// 调试构建可以用 `COVIO_PLATE_TINT` 覆盖。真机对照用它扫值。
    @MainActor static var plateTintOpacity: Double = 0

    /// 底板用的底材。默认 `.ultraThin`：不带边框的模糊层，与控制中心的底板一致。
    ///
    /// 为什么不用 `.glass`：Liquid Glass 自带一圈镜面亮边。控制中心的**模块**有亮边，
    /// **底板**没有。真机对照（2026-10-17）：把两块板的左上角放大，工作台的内容板
    /// 沿上边缘有一条浅蓝亮线，控制中心的底板边缘是干净的。
    ///
    /// 斜率上两者几乎一样（0.49 对 0.50），但 `.ultraThin` 的整体更暗一档
    /// （132 到 221 对 152 到 243），离控制中心的 66 到 196 更近。
    ///
    /// 卡片的亮边保留：卡片走 `.clear` 玻璃，与控制中心的模块一样带边。
    ///
    /// 调试构建可以用 `COVIO_PLATE_MODE` 覆盖，用来复核别的底材。
    @MainActor static var plateMode: GlassSurfaceMode = .ultraThin

    /// 顶栏板用的底材。默认 `.glass`：它是一块独立的胶囊，保留亮边。
    ///
    /// 底板不带边框，顶栏板带 —— 两者不同是有意的。顶栏板是与底板分开的一块，
    /// 两块都去掉边框以后，中间那道 11 点的缝就只剩明度差，读起来像一整块面板。
    /// 控制中心里凡是独立成块的元素都带亮边。
    ///
    /// 调试构建可以用 `COVIO_TOPBAR_MODE` 覆盖。
    @MainActor static var topBarMode: GlassSurfaceMode = .glass

    /// 底板的填充倍率。1 是底材原样，0 是只剩桌面。
    ///
    /// **它同时控制模糊和可见度，两者不可分开。** 底材的输出是
    /// `α·模糊(桌面) + (1−α)·填充色`。乘上这个倍率 p 以后，
    /// 桌面按 `1 − α(1−p)` 直接透上来，填充按 `p(1−α)F` 留下。
    /// 所以 p 越小，板越接近桌面，**同时**糊得越轻。
    ///
    /// 真机实测（2026-10-17，满量程渐变垫在背后，浅色外观，`.ultraThin`）：
    ///
    /// | p | 传递曲线 | 条纹残留 |
    /// | --- | --- | --- |
    /// | 1.0 | 0.53·桌面 + 98 | 0% |
    /// | 0.5 | 0.77·桌面 + 49 | 50% |
    /// | 0.3 | 0.86·桌面 + 29 | 70% |
    /// | 0.1 | 0.95·桌面 + 10 | 90% |
    ///
    /// 控制中心的底板实测是 `0.95·桌面 + 0.4`，条纹残留 2%。
    /// 也就是说控制中心**既有满量程模糊，又几乎不加填充**。
    /// 这需要 α≈0.95 的底材。实测下来公开接口里没有：
    /// 会模糊的材质 α 最高只有 0.59（`.clear` 玻璃），填充色都在 200 以上；
    /// 唯一 α 到 0.93 的 `.selection` 根本不模糊（条纹残留 91%）。
    /// 手工搭的 `CABackdropLayer`（AppKit 自己那套滤镜）实测 α=0.61、填充 140，
    /// 也到不了。所以这个组合取不到，只能在这条线上选一点。
    ///
    /// 当前取 1.0：模糊拉满，桌面细节全部抹平，与控制中心一致。
    /// 代价是填充也拉满，板比桌面亮 98 级。取小值能把板压到与桌面齐平，
    /// 但背后窗口的文字会跟着透上来 —— 那正是控制中心不会发生的事。
    /// 两者不可兼得，这里选模糊。
    ///
    /// 调试构建可以用 `COVIO_PLATE_OPACITY` 覆盖，用来复核别的取值。
    @MainActor static var plateOpacity: Double = 1.0

    /// 底板用的着色。不透明度是 0 时返回 nil，玻璃走原样。
    @MainActor static var plateTint: Color? {
        plateTintOpacity > 0 ? .black.opacity(plateTintOpacity) : nil
    }

    /// 从环境变量取覆盖值。取值不认识时保持原样。
    @MainActor static func applyEnvironmentOverride() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if let raw = env["COVIO_GLASS_SURFACE"], let mode = GlassSurfaceMode(rawValue: raw) {
            current = mode
            NSLog("Covio 玻璃底材被环境变量改成 \(mode.rawValue)。")
        }
        if let raw = env["COVIO_PLATE_TINT"], let value = Double(raw) {
            plateTintOpacity = min(max(value, 0), 1)
            NSLog("Covio 底板着色被环境变量改成 \(plateTintOpacity)。")
        }
        if let raw = env["COVIO_PLATE_MODE"], let mode = GlassSurfaceMode(rawValue: raw) {
            plateMode = mode
            NSLog("Covio 底板底材被环境变量改成 \(mode.rawValue)。")
        }
        if let raw = env["COVIO_TOPBAR_MODE"], let mode = GlassSurfaceMode(rawValue: raw) {
            topBarMode = mode
            NSLog("Covio 顶栏板底材被环境变量改成 \(mode.rawValue)。")
        }
        if let raw = env["COVIO_PLATE_MATERIAL"], let material = GlassSurfaceMode.material(named: raw) {
            plateMaterial = material
            NSLog("Covio 底板材质被环境变量改成 \(raw)。")
        }
        if let raw = env["COVIO_PLATE_OPACITY"], let value = Double(raw) {
            plateOpacity = min(max(value, 0), 1)
            NSLog("Covio 底板填充倍率被环境变量改成 \(plateOpacity)。")
        }
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
                .background(shape.fill(.regularMaterial).opacity(GlassSurfaceMode.plateOpacity))
        case .ultraThin:
            content
                .background(shape.fill(tint ?? .clear))
                .background(shape.fill(.ultraThinMaterial).opacity(GlassSurfaceMode.plateOpacity))
        case .system:
            content
                .background(shape.fill(tint ?? .clear))
                .background(SystemBackdrop(material: GlassSurfaceMode.plateMaterial, cornerRadius: cornerRadius))
        }
    }
}

/// 系统材质做的半透明模糊底。
///
/// `blendingMode` 取 `.behindWindow`：模糊的是窗口背后的桌面。
/// 面板是无边框透明窗口，所以这一层看到的就是桌面。
///
/// `state` 取 `.active`。默认的 `.followsWindowActiveState` 会在应用不是前台时
/// 把材质调淡，面板是 `.nonactivatingPanel`，点它不激活应用，会被误判成非前台。
private struct SystemBackdrop: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = material
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.layer?.cornerRadius = cornerRadius
    }
}
