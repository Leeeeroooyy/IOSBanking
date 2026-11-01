import SwiftData
import XCTest
@testable import MobileBanking

@MainActor
final class LocalAuthServiceTests: XCTestCase {

    private let password = "heslo123"

    private func assertThrows(
        _ expected: AuthError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> User
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AuthError, expected, file: file, line: line)
        }
    }

    /// Counts through a separate context, which sees only what was really saved.
    private func savedUserCount(in container: ModelContainer) throws -> Int {
        try ModelContext(container).fetchCount(FetchDescriptor<User>())
    }

    func testRegisterSavesTheUser() async throws {
        let container = try makeTestContainer()
        let service = try makeAuthService(container: container)

        _ = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)

        XCTAssertEqual(try savedUserCount(in: container), 1)
    }

    func testFailedSessionWriteLeavesNothingAndEmailStaysFree() async throws {
        let container = try makeTestContainer()
        let keychain = FailingKeychainService(failingPrefix: LocalAuthService.sessionAccount)
        let service = try makeAuthService(keychain: keychain, container: container)

        await assertThrows(.storageFailed) {
            try await service.register(fullName: "Jana", email: "jana@example.cz", password: self.password)
        }

        XCTAssertEqual(try savedUserCount(in: container), 0)
        XCTAssertTrue(keychain.items.isEmpty)

        keychain.failingPrefix = nil
        let user = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)
        XCTAssertEqual(service.restoreSession()?.id, user.id)
    }

    func testFailedCredentialWriteLeavesNothing() async throws {
        let container = try makeTestContainer()
        let keychain = FailingKeychainService(failingPrefix: "credential.")
        let service = try makeAuthService(keychain: keychain, container: container)

        await assertThrows(.storageFailed) {
            try await service.register(fullName: "Jana", email: "jana@example.cz", password: self.password)
        }

        XCTAssertEqual(try savedUserCount(in: container), 0)
        XCTAssertTrue(keychain.items.isEmpty)
    }

    func testRegisterCreatesUserWithNormalizedData() async throws {
        let service = try makeAuthService()
        let user = try await service.register(fullName: "  Jana Nováková ", email: " Jana@Example.CZ", password: password)
        XCTAssertEqual(user.fullName, "Jana Nováková")
        XCTAssertEqual(user.email, "jana@example.cz")
    }

    func testRegisterStartsSession() async throws {
        let service = try makeAuthService()
        let user = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)
        XCTAssertEqual(service.restoreSession()?.id, user.id)
    }

    func testEmailCanBeRegisteredOnlyOnceIgnoringCase() async throws {
        let service = try makeAuthService()
        _ = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)
        await assertThrows(.emailTaken) {
            try await service.register(fullName: "Jiná", email: "JANA@example.cz", password: password)
        }
    }

    func testPasswordIsStoredOnlyAsSaltedHash() async throws {
        let keychain = InMemoryKeychainService()
        let service = try makeAuthService(keychain: keychain)
        let user = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)

        let account = LocalAuthService.credentialAccount(for: user.id)
        let stored = try XCTUnwrap(try keychain.read(account: account))
        XCTAssertNil(stored.range(of: Data(password.utf8)))

        let credential = try JSONDecoder().decode(PasswordCredential.self, from: stored)
        XCTAssertTrue(try PasswordHasher.verify(password: password, credential: credential))
    }

    func testSignInWithCorrectPassword() async throws {
        let service = try makeAuthService()
        let user = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)
        service.signOut()

        let signedIn = try await service.signIn(email: " JANA@example.cz ", password: password)
        XCTAssertEqual(signedIn.id, user.id)
        XCTAssertEqual(service.restoreSession()?.id, user.id)
    }

    func testSignInWithWrongPasswordFails() async throws {
        let service = try makeAuthService()
        _ = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)
        service.signOut()

        await assertThrows(.invalidCredentials) {
            try await service.signIn(email: "jana@example.cz", password: "spatneheslo")
        }
        XCTAssertNil(service.restoreSession())
    }

    func testSignInWithUnknownEmailFailsTheSameWay() async throws {
        let service = try makeAuthService()
        await assertThrows(.invalidCredentials) {
            try await service.signIn(email: "nikdo@example.cz", password: self.password)
        }
    }

    func testSignOutEndsSession() async throws {
        let service = try makeAuthService()
        _ = try await service.register(fullName: "Jana", email: "jana@example.cz", password: password)
        service.signOut()
        XCTAssertNil(service.restoreSession())
    }

    func testSessionOfMissingUserIsDropped() async throws {
        let keychain = InMemoryKeychainService()
        let service = try makeAuthService(keychain: keychain)
        try keychain.save(Data(UUID().uuidString.utf8), account: LocalAuthService.sessionAccount)

        XCTAssertNil(service.restoreSession())
        XCTAssertNil(try keychain.read(account: LocalAuthService.sessionAccount))
    }
}
