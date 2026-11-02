import Foundation
import Observation
import SwiftData

/// All services of the app, created once and shared through `.environment`.
@MainActor
@Observable
final class AppDependencies {
    /// UI tests pass this launch argument to start every run clean.
    static let uiTestingArgument = "-uiTesting"
    static let uiTestingSignedInArgument = "-uiTestingSignedIn"

    let auth: any AuthService
    let banking: any BankingService
    let biometrics: any BiometricService
    let biometricSettings: BiometricSettings
    let session: SessionStore
    /// Creates the built-in test profiles (only in the real app, not in UI tests or previews).
    @ObservationIgnored var prepareTestAccounts: (@MainActor () async -> Void)?

    init(
        auth: any AuthService,
        banking: any BankingService,
        biometrics: any BiometricService,
        biometricSettings: BiometricSettings
    ) {
        self.auth = auth
        self.banking = banking
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
            let startsSignedIn = ProcessInfo.processInfo.arguments.contains(uiTestingSignedInArgument)
            return inMemory(signedIn: startsSignedIn)
        }
        #endif

        // One database for all services, so they see the same users and accounts.
        let container = makeContainer(inMemory: false)
        let auth = LocalAuthService(container: container, keychain: SystemKeychainService())
        let banking = LocalBankingService(container: container)
        let dependencies = AppDependencies(
            auth: auth,
            banking: banking,
            biometrics: LocalBiometricService(),
            biometricSettings: BiometricSettings()
        )
        dependencies.prepareTestAccounts = {
            await TestAccounts.prepare(auth: auth, banking: banking)
        }
        return dependencies
    }

    /// Nothing survives the run. Used by previews and UI tests.
    static func inMemory(signedIn: Bool = false) -> AppDependencies {
        let container = makeContainer(inMemory: true)
        let keychain = InMemoryKeychainService()
        if signedIn {
            addDemoSession(container: container, keychain: keychain)
        }

        return AppDependencies(
            auth: LocalAuthService(container: container, keychain: keychain, iterations: 1_000),
            banking: LocalBankingService(container: container),
            biometrics: LocalBiometricService(),
            biometricSettings: BiometricSettings()
        )
    }

    /// Lets UI tests reach the signed-in screens without going through the sign-up form.
    private static func addDemoSession(container: ModelContainer, keychain: any KeychainService) {
        let user = User(fullName: "Jana Novakova", email: "jana@example.cz")
        container.mainContext.insert(user)
        try? container.mainContext.save()
        try? keychain.save(Data(user.id.uuidString.utf8), account: LocalAuthService.sessionAccount)
    }

    private static func makeContainer(inMemory: Bool) -> ModelContainer {
        do {
            return try AppSchema.makeContainer(inMemory: inMemory)
        } catch {
            // The app cannot do anything useful without its database.
            fatalError("Could not open the local database.")
        }
    }
}
