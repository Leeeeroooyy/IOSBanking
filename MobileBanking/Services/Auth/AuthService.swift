import SwiftUI

enum AuthError: Error, Equatable {
    case emailTaken
    /// Used for both an unknown e-mail and a wrong password,
    /// so the sign-in screen does not reveal which e-mails are registered.
    case invalidCredentials
    case storageFailed

    var messageKey: LocalizedStringKey {
        switch self {
        case .emailTaken: return "auth.error.emailTaken"
        case .invalidCredentials: return "auth.error.invalidCredentials"
        case .storageFailed: return "auth.error.storage"
        }
    }
}

/// Sign-up, sign-in and the saved session.
@MainActor
protocol AuthService {
    /// The user of the saved session, if there is one.
    func restoreSession() -> User?
    func register(fullName: String, email: String, password: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signOut()
}
