// 界面用的颜色、尺寸与动效取值。
//
// 改这里就是改界面。没有上游文件需要同步。

import CoreGraphics
import Foundation

/// 一枚颜色。值是十六进制字符串，浅色与深色各一份。
///
/// `MacTheme` 负责把它转成随外观变化的颜色。
struct TokenColor: Sendable, Equatable {
    let lightHex: String
    let darkHex: String
}

/// 界面用的颜色。
enum TokenColors {
    /// System emphasis color for controls, selection, and focus rings.
    static let tokenColorAccentSystem = TokenColor(lightHex: "#007AFF", darkHex: "#0A84FF")
    /// System action fill, focus ring, and active icon fill.
    static let tokenColorActionFill = TokenColor(lightHex: "#0A84FF", darkHex: "#0A84FF")
    /// Action text, links, and small action labels.
    static let tokenColorActionText = TokenColor(lightHex: "#0066CC", darkHex: "#4DA3FF")
    /// Covio brand fill and selected emphasis.
    static let tokenColorBrand = TokenColor(lightHex: "#4656A4", darkHex: "#4656A4")
    /// Brand hover feedback.
    static let tokenColorBrandHover = TokenColor(lightHex: "#3B4A93", darkHex: "#5966A8")
    /// Brand pressed feedback.
    static let tokenColorBrandPressed = TokenColor(lightHex: "#2E3A75", darkHex: "#23304D")
    /// Default page canvas.
    static let tokenColorCanvas = TokenColor(lightHex: "#F2F2F7", darkHex: "#1C1C1E")
    /// Default native control fill.
    static let tokenColorControlFill = TokenColor(lightHex: "#FFFFFF", darkHex: "#3A3A3C")
    /// Hovered native control fill.
    static let tokenColorControlFillHover = TokenColor(lightHex: "#F0F0F2", darkHex: "#48484A")
    /// Pressed native control fill.
    static let tokenColorControlFillPressed = TokenColor(lightHex: "#E5E5EA", darkHex: "#545456")
    /// Inactive control text and nonessential disabled labels.
    static let tokenColorDisabledText = TokenColor(lightHex: "#98989D", darkHex: "#98989D")
    /// Separators, control borders, and subtle outlines.
    static let tokenColorDivider = TokenColor(lightHex: "#D1D1D6", darkHex: "#3A3A3C")
    /// Elevated neutral surfaces and grouped controls.
    static let tokenColorElevated = TokenColor(lightHex: "#F7F7F9", darkHex: "#3A3A3C")
    /// Subtle error background.
    static let tokenColorErrorBg = TokenColor(lightHex: "#FFF0F1", darkHex: "#3E151A")
    /// Error fill and error icon foreground.
    static let tokenColorErrorFill = TokenColor(lightHex: "#D70015", darkHex: "#D70015")
    /// Error text.
    static let tokenColorErrorText = TokenColor(lightHex: "#D70015", darkHex: "#FF6961")
    /// Keyboard focus ring color.
    static let tokenColorFocusRing = TokenColor(lightHex: "#007AFF", darkHex: "#0A84FF")
    /// Informational background.
    static let tokenColorInfoBg = TokenColor(lightHex: "#EEF5FF", darkHex: "#102743")
    /// Medium light and dark material fill.
    static let tokenColorMaterialMedium = TokenColor(lightHex: "#FFFFFFC7", darkHex: "#1C1C1E94")
    /// Thick light and dark material fill.
    static let tokenColorMaterialThick = TokenColor(lightHex: "#FFFFFFDB", darkHex: "#1C1C1EAD")
    /// Thin light and dark material fill.
    static let tokenColorMaterialThin = TokenColor(lightHex: "#FFFFFFB2", darkHex: "#1C1C1E7A")
    /// Ultra-thick light and dark material fill.
    static let tokenColorMaterialUltraThick = TokenColor(lightHex: "#FFFFFFEF", darkHex: "#1C1C1EC7")
    /// Ultra-thin light and dark material fill.
    static let tokenColorMaterialUltraThin = TokenColor(lightHex: "#FFFFFF9E", darkHex: "#1C1C1E61")
    /// Selected menu-item fill.
    static let tokenColorMenuSelection = TokenColor(lightHex: "#007AFF", darkHex: "#0A84FF")
    /// Muted fills and tertiary visual elements.
    static let tokenColorMuted = TokenColor(lightHex: "#B6B6BC", darkHex: "#636366")
    /// Modal and popover overlay color.
    static let tokenColorOverlay = TokenColor(lightHex: "#00000033", darkHex: "#00000080")
    /// Modal scrim.
    static let tokenColorScrim = TokenColor(lightHex: "#00000033", darkHex: "#00000073")
    /// Divider and separator color.
    static let tokenColorSeparator = TokenColor(lightHex: "#D1D1D6", darkHex: "#3A3A3C")
    /// Window, menu, and card shadow.
    static let tokenColorShadow = TokenColor(lightHex: "#0000002E", darkHex: "#00000059")
    /// Sidebar material fill.
    static let tokenColorSidebarFill = TokenColor(lightHex: "#F2F2F7E6", darkHex: "#1C1C1ED9")
    /// Slider and range-control track fill.
    static let tokenColorSliderTrack = TokenColor(lightHex: "#D1D1D6", darkHex: "#48484A")
    /// Subtle success background.
    static let tokenColorSuccessBg = TokenColor(lightHex: "#E5F8EA", darkHex: "#14351D")
    /// Success fill and success icon foreground.
    static let tokenColorSuccessFill = TokenColor(lightHex: "#34C759", darkHex: "#34C759")
    /// Success text.
    static let tokenColorSuccessText = TokenColor(lightHex: "#1E7A34", darkHex: "#6EDB84")
    /// Cards, windows, and primary surfaces.
    static let tokenColorSurface = TokenColor(lightHex: "#FFFFFF", darkHex: "#2C2C2E")
    /// Text and icon color on blue accent fills.
    static let tokenColorTextOnAccent = TokenColor(lightHex: "#FFFFFF", darkHex: "#FFFFFF")
    /// Primary text and monochrome icon foreground.
    static let tokenColorTextPrimary = TokenColor(lightHex: "#1D1D1F", darkHex: "#F5F5F7")
    /// Secondary supporting text.
    static let tokenColorTextSecondary = TokenColor(lightHex: "#6E6E73", darkHex: "#AEAEB2")
    /// Toolbar material fill.
    static let tokenColorToolbarFill = TokenColor(lightHex: "#F7F7F9E6", darkHex: "#2C2C2ED9")
    /// Subtle warning background.
    static let tokenColorWarningBg = TokenColor(lightHex: "#FFF2DC", darkHex: "#3A2A08")
    /// Warning fill and warning icon foreground.
    static let tokenColorWarningFill = TokenColor(lightHex: "#FF9F0A", darkHex: "#FF9F0A")
    /// Warning text.
    static let tokenColorWarningText = TokenColor(lightHex: "#8A4B00", darkHex: "#FFB340")
    /// Window title-bar and chrome fill.
    static let tokenColorWindowChrome = TokenColor(lightHex: "#F5F5F7", darkHex: "#2C2C2E")
    /// macOS close window button.
    static let tokenColorWindowClose = TokenColor(lightHex: "#FF5F57", darkHex: "#FF5F57")
    /// macOS minimize window button.
    static let tokenColorWindowMinimize = TokenColor(lightHex: "#FEBC2E", darkHex: "#FEBC2E")
    /// macOS zoom window button.
    static let tokenColorWindowZoom = TokenColor(lightHex: "#28C840", darkHex: "#28C840")

    static let all: [TokenColor] = [
        tokenColorAccentSystem,
        tokenColorActionFill,
        tokenColorActionText,
        tokenColorBrand,
        tokenColorBrandHover,
        tokenColorBrandPressed,
        tokenColorCanvas,
        tokenColorControlFill,
        tokenColorControlFillHover,
        tokenColorControlFillPressed,
        tokenColorDisabledText,
        tokenColorDivider,
        tokenColorElevated,
        tokenColorErrorBg,
        tokenColorErrorFill,
        tokenColorErrorText,
        tokenColorFocusRing,
        tokenColorInfoBg,
        tokenColorMaterialMedium,
        tokenColorMaterialThick,
        tokenColorMaterialThin,
        tokenColorMaterialUltraThick,
        tokenColorMaterialUltraThin,
        tokenColorMenuSelection,
        tokenColorMuted,
        tokenColorOverlay,
        tokenColorScrim,
        tokenColorSeparator,
        tokenColorShadow,
        tokenColorSidebarFill,
        tokenColorSliderTrack,
        tokenColorSuccessBg,
        tokenColorSuccessFill,
        tokenColorSuccessText,
        tokenColorSurface,
        tokenColorTextOnAccent,
        tokenColorTextPrimary,
        tokenColorTextSecondary,
        tokenColorToolbarFill,
        tokenColorWarningBg,
        tokenColorWarningFill,
        tokenColorWarningText,
        tokenColorWindowChrome,
        tokenColorWindowClose,
        tokenColorWindowMinimize,
        tokenColorWindowZoom,
    ]
}

/// 界面用的尺寸。半径、间距、材质不透明度。
enum TokenDimensions {
    /// Figma material blur radius.
    static let tokenMaterialBlur: CGFloat = 60
    /// Medium material opacity.
    static let tokenMaterialOpacityMedium: CGFloat = 0.78
    /// Thick material opacity.
    static let tokenMaterialOpacityThick: CGFloat = 0.86
    /// Thin material opacity.
    static let tokenMaterialOpacityThin: CGFloat = 0.7
    /// Ultra-thick material opacity.
    static let tokenMaterialOpacityUltraThick: CGFloat = 0.94
    /// Ultra-thin material opacity.
    static let tokenMaterialOpacityUltraThin: CGFloat = 0.62
    /// Card corner radius.
    static let tokenRadiusCard: CGFloat = 12
    /// Compact surface corner radius.
    static let tokenRadiusCompact: CGFloat = 8
    /// Native control corner radius.
    static let tokenRadiusControl: CGFloat = 6
    /// Cards and screenshot cards.
    static let tokenRadiusLarge: CGFloat = 16
    /// Sequoia material and surface corner radius.
    static let tokenRadiusMaterial: CGFloat = 12
    /// Buttons and status labels.
    static let tokenRadiusMedium: CGFloat = 12
    /// Pill buttons and status labels.
    static let tokenRadiusPill: CGFloat = 999
    /// Popover, alert, and dialog corner radius.
    static let tokenRadiusPopover: CGFloat = 10
    /// Inputs and small controls.
    static let tokenRadiusSmall: CGFloat = 8
    /// Tight icon and label spacing.
    static let tokenSpace1: CGFloat = 4
    /// Page top and bottom padding.
    static let tokenSpace10: CGFloat = 40
    /// Compact control spacing.
    static let tokenSpace2: CGFloat = 8
    /// Setting row spacing.
    static let tokenSpace3: CGFloat = 12
    /// Card inner padding.
    static let tokenSpace4: CGFloat = 16
    /// Primary card group spacing.
    static let tokenSpace5: CGFloat = 20
    /// Card-to-card spacing.
    static let tokenSpace6: CGFloat = 24
    /// Page section spacing.
    static let tokenSpace8: CGFloat = 32

}

/// 一枚动效时长。
///
/// 单位是秒，与 `TimeInterval` 一致。
/// `curve` 是曲线的中文描述。
/// `reducedSeconds` 是「减弱动态效果」下的时长。没有就为 nil。
struct MotionToken: Sendable, Equatable {
    let seconds: TimeInterval
    let minSeconds: TimeInterval
    let maxSeconds: TimeInterval
    let reducedSeconds: TimeInterval?
    let curve: String
}

/// 界面用的动效时长。
enum Motion {
    /// 错误出现。来源第 6.4 节：160 毫秒，淡入和轻微位移。
    static let tokenMotionErrorAppear = MotionToken(seconds: 0.16, minSeconds: 0.16, maxSeconds: 0.16, reducedSeconds: nil, curve: "淡入和轻微位移")
    /// Hub 收起。来源第 6.4 节：160 至 220 毫秒，缓出曲线。
    static let tokenMotionHubCollapse = MotionToken(seconds: 0.19, minSeconds: 0.16, maxSeconds: 0.22, reducedSeconds: 0.12, curve: "缓出曲线")
    /// Hub 展开。来源 covio-product-master.md 第 6.4 节：220 至 280 毫秒，弹性曲线。
    static let tokenMotionHubExpand = MotionToken(seconds: 0.25, minSeconds: 0.22, maxSeconds: 0.28, reducedSeconds: 0.12, curve: "弹性曲线")
    /// 指针移出 Hub 后收起的等待时间。来源 covio-product-master.md 第 4.4 节。
    static let tokenMotionPointerExitCollapse = MotionToken(seconds: 0.5, minSeconds: 0.5, maxSeconds: 0.5, reducedSeconds: nil, curve: "指针移出后等待，然后收起")
    /// 减弱动态效果。来源第 6.4 节：120 毫秒，只改变透明度。
    static let tokenMotionReducedMotion = MotionToken(seconds: 0.12, minSeconds: 0.12, maxSeconds: 0.12, reducedSeconds: nil, curve: "只改变透明度")
    /// 截图捕获。来源第 6.4 节：650 毫秒，保留现有捕获动画。
    static let tokenMotionScreenshotCapture = MotionToken(seconds: 0.65, minSeconds: 0.65, maxSeconds: 0.65, reducedSeconds: nil, curve: "保留现有捕获动画")
    /// 截图复制。来源第 6.4 节：1200 毫秒提示，保留现有摆动反馈。
    static let tokenMotionScreenshotCopy = MotionToken(seconds: 1.2, minSeconds: 1.2, maxSeconds: 1.2, reducedSeconds: nil, curve: "保留现有摆动反馈")
    /// 页签切换。来源第 6.4 节：160 毫秒，横向滑动加淡入。
    static let tokenMotionTabSwitch = MotionToken(seconds: 0.16, minSeconds: 0.16, maxSeconds: 0.16, reducedSeconds: nil, curve: "横向滑动加淡入")
    /// 传输完成。来源第 6.4 节：240 毫秒，进度变为完成状态。
    static let tokenMotionTransferComplete = MotionToken(seconds: 0.24, minSeconds: 0.24, maxSeconds: 0.24, reducedSeconds: nil, curve: "进度变为完成状态")
    /// 传输开始。来源第 6.4 节：180 毫秒，卡片抬起并显示进度。
    static let tokenMotionTransferStart = MotionToken(seconds: 0.18, minSeconds: 0.18, maxSeconds: 0.18, reducedSeconds: nil, curve: "卡片抬起并显示进度")

}
