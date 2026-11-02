import Foundation
import Observation

@MainActor
@Observable
final class RegisterViewModel {
    var fullName = ""
    var email = ""
    var password = ""
    var passwordConfirmation = ""

    private(set) var fullNameError: AuthFormError?
    private(set) var emailError: AuthFormError?
    private(set) var passwordError: AuthFormError?
    private(set) var confirmationError: AuthFormError?
    private(set) var error: AuthError?
    private(set) var isSubmitting = false

    private let auth: any AuthService
    private let session: SessionStore

    init(auth: any AuthService, session: SessionStore) {
        self.auth = auth
        self.session = session
    }

    func submit() async {
        guard !isSubmitting else { return }
        error = nil
        guard validate() else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let user = try await auth.register(fullName: fullName, email: email, password: password)
            session.didAuthenticate(user)
        } catch let authError as AuthError {
            error = authError
        } catch {
            self.error = .storageFailed
        }
    }

    private func validate() -> Bool {
        fullNameError = AuthValidator.validateFullName(fullName)
        emailError = AuthValidator.validateEmail(email)
        passwordError = AuthValidator.validatePassword(password)
        confirmationError = AuthValidator.validateConfirmation(password: password, confirmation: passwordConfirmation)
        return [fullNameError, emailError, passwordError, confirmationError].allSatisfy { $0 == nil }
    }
}
