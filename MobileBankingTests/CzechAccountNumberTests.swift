import XCTest
@testable import MobileBanking

final class CzechAccountNumberTests: XCTestCase {

    func testValidNumberWithPrefix() throws {
        let number = try XCTUnwrap(CzechAccountNumber("19-2000145399/0800"))
        XCTAssertEqual(number.prefix, "19")
        XCTAssertEqual(number.number, "2000145399")
        XCTAssertEqual(number.bankCode, "0800")
        XCTAssertEqual(number.formatted, "19-2000145399/0800")
        XCTAssertEqual(number.masked, "•• 5399")
    }

    func testValidNumberWithoutPrefix() {
        XCTAssertEqual(CzechAccountNumber("2000145399/0800")?.formatted, "2000145399/0800")
    }

    func testSpacesAndLeadingZerosAreNormalized() {
        XCTAssertEqual(CzechAccountNumber(" 000019 - 2000145399 / 0800 ")?.formatted, "19-2000145399/0800")
        XCTAssertEqual(CzechAccountNumber("000000-2000145399/0800")?.formatted, "2000145399/0800")
    }

    func testWrongCheckDigitIsRejected() {
        XCTAssertNil(CzechAccountNumber("2000145398/0800"), "Number check digit")
        XCTAssertNil(CzechAccountNumber("18-2000145399/0800"), "Prefix check digit")
    }

    func testMalformedInputIsRejected() {
        let inputs = [
            "", "abc", "2000145399", "2000145399/080", "2000145399/08000",
            "2000145399/08a0", "1234567-2000145399/0800", "12345678901/0800",
            "-2000145399/0800", "1-2-2000145399/0800", "0/0800", "0000000000/0800",
        ]
        for input in inputs {
            XCTAssertNil(CzechAccountNumber(input), "Should be rejected: \(input)")
        }
    }

    func testGeneratedNumbersAreValidAndInTheDemoBank() {
        for _ in 0..<500 {
            let generated = CzechAccountNumber.generate()
            XCTAssertEqual(generated.number.count, 10)
            XCTAssertEqual(generated.bankCode, CzechAccountNumber.demoBankCode)
            XCTAssertEqual(CzechAccountNumber(generated.formatted), generated, generated.formatted)
        }
    }
}
