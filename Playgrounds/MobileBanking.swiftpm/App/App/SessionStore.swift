import Foundation
import Observation

/// Who is using the app right now. `RootView` follows `state`.
@MainActor
@Observable
final class SessionStore {
    enum State {
        case signedOut
        /// There is a saved session, but Face ID has to confirm it first.
        case locked(User)
        case signedIn(User)
    }

    private(set) var state: State

    private let auth: any AuthService

    init(auth: any AuthService, biometricSettings: BiometricSettings) {
        self.auth = auth
        if let user = auth.restoreSession() {
            state = biometricSettings.isEnabled ? .locked(user) : .signedIn(user)
        } else {
            state = .signedOut
        }
    }

    func didAuthenticate(_ user: User) {
        state = .signedIn(user)
    }

    func unlock() {
        guard case .locked(let user) = state else { return }
        state = .signedIn(user)
    }

    func signOut() {
        auth.signOut()
        state = .signedOut
    }
}
