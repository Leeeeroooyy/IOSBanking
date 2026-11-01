import LocalAuthentication
import SwiftUI

enum BiometricError: Error, Equatable {
    case cancelled
    case unavailable
    case failed

    /// `nil` for a cancelled prompt: the user did that on purpose, so there is nothing to report.
    var messageKey: LocalizedStringKey? {
        switch self {
        case .cancelled: return nil
        case .unavailable: return "biometric.error.unavailable"
        case .failed: return "biometric.error.failed"
        }
    }
}

@MainActor
protocol BiometricService {
    var isAvailable: Bool { get }
    /// Shows the system Face ID prompt. Returns normally only after a successful check.
    func authenticate(reason: String) async throws
}

/// Face ID through LocalAuthentication.
/// In the Simulator it needs Features › Face ID › Enrolled.
struct LocalBiometricService: BiometricService {
    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        // The fallback is our own "Sign in with password" button.
        context.localizedFallbackTitle = ""

        do {
            _ = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricError.cancelled
            case .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout:
                throw BiometricError.unavailable
            default:
                throw BiometricError.failed
            }
        } catch {
            throw BiometricError.failed
        }
    }
}

/// The "Face ID on launch" setting. It is not a secret, so it lives in UserDefaults.
struct BiometricSettings {
    static let storageKey = "faceIDEnabled"

    var defaults: UserDefaults = .standard

    var isEnabled: Bool {
        get { defaults.bool(forKey: Self.storageKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.storageKey) }
    }
}

extension String {
    /// A catalog string in the language chosen inside the app. The system Face ID prompt
    /// takes plain text, so it cannot follow `\.locale` by itself as SwiftUI `Text` does.
    static func localized(_ resource: LocalizedStringResource, locale: Locale) -> String {
        var resource = resource
        resource.locale = locale
        return String(localized: resource)
    }
}
