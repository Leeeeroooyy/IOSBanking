import XCTest
@testable import MobileBanking

/// Runs against the real Keychain of the simulator, under a service name of its own.
final class KeychainServiceTests: XCTestCase {

    private let keychain = SystemKeychainService(service: "cz.mobiletech.tests.\(UUID().uuidString)")
    private let account = "account"

    override func tearDownWithError() throws {
        try keychain.delete(account: account)
    }

    func testReadingUnknownAccountReturnsNil() throws {
        XCTAssertNil(try keychain.read(account: account))
    }

    func testSavedValueCanBeRead() throws {
        try keychain.save(Data("value".utf8), account: account)
        XCTAssertEqual(try keychain.read(account: account), Data("value".utf8))
    }

    func testSavingAgainReplacesTheValue() throws {
        try keychain.save(Data("old".utf8), account: account)
        try keychain.save(Data("new".utf8), account: account)
        XCTAssertEqual(try keychain.read(account: account), Data("new".utf8))
    }

    func testDeletedValueIsGone() throws {
        try keychain.save(Data("value".utf8), account: account)
        try keychain.delete(account: account)
        XCTAssertNil(try keychain.read(account: account))
    }

    func testDeletingUnknownAccountIsNotAnError() {
        XCTAssertNoThrow(try keychain.delete(account: account))
    }
}
