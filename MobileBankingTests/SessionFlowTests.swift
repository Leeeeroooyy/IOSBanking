import XCTest
@testable import MobileBanking

/// `SessionStore` and the view models that drive it.
@MainActor
final class SessionFlowTests: XCTestCase {

    private let password = "heslo123"

    /// A service with a saved session, as after the previous run of the app.
    private func makeSignedInService() async throws -> LocalAuthService {
        let service = try makeAuthService()
        _ = try await service.register(fullName: "Jana Nováková", email: "jana@example.cz", password: password)
        return service
    }

    // MARK: SessionStore

    func testNoSessionMeansSignedOut() throws {
        let store = SessionStore(auth: try makeAuthService(), biometricSettings: makeBiometricSettings())
        XCTAssertTrue(store.state.isSignedOut)
    }

    func testSavedSessionOpensTheAppWithoutFaceID() async throws {
        let service = try await makeSignedInService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        XCTAssertTrue(store.state.isSignedIn)
    }

    func testSavedSessionIsLockedWhenFaceIDIsOn() async throws {
        let service = try await makeSignedInService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings(isEnabled: true))
        XCTAssertTrue(store.state.isLocked)
    }

    func testSignOutEndsTheSessionForTheNextLaunch() async throws {
        let service = try await makeSignedInService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())

        store.signOut()

        XCTAssertTrue(store.state.isSignedOut)
        XCTAssertNil(service.restoreSession())
    }

    // MARK: Lock screen

    func testFaceIDSuccessUnlocks() async throws {
        let service = try await makeSignedInService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings(isEnabled: true))
        let viewModel = LockViewModel(biometrics: FakeBiometricService(), session: store)

        await viewModel.unlock(reason: "test")

        XCTAssertTrue(store.state.isSignedIn)
    }

    func testCancelledFaceIDStaysLockedWithoutError() async throws {
        let service = try await makeSignedInService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings(isEnabled: true))
        let biometrics = FakeBiometricService()
        biometrics.failure = .cancelled
        let viewModel = LockViewModel(biometrics: biometrics, session: store)

        await viewModel.unlock(reason: "test")

        XCTAssertTrue(store.state.isLocked)
        XCTAssertNil(viewModel.error)
    }

    func testFailedFaceIDStaysLockedAndShowsError() async throws {
        let service = try await makeSignedInService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings(isEnabled: true))
        let biometrics = FakeBiometricService()
        biometrics.failure = .failed
        let viewModel = LockViewModel(biometrics: biometrics, session: store)

        await viewModel.unlock(reason: "test")

        XCTAssertTrue(store.state.isLocked)
        XCTAssertEqual(viewModel.error, .failed)
    }

    func testUsingThePasswordLeadsToSignIn() async throws {
        let service = try await makeSignedInService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings(isEnabled: true))
        let viewModel = LockViewModel(biometrics: FakeBiometricService(), session: store)

        viewModel.usePassword()

        XCTAssertTrue(store.state.isSignedOut)
    }

    // MARK: Sign-in form

    func testSignInSubmitSignsIn() async throws {
        let service = try await makeSignedInService()
        service.signOut()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        let viewModel = LoginViewModel(auth: service, session: store)
        viewModel.email = "jana@example.cz"
        viewModel.password = password

        await viewModel.submit()

        XCTAssertTrue(store.state.isSignedIn)
        XCTAssertNil(viewModel.error)
    }

    func testWrongPasswordShowsErrorAndClearsThePassword() async throws {
        let service = try await makeSignedInService()
        service.signOut()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        let viewModel = LoginViewModel(auth: service, session: store)
        viewModel.email = "jana@example.cz"
        viewModel.password = "spatneheslo"

        await viewModel.submit()

        XCTAssertTrue(store.state.isSignedOut)
        XCTAssertEqual(viewModel.error, .invalidCredentials)
        XCTAssertEqual(viewModel.password, "")
    }

    func testSignInNeedsBothFields() throws {
        let service = try makeAuthService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        let viewModel = LoginViewModel(auth: service, session: store)

        XCTAssertFalse(viewModel.canSubmit)
        viewModel.email = "jana@example.cz"
        XCTAssertFalse(viewModel.canSubmit)
        viewModel.password = password
        XCTAssertTrue(viewModel.canSubmit)
    }

    // MARK: Sign-up form

    func testValidSignUpSignsIn() async throws {
        let service = try makeAuthService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        let viewModel = RegisterViewModel(auth: service, session: store)
        viewModel.fullName = "Jana Nováková"
        viewModel.email = "jana@example.cz"
        viewModel.password = password
        viewModel.passwordConfirmation = password

        await viewModel.submit()

        XCTAssertTrue(store.state.isSignedIn)
    }

    func testInvalidSignUpShowsEveryErrorAndCreatesNothing() async throws {
        let service = try makeAuthService()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        let viewModel = RegisterViewModel(auth: service, session: store)
        viewModel.email = "jana"
        viewModel.password = "kratke"
        viewModel.passwordConfirmation = "jine"

        await viewModel.submit()

        XCTAssertEqual(viewModel.fullNameError, .fullNameEmpty)
        XCTAssertEqual(viewModel.emailError, .emailInvalid)
        XCTAssertEqual(viewModel.passwordError, .passwordTooShort)
        XCTAssertEqual(viewModel.confirmationError, .passwordMismatch)
        XCTAssertTrue(store.state.isSignedOut)
    }

    func testTakenEmailShowsError() async throws {
        let service = try await makeSignedInService()
        service.signOut()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        let viewModel = RegisterViewModel(auth: service, session: store)
        viewModel.fullName = "Jiná Jana"
        viewModel.email = "jana@example.cz"
        viewModel.password = password
        viewModel.passwordConfirmation = password

        await viewModel.submit()

        XCTAssertEqual(viewModel.error, .emailTaken)
        XCTAssertTrue(store.state.isSignedOut)
    }

    func testResubmitWithInvalidFieldClearsTheOldError() async throws {
        let service = try await makeSignedInService()
        service.signOut()
        let store = SessionStore(auth: service, biometricSettings: makeBiometricSettings())
        let viewModel = RegisterViewModel(auth: service, session: store)
        viewModel.fullName = "Jiná Jana"
        viewModel.email = "jana@example.cz"
        viewModel.password = password
        viewModel.passwordConfirmation = password
        await viewModel.submit()

        viewModel.fullName = ""
        await viewModel.submit()

        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.fullNameError, .fullNameEmpty)
    }

    // MARK: Face ID setting

    func testFaceIDTurnsOnOnlyAfterSuccessfulCheck() async {
        let settings = makeBiometricSettings()
        let viewModel = SettingsViewModel(biometrics: FakeBiometricService(), settings: settings)

        await viewModel.setFaceID(true, reason: "test")

        XCTAssertTrue(viewModel.isFaceIDEnabled)
        XCTAssertTrue(settings.isEnabled)
    }

    func testFailedCheckLeavesFaceIDOff() async {
        let settings = makeBiometricSettings()
        let biometrics = FakeBiometricService()
        biometrics.failure = .failed
        let viewModel = SettingsViewModel(biometrics: biometrics, settings: settings)

        await viewModel.setFaceID(true, reason: "test")

        XCTAssertFalse(viewModel.isFaceIDEnabled)
        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(viewModel.faceIDError, .failed)
    }

    func testTurningFaceIDOffNeedsNoCheck() async {
        let settings = makeBiometricSettings(isEnabled: true)
        let biometrics = FakeBiometricService()
        let viewModel = SettingsViewModel(biometrics: biometrics, settings: settings)

        await viewModel.setFaceID(false, reason: "test")

        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(biometrics.authenticateCalls, 0)
    }

    func testFaceIDCannotBeTurnedOnWhenUnavailable() {
        let biometrics = FakeBiometricService()
        biometrics.isAvailable = false
        let viewModel = SettingsViewModel(biometrics: biometrics, settings: makeBiometricSettings())

        XCTAssertFalse(viewModel.canChangeFaceID)
    }

    func testFaceIDCanBeTurnedOffWhenUnavailable() {
        let biometrics = FakeBiometricService()
        biometrics.isAvailable = false
        let viewModel = SettingsViewModel(biometrics: biometrics, settings: makeBiometricSettings(isEnabled: true))

        XCTAssertTrue(viewModel.canChangeFaceID)
    }
}
