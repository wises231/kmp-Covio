import AppKit
import SwiftUI

/// 设计令牌到 SwiftUI 的映射。
///
/// 取值全部来自 `Tokens.swift`。
/// 这一层只做两件事：十六进制转颜色，浅色深色合成一个动态颜色。
/// 不在这里写任何字面量色值。
enum MacTheme {
    // MARK: - 颜色

    /// 页面底色。
    static let canvas = color(TokenColors.tokenColorCanvas)
    /// 卡片与窗口表面。
    static let surface = color(TokenColors.tokenColorSurface)
    /// 抬起的表面。
    static let elevated = color(TokenColors.tokenColorElevated)
    /// 分隔线与控件描边。
    static let divider = color(TokenColors.tokenColorDivider)
    /// 主文字。
    static let textPrimary = color(TokenColors.tokenColorTextPrimary)
    /// 次要文字。
    static let textSecondary = color(TokenColors.tokenColorTextSecondary)
    /// 禁用文字。
    static let disabledText = color(TokenColors.tokenColorDisabledText)
    /// 系统强调色。
    static let accent = color(TokenColors.tokenColorAccentSystem)
    /// 品牌色。选中态用它。
    static let brand = color(TokenColors.tokenColorBrand)
    /// 动作填充。
    static let actionFill = color(TokenColors.tokenColorActionFill)
    /// 键盘焦点环。
    static let focusRing = color(TokenColors.tokenColorFocusRing)
    /// 错误文字。
    static let errorText = color(TokenColors.tokenColorErrorText)
    /// 错误底色。
    static let errorBackground = color(TokenColors.tokenColorErrorBg)
    /// 警告文字。
    static let warningText = color(TokenColors.tokenColorWarningText)
    /// 警告底色。
    static let warningBackground = color(TokenColors.tokenColorWarningBg)
    /// 成功文字。
    static let successText = color(TokenColors.tokenColorSuccessText)
    /// 成功底色。
    static let successBackground = color(TokenColors.tokenColorSuccessBg)
    /// 信息底色。
    static let infoBackground = color(TokenColors.tokenColorInfoBg)
    /// 卡片与窗口阴影。
    static let shadow = color(TokenColors.tokenColorShadow)

    // MARK: - 尺寸

    /// 卡片圆角。
    static let cardRadius = TokenDimensions.tokenRadiusCard
    /// 控件圆角。
    static let controlRadius = TokenDimensions.tokenRadiusControl
    /// 输入框圆角。
    static let smallRadius = TokenDimensions.tokenRadiusSmall
    /// 按钮圆角。
    static let mediumRadius = TokenDimensions.tokenRadiusMedium
    /// 紧凑表面圆角。
    static let compactRadius = TokenDimensions.tokenRadiusCompact

    /// 间距 4。
    static let space1 = TokenDimensions.tokenSpace1
    /// 间距 8。
    static let space2 = TokenDimensions.tokenSpace2
    /// 设置行间距 12。
    static let space3 = TokenDimensions.tokenSpace3
    /// 卡片内边距 16。
    static let space4 = TokenDimensions.tokenSpace4
    /// 卡片组间距 20。
    static let space5 = TokenDimensions.tokenSpace5
    /// 卡片间距 24。
    static let space6 = TokenDimensions.tokenSpace6
    /// 页面分节间距 32。
    static let space8 = TokenDimensions.tokenSpace8
    /// 页面上下留白 40。
    static let space10 = TokenDimensions.tokenSpace10

    // MARK: - 转换

    /// 把一枚颜色令牌转成随外观变化的 SwiftUI 颜色。
    static func color(_ token: TokenColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return nsColor(hex: isDark ? token.darkHex : token.lightHex)
        })
    }

    /// 解析十六进制色值。支持 `#RRGGBB` 与 `#RRGGBBAA`。
    ///
    /// 8 位色值把透明度放在最后两位，与 CSS 一致。
    /// 认不出的色值返回洋红色，好让错误一眼可见。
    static func nsColor(hex: String) -> NSColor {
        var text = hex
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6 || text.count == 8, let value = UInt64(text, radix: 16) else {
            return .magenta
        }
        let hasAlpha = text.count == 8
        let red = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let green = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let blue = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let alpha = hasAlpha ? CGFloat(value & 0xFF) / 255 : 1
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}
