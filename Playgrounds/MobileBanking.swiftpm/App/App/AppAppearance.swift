import SwiftUI

/// Light / dark theme choice. Light = design variant C, dark = design variant D.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// UserDefaults key. Can also be set at launch for tests: `-appAppearance dark`.
    static let storageKey = "appAppearance"
    static let `default`: AppAppearance = .system

    static func resolve(_ rawValue: String) -> AppAppearance {
        AppAppearance(rawValue: rawValue) ?? .default
    }

    var id: String { rawValue }

    /// `nil` means "follow the system setting".
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: return "appearance.system"
        case .light: return "appearance.light"
        case .dark: return "appearance.dark"
        }
    }
}
