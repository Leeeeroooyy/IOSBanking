import XCTest
@testable import MobileBanking

final class PasswordHasherTests: XCTestCase {

    func testKnownVector() throws {
        // PBKDF2-HMAC-SHA256, password "password", salt "salt", 1 iteration, 32 bytes.
        let hash = try PasswordHasher.derive(password: "password", salt: Data("salt".utf8), iterations: 1)
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(hex, "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b")
    }

    func testCorrectPasswordVerifies() throws {
        let credential = try PasswordHasher.makeCredential(password: "heslo123", iterations: 1)
        XCTAssertTrue(try PasswordHasher.verify(password: "heslo123", credential: credential))
    }

    func testWrongPasswordDoesNotVerify() throws {
        let credential = try PasswordHasher.makeCredential(password: "heslo123", iterations: 1)
        XCTAssertFalse(try PasswordHasher.verify(password: "heslo124", credential: credential))
    }

    func testSamePasswordGetsDifferentSaltAndHash() throws {
        let first = try PasswordHasher.makeCredential(password: "heslo123", iterations: 1)
        let second = try PasswordHasher.makeCredential(password: "heslo123", iterations: 1)
        XCTAssertNotEqual(first.salt, second.salt)
        XCTAssertNotEqual(first.hash, second.hash)
    }

    func testComposedAndDecomposedLettersGiveTheSameHash() throws {
        let credential = try PasswordHasher.makeCredential(password: "h\u{00E9}slo123", iterations: 1)
        XCTAssertTrue(try PasswordHasher.verify(password: "he\u{0301}slo123", credential: credential))
    }
}
