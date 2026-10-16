import Foundation

/// 设置界面用到的格式化。纯函数，好测。
enum SettingsFormat {
    /// 时长的中英文写法。与 Compose 版 `formatDuration` 一致。
    static func duration(seconds: Int64, language: AppLanguage) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        switch language {
        case .simplifiedChinese:
            return hours > 0 ? "\(hours)小时\(minutes)分" : "\(seconds / 60)分"
        case .english:
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(seconds / 60)m"
        }
    }

    /// 休眠模式的显示名。文案来自 `Copy`。
    ///
    /// 认不出的模式只显示数字：界面不能编一个名字。
    static func sleepModeLabel(_ mode: Int32, language: AppLanguage) -> String {
        switch mode {
        case 0: return Copy.copyGeneralSleepModeFastest.text(for: language)
        case 3: return Copy.copyGeneralSleepModeDefault.text(for: language)
        case 25: return Copy.copyGeneralSleepModeLowestPower.text(for: language)
        default: return "\(mode)"
        }
    }

    /// 上次 DarkWake 的时间。用系统时区，格式与 Compose 版一致。
    static func wakeTime(epochSeconds: Int64) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(epochSeconds)))
    }
}
