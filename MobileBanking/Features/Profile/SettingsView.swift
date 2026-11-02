import SwiftUI

/// Screen 16: language, appearance and Face ID. Every change applies immediately.
struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.default.rawValue
    @AppStorage(AppAppearance.storageKey) private var appearanceValue = AppAppearance.default.rawValue
    @Environment(\.locale) private var locale

    @State private var viewModel: SettingsViewModel
    private let stockAPIKey: StockAPIKeyStore

    @MainActor
    init(biometrics: any BiometricService, settings: BiometricSettings, stockAPIKey: StockAPIKeyStore) {
        self.stockAPIKey = stockAPIKey
        _viewModel = State(initialValue: SettingsViewModel(biometrics: biometrics, settings: settings))
    }

    private var faceIDBinding: Binding<Bool> {
        Binding {
            viewModel.isFaceIDEnabled
        } set: { isEnabled in
            Task {
                await viewModel.setFaceID(isEnabled, reason: .localized("settings.faceID.reason", locale: locale))
            }
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("settings.language", selection: $languageCode) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(verbatim: language.nativeName).tag(language.rawValue)
                    }
                }
                .accessibilityIdentifier("settings.language")

                Picker("settings.appearance", selection: $appearanceValue) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.titleKey).tag(appearance.rawValue)
                    }
                }
                .accessibilityIdentifier("settings.appearance")
            }

            Section {
                Toggle("settings.faceID", isOn: faceIDBinding)
                    .disabled(!viewModel.canChangeFaceID)
                    .accessibilityIdentifier("settings.faceID")
            } header: {
                Text("settings.security")
            } footer: {
                if let message = viewModel.faceIDError?.messageKey {
                    Text(message)
                } else if viewModel.isFaceIDAvailable {
                    Text("settings.faceID.hint")
                } else {
                    Text("biometric.error.unavailable")
                }
            }

            StockAPIKeySection(keyStore: stockAPIKey)
        }
        .navigationTitle("settings.title")
    }
}

#Preview {
    let dependencies = AppDependencies.inMemory()
    return NavigationStack {
        SettingsView(biometrics: dependencies.biometrics, settings: dependencies.biometricSettings, stockAPIKey: dependencies.stockAPIKey)
    }
}
