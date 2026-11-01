import XCTest
@testable import MobileBanking

final class AuthValidatorTests: XCTestCase {

    func testEmailIsTrimmedAndLowercased() {
        XCTAssertEqual(AuthValidator.normalizedEmail("  Jana@Example.CZ \n"), "jana@example.cz")
    }

    func testValidEmails() {
        XCTAssertNil(AuthValidator.validateEmail("jana@example.cz"))
        XCTAssertNil(AuthValidator.validateEmail(" Jana.Novakova+demo@mail.example.cz "))
    }

    func testInvalidEmails() {
        for email in ["", "jana", "jana@", "@example.cz", "jana@example", "jana@example.c", "ja na@example.cz", "a@b@example.cz"] {
            XCTAssertEqual(AuthValidator.validateEmail(email), .emailInvalid, "Accepted: \(email)")
        }
    }

    func testFullNameMustNotBeEmpty() {
        XCTAssertEqual(AuthValidator.validateFullName("   "), .fullNameEmpty)
        XCTAssertNil(AuthValidator.validateFullName("Jana Nováková"))
    }

    func testFullNameLengthLimit() {
        XCTAssertNil(AuthValidator.validateFullName(String(repeating: "a", count: 70)))
        XCTAssertEqual(AuthValidator.validateFullName(String(repeating: "a", count: 71)), .fullNameTooLong)
    }

    func testPasswordLength() {
        XCTAssertEqual(AuthValidator.validatePassword("1234567"), .passwordTooShort)
        XCTAssertNil(AuthValidator.validatePassword("12345678"))
    }

    func testPasswordConfirmation() {
        XCTAssertNil(AuthValidator.validateConfirmation(password: "heslo123", confirmation: "heslo123"))
        XCTAssertEqual(AuthValidator.validateConfirmation(password: "heslo123", confirmation: "heslo124"), .passwordMismatch)
    }
}
