import Foundation

/// 一条搜索命中。
struct SettingsSearchHit: Sendable, Equatable, Identifiable {
    let rowID: String
    let section: SettingsSection
    /// 命中的设置项。
    let entry: SettingsCatalogEntry

    var id: String { rowID }
}

/// 设置项的搜索。纯函数，不碰界面，所以可以单独测。
///
/// 匹配规则：
/// - 空查询返回空结果。清空搜索框就等于关掉搜索。
/// - 不区分大小写。
/// - 查标题、说明与关键词。关键词里同时有中文与英文，所以两种界面语言都能搜到。
/// - 结果按目录表顺序返回，也就是按分节顺序。
enum SettingsSearchIndex {
    /// 结果最多几条。再多用户也不会往下看，面板也放不下。
    static let maxResults = 8

    /// 高亮持续多久。取值按一眼能看到的时长定。
    static let highlightDuration: TimeInterval = 1.2

    /// 查一次。
    static func search(_ query: String, language: AppLanguage) -> [SettingsSearchHit] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }

        var hits: [SettingsSearchHit] = []
        for entry in SettingsCatalog.entries {
            guard matches(entry, needle: needle, language: language) else { continue }
            hits.append(SettingsSearchHit(rowID: entry.rowID, section: entry.section, entry: entry))
            if hits.count == maxResults { break }
        }
        return hits
    }

    /// 一条是否命中。
    ///
    /// 界面语言之外的那一种文案也参与匹配：用户可能用英文搜中文界面。
    private static func matches(_ entry: SettingsCatalogEntry, needle: String, language: AppLanguage) -> Bool {
        if contains(entry.title.text(for: language), needle) { return true }
        if contains(entry.title.en, needle) || contains(entry.title.zhHans, needle) { return true }
        if let summary = entry.summary {
            if contains(summary.text(for: language), needle) { return true }
            if contains(summary.en, needle) || contains(summary.zhHans, needle) { return true }
        }
        return entry.keywords.contains { contains($0, needle) }
    }

    private static func contains(_ haystack: String, _ needle: String) -> Bool {
        haystack.lowercased().contains(needle)
    }
}
