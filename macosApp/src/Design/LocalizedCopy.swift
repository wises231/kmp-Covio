import Foundation

/// 一条双语文案。
///
/// 文案本身一律写在 `Copy` 里，别处不得构造这个类型。
struct LocalizedCopy: Sendable, Equatable {
    let en: String
    let zhHans: String

    init(en: String, zhHans: String) {
        self.en = en
        self.zhHans = zhHans
    }

    /// 按当前系统语言取文案。
    ///
    /// 只有 `en` 与 `zh-Hans` 两种。其它语言回落到英文。
    var text: String { text(for: CopyLocale.language) }

    /// 按指定语言取文案。设置里改了语言后，界面走这一条。
    func text(for language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese: zhHans
        case .english: en
        }
    }
}

/// 界面语言。
///
/// 取值与 Kotlin 的 `AppLanguage` 一致：`en` 与 `zh-CN`。
/// `AppConfig.language` 存的就是这个码。
enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-CN"

    /// 按配置里的语言码取语言。空码或认不出的码回落到系统语言。
    static func fromCode(_ code: String?) -> AppLanguage {
        if let code, let match = AppLanguage(rawValue: code) { return match }
        return CopyLocale.prefersChinese ? .simplifiedChinese : .english
    }
}

enum CopyLocale {
    /// 系统首选语言是否是中文。
    static var prefersChinese: Bool {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh")
    }

    /// 系统语言。
    static var language: AppLanguage {
        prefersChinese ? .simplifiedChinese : .english
    }
}
