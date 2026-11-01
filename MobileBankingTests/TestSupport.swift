import Foundation
import SwiftData
@testable import MobileBanking

func makeTestContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: User.self, configurations: configuration)
}

/// One iteration keeps the password hashing in tests fast.
@MainActor
func makeAuthService(
    keychain: any KeychainService = InMemoryKeychainService(),
    container: ModelContainer? = nil
) throws -> LocalAuthService {
    LocalAuthService(container: try container ?? makeTestContainer(), keychain: keychain, iterations: 1)
}

/// Fails to save accounts that start with `failingPrefix`, to reach the error paths of sign-up.
final class FailingKeychainService: KeychainService {
    struct Failure: Error {}

    var failingPrefix: String?
    private(set) var items: [String: Data] = [:]

    init(failingPrefix: String) {
        self.failingPrefix = failingPrefix
    }

    func save(_ data: Data, account: String) throws {
        if let failingPrefix, account.hasPrefix(failingPrefix) { throw Failure() }
        items[account] = data
    }

    func read(account: String) throws -> Data? {
        items[account]
    }

    func delete(account: String) throws {
        items[account] = nil
    }
}

/// Settings stored in a separate suite, so tests never touch the real ones.
func makeBiometricSettings(isEnabled: Bool = false) -> BiometricSettings {
    let settings = BiometricSettings(defaults: UserDefaults(suiteName: "tests.\(UUID().uuidString)")!)
    settings.isEnabled = isEnabled
    return settings
}

@MainActor
final class FakeBiometricService: BiometricService {
    var isAvailable = true
    /// The error to throw; `nil` means a successful check.
    var failure: BiometricError?
    private(set) var authenticateCalls = 0

    func authenticate(reason: String) async throws {
        authenticateCalls += 1
        if let failure { throw failure }
    }
}

extension SessionStore.State {
    var isSignedOut: Bool {
        if case .signedOut = self { return true }
        return false
    }

    var isLocked: Bool {
        if case .locked = self { return true }
        return false
    }

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
}
