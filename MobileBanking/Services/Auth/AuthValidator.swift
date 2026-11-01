import SwiftUI

/// A problem with a value in the sign-in or sign-up form, shown under the field.
enum AuthFormError: Error, Equatable {
    case fullNameEmpty
    case fullNameTooLong
    case emailInvalid
    case passwordTooShort
    case passwordMismatch

    var messageKey: LocalizedStringKey {
        switch self {
        case .fullNameEmpty: return "auth.error.fullName.empty"
        case .fullNameTooLong: return "auth.error.fullName.tooLong"
        case .emailInvalid: return "auth.error.email.invalid"
        case .passwordTooShort: return "auth.error.password.tooShort"
        case .passwordMismatch: return "auth.error.password.mismatch"
        }
    }
}

/// Rules of the sign-up form.
enum AuthValidator {
    static let maxFullNameLength = 70
    static let minPasswordLength = 8

    static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func normalizedFullName(_ fullName: String) -> String {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validateFullName(_ fullName: String) -> AuthFormError? {
        let name = normalizedFullName(fullName)
        if name.isEmpty { return .fullNameEmpty }
        if name.count > maxFullNameLength { return .fullNameTooLong }
        return nil
    }

    static func validateEmail(_ email: String) -> AuthFormError? {
        let pattern = #"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$"#
        let isValid = normalizedEmail(email).range(of: pattern, options: .regularExpression) != nil
        return isValid ? nil : .emailInvalid
    }

    static func validatePassword(_ password: String) -> AuthFormError? {
        password.count >= minPasswordLength ? nil : .passwordTooShort
    }

    static func validateConfirmation(password: String, confirmation: String) -> AuthFormError? {
        password == confirmation ? nil : .passwordMismatch
    }
}
