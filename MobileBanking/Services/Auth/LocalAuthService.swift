import Foundation
import SwiftData

/// Users live in SwiftData, their password hashes and the session in the Keychain.
/// Nothing leaves the device.
@MainActor
final class LocalAuthService: AuthService {
    static let sessionAccount = "session.userId"

    static func credentialAccount(for userId: UUID) -> String {
        "credential.\(userId.uuidString)"
    }

    private let container: ModelContainer
    private let keychain: any KeychainService
    private let iterations: Int

    private var context: ModelContext { container.mainContext }

    init(
        container: ModelContainer,
        keychain: any KeychainService,
        iterations: Int = PasswordHasher.defaultIterations
    ) {
        self.container = container
        self.keychain = keychain
        self.iterations = iterations
    }

    func restoreSession() -> User? {
        guard
            let data = try? keychain.read(account: Self.sessionAccount),
            let text = String(data: data, encoding: .utf8),
            let id = UUID(uuidString: text)
        else { return nil }

        var descriptor = FetchDescriptor<User>(predicate: #Predicate<User> { $0.id == id })
        descriptor.fetchLimit = 1
        if let user = try? context.fetch(descriptor).first { return user }

        // The Keychain survives reinstalling the app, the database does not.
        signOut()
        return nil
    }

    func register(fullName: String, email: String, password: String) async throws -> User {
        let email = AuthValidator.normalizedEmail(email)
        guard try findUser(email: email) == nil else { throw AuthError.emailTaken }

        let credential = try await makeCredential(password: password)
        let user = User(fullName: AuthValidator.normalizedFullName(fullName), email: email)
        let credentialAccount = Self.credentialAccount(for: user.id)
        context.insert(user)

        do {
            try keychain.save(JSONEncoder().encode(credential), account: credentialAccount)
            try saveSession(for: user)
            // Last on purpose: this is the step that makes the user permanent.
            try context.save()
        } catch {
            context.rollback()
            signOut()
            try? keychain.delete(account: credentialAccount)
            throw AuthError.storageFailed
        }
        return user
    }

    /// Creates a user without signing in (used for the built-in test profiles).
    /// Returns the existing user when the e-mail is already registered.
    @discardableResult
    func createUserIfMissing(fullName: String, email: String, password: String) async throws -> User {
        let email = AuthValidator.normalizedEmail(email)
        if let existing = try findUser(email: email) { return existing }

        let credential = try await makeCredential(password: password)
        let user = User(fullName: AuthValidator.normalizedFullName(fullName), email: email)
        let credentialAccount = Self.credentialAccount(for: user.id)
        context.insert(user)
        do {
            try keychain.save(JSONEncoder().encode(credential), account: credentialAccount)
            try context.save()
        } catch {
            context.rollback()
            try? keychain.delete(account: credentialAccount)
            throw AuthError.storageFailed
        }
        return user
    }

    func signIn(email: String, password: String) async throws -> User {
        let email = AuthValidator.normalizedEmail(email)
        guard
            let user = try findUser(email: email),
            let credential = try loadCredential(for: user)
        else { throw AuthError.invalidCredentials }

        guard try await verify(password: password, credential: credential) else {
            throw AuthError.invalidCredentials
        }

        do {
            try saveSession(for: user)
        } catch {
            throw AuthError.storageFailed
        }
        return user
    }

    func signOut() {
        try? keychain.delete(account: Self.sessionAccount)
    }

    // MARK: Private

    private func findUser(email: String) throws -> User? {
        var descriptor = FetchDescriptor<User>(predicate: #Predicate<User> { $0.email == email })
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            throw AuthError.storageFailed
        }
    }

    private func loadCredential(for user: User) throws -> PasswordCredential? {
        do {
            let account = Self.credentialAccount(for: user.id)
            guard let data = try keychain.read(account: account) else { return nil }
            return try JSONDecoder().decode(PasswordCredential.self, from: data)
        } catch {
            throw AuthError.storageFailed
        }
    }

    private func saveSession(for user: User) throws {
        try keychain.save(Data(user.id.uuidString.utf8), account: Self.sessionAccount)
    }

    private func makeCredential(password: String) async throws -> PasswordCredential {
        let rounds = iterations
        do {
            return try await Task.detached(priority: .userInitiated) {
                try PasswordHasher.makeCredential(password: password, iterations: rounds)
            }.value
        } catch {
            throw AuthError.storageFailed
        }
    }

    private func verify(password: String, credential: PasswordCredential) async throws -> Bool {
        do {
            return try await Task.detached(priority: .userInitiated) {
                try PasswordHasher.verify(password: password, credential: credential)
            }.value
        } catch {
            throw AuthError.storageFailed
        }
    }
}
