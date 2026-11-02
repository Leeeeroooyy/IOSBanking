import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var isFaceIDEnabled: Bool
    private(set) var isChangingFaceID = false
    private(set) var faceIDError: BiometricError?

    let isFaceIDAvailable: Bool

    private let biometrics: any BiometricService
    private let settings: BiometricSettings

    init(biometrics: any BiometricService, settings: BiometricSettings) {
        self.biometrics = biometrics
        self.settings = settings
        isFaceIDEnabled = settings.isEnabled
        isFaceIDAvailable = biometrics.isAvailable
    }

    /// Face ID can always be turned off, but only a successful check turns it on.
    var canChangeFaceID: Bool {
        !isChangingFaceID && (isFaceIDEnabled || isFaceIDAvailable)
    }

    func setFaceID(_ isEnabled: Bool, reason: String) async {
        faceIDError = nil

        guard isEnabled else {
            settings.isEnabled = false
            isFaceIDEnabled = false
            return
        }

        guard !isChangingFaceID else { return }
        isChangingFaceID = true
        defer { isChangingFaceID = false }

        do {
            try await biometrics.authenticate(reason: reason)
            settings.isEnabled = true
            isFaceIDEnabled = true
        } catch BiometricError.cancelled {
            // The toggle simply stays off.
        } catch let biometricError as BiometricError {
            faceIDError = biometricError
        } catch {
            faceIDError = .failed
        }
    }
}
