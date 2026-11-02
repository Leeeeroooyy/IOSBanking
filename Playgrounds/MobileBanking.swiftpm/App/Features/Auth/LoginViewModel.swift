import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    private(set) var error: AuthError?
    private(set) var isSubmitting = false

    private let auth: any AuthService
    private let session: SessionStore

    init(auth: any AuthService, session: SessionStore) {
        self.auth = auth
        self.session = session
    }

    var canSubmit: Bool {
        !isSubmitting && !email.isEmpty && !password.isEmpty
    }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        error = nil

        do {
            let user = try await auth.signIn(email: email, password: password)
            session.didAuthenticate(user)
        } catch let authError as AuthError {
            error = authError
            password = ""
        } catch {
            self.error = .storageFailed
        }
    }
}
