import SwiftUI

/// Entry point of the app.
///
/// Language and appearance are stored in UserDefaults through `@AppStorage`
/// and applied to the whole view tree here. When the user changes them in Settings,
/// every screen updates immediately — no restart needed.
@main
struct MobileBankingApp: App {
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.default.rawValue
    @AppStorage(AppAppearance.storageKey) private var appearanceValue = AppAppearance.default.rawValue

    @State private var dependencies: AppDependencies

    init() {
        _dependencies = State(initialValue: AppDependencies.live())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dependencies)
                // Texts and number/date/currency formats follow this locale.
                .environment(\.locale, AppLanguage.resolve(languageCode).locale)
                // nil = follow the system setting.
                .preferredColorScheme(AppAppearance.resolve(appearanceValue).colorScheme)
                // SF Pro Rounded everywhere (layout of design variant C).
                .fontDesign(.rounded)
                .tint(Theme.Colors.primary)
                .task { await dependencies.prepareTestAccounts?() }
        }
    }
}
