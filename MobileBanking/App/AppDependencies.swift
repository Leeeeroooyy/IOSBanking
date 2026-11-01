import Foundation
import Observation
import SwiftData

/// All services of the app, created once and shared through `.environment`.
@MainActor
@Observable
final class AppDependencies {
    /// UI tests pass this launch argument to start every run clean.
    static let uiTestingArgument = "-uiTesting"

    let auth: any AuthService
    let biometrics: any BiometricService
    let biometricSettings: BiometricSettings
    let session: SessionStore

    init(auth: any AuthService, biometrics: any BiometricService, biometricSettings: BiometricSettings) {
        self.auth = auth
        self.biometrics = biometrics
        self.biometricSettings = biometricSettings
        session = SessionStore(auth: auth, biometricSettings: biometricSettings)
    }

    static func live() -> AppDependencies {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(uiTestingArgument) {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: AppLanguage.storageKey)
            defaults.removeObject(forKey: AppAppearance.storageKey)
            defaults.removeObject(forKey: BiometricSettings.storageKey)
            return inMemory()
        }
        #endif

        return AppDependencies(
            auth: LocalAuthService(
                container: makeContainer(inMemory: false),
                keychain: SystemKeychainService()
            ),
            biometrics: LocalBiometricService(),
            biometricSettings: BiometricSettings()
        )
    }

    /// Nothing survives the run. Used by previews and UI tests.
    static func inMemory() -> AppDependencies {
        AppDependencies(
            auth: LocalAuthService(
                container: makeContainer(inMemory: true),
                keychain: InMemoryKeychainService(),
                iterations: 1_000
            ),
            biometrics: LocalBiometricService(),
            biometricSettings: BiometricSettings()
        )
    }

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: User.self, configurations: configuration)
        } catch {
            // The app cannot do anything useful without its database.
            fatalError("Could not open the local database.")
        }
    }
}
