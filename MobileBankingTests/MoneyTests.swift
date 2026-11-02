import XCTest
@testable import MobileBanking

final class MoneyTests: XCTestCase {

    func testMinorUnitsBecomeDecimalAmount() {
        XCTAssertEqual(Money(minorUnits: 4_525_000).amount, Decimal(45_250))
        XCTAssertEqual(Money(minorUnits: 124_890).amount, Decimal(string: "1248.90"))
        XCTAssertEqual(Money(minorUnits: -1).amount, Decimal(string: "-0.01"))
    }

    func testDecimalAmountBecomesMinorUnits() {
        XCTAssertEqual(Money(amount: Decimal(string: "1248.9")!)?.minorUnits, 124_890)
        XCTAssertEqual(Money(amount: Decimal(string: "0.10")!)?.minorUnits, 10)
        XCTAssertEqual(Money(amount: 0)?.minorUnits, 0)
    }

    func testMoreThanTwoDecimalPlacesIsRejected() {
        XCTAssertNil(Money(amount: Decimal(string: "10.001")!))
    }

    func testTooLargeAmountIsRejected() {
        XCTAssertNil(Money(amount: Decimal(string: "999999999999999999999")!))
    }

    func testRoundTripKeepsTheValue() {
        for text in ["0.01", "45250.00", "999999999.99", "-350.50"] {
            let amount = Decimal(string: text)!
            XCTAssertEqual(Money(amount: amount)?.amount, amount, text)
        }
    }
}
