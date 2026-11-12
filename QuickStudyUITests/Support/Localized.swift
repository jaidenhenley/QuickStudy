import Foundation

/// The app's own translations, read from the String Catalogs in the repository, so a UI test
/// can find controls by the label the app shows in whatever language it was launched in.
enum Localized {
    /// Set by the runner through `TEST_RUNNER_QS_LANGUAGE`, e.g. `ja` or `es-419`.
    static let language = ProcessInfo.processInfo.environment["QS_LANGUAGE"] ?? "en"

    static var launchArguments: [String] {
        ["-AppleLanguages", "(\(language))", "-AppleLocale", localeIdentifier]
    }

    static var localeIdentifier: String {
        switch language {
        case "es-419": return "es_MX"
        case "es-ES": return "es_ES"
        case "pt-BR": return "pt_BR"
        case "ja": return "ja_JP"
        case "ko": return "ko_KR"
        case "fr": return "fr_FR"
        case "de": return "de_DE"
        default: return "en_US"
        }
    }

    static func string(_ key: String, table: String = "Localizable") -> String {
        resolve(key, count: nil, table: table)
    }

    /// The label for a key with one integer argument, using the catalog's plural form.
    static func string(_ key: String, count: Int, table: String = "Localizable") -> String {
        resolve(key, count: count, table: table)
    }

    /// Every English value in a table whose translation differs, for spotting copy the app
    /// failed to localize.
    static func englishValuesThatShouldBeTranslated(table: String = "Localizable") -> Set<String> {
        guard language != "en" else { return [] }
        var values: Set<String> = []
        for (key, entry) in catalog(table) {
            guard let entry = entry as? [String: Any], entry["shouldTranslate"] as? Bool != false,
                  !key.contains("%") else { continue }
            let english = englishValue(key, entry: entry)
            let translated = resolve(key, count: nil, table: table)
            if translated != english, english.count > 2 { values.insert(english) }
        }
        return values
    }

    private static func resolve(_ key: String, count: Int?, table: String) -> String {
        guard let entry = catalog(table)[key] as? [String: Any],
              let localizations = entry["localizations"] as? [String: Any],
              let unit = localizations[language] as? [String: Any] ?? localizations["en"] as? [String: Any]
        else { return substitute(key, count: count) }
        if let plural = (unit["variations"] as? [String: Any])?["plural"] as? [String: Any] {
            let form = count == 1 && plural["one"] != nil ? "one" : "other"
            return substitute(value(of: plural[form]) ?? key, count: count)
        }
        return substitute(value(of: unit) ?? key, count: count)
    }

    private static func englishValue(_ key: String, entry: [String: Any]) -> String {
        let english = (entry["localizations"] as? [String: Any])?["en"]
        return value(of: english) ?? key
    }

    private static func value(of unit: Any?) -> String? {
        ((unit as? [String: Any])?["stringUnit"] as? [String: Any])?["value"] as? String
    }

    private static func substitute(_ format: String, count: Int?) -> String {
        guard let count else { return format }
        return format.replacingOccurrences(
            of: "%(1\\$)?lld",
            with: String(count),
            options: .regularExpression
        )
    }

    private static var cache: [String: [String: Any]] = [:]

    private static func catalog(_ table: String) -> [String: Any] {
        if let cached = cache[table] { return cached }
        let url = QSApp.repositoryRoot.appendingPathComponent("QuickStudy/\(table).xcstrings")
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: Any]
        else {
            preconditionFailure("Could not read \(url.path)")
        }
        cache[table] = strings
        return strings
    }
}
