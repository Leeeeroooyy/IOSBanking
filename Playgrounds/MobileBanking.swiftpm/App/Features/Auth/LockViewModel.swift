import Foundation
import Observation

@MainActor
@Observable
final class LockViewModel {
    private(set) var error: BiometricError?
    private(set) var isAuthenticating = false

    private let biometrics: any BiometricService
    private let session: SessionStore

    init(biometrics: any BiometricService, session: SessionStore) {
        self.biometrics = biometrics
        self.session = session
    }

    func unlock(reason: String) async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        error = nil

        do {
            try await biometrics.authenticate(reason: reason)
            session.unlock()
        } catch BiometricError.cancelled {
            // The user stays here and picks Face ID again or the password.
        } catch let biometricError as BiometricError {
            error = biometricError
        } catch {
            self.error = .failed
        }
    }

    /// The saved session ends here, so only the password can open the app again.
    func usePassword() {
        session.signOut()
    }
}
