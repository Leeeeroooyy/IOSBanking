import Foundation

/// Languages supported by the app. Czech is the default regardless of the system language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case czech = "cs"
    case english = "en"

    /// UserDefaults key. Can also be set at launch for tests: `-appLanguage en`.
    static let storageKey = "appLanguage"
    static let `default`: AppLanguage = .czech

    /// Unknown or missing values fall back to Czech.
    static func resolve(_ rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? .default
    }

    var id: String { rawValue }

    /// Locale used for texts and for formatting money, numbers and dates.
    /// English uses the British region: day-month-year dates suit users in Czechia.
    var locale: Locale {
        switch self {
        case .czech: return Locale(identifier: "cs_CZ")
        case .english: return Locale(identifier: "en_GB")
        }
    }

    /// A language is always shown in its own language in a language picker.
    var nativeName: String {
        switch self {
        case .czech: return "Čeština"
        case .english: return "English"
        }
    }
}
