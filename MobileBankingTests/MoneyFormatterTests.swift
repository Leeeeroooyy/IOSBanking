import XCTest
@testable import MobileBanking

final class MoneyFormatterTests: XCTestCase {

    private let czech = AppLanguage.czech.locale
    private let english = AppLanguage.english.locale

    /// Foundation uses non-breaking spaces as separators; compare with plain spaces.
    private func normalized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    func testCzechFormatUsesSpaceGroupingDecimalCommaAndKc() {
        let text = MoneyFormatter.string(Decimal(45_250), locale: czech)
        XCTAssertEqual(normalized(text), "45 250,00 Kč")
    }

    func testEnglishFormatUsesCommaGroupingAndDecimalPoint() {
        let text = normalized(MoneyFormatter.string(Decimal(string: "45250.5")!, locale: english))
        XCTAssertTrue(text.contains("45,250.50"), "Unexpected format: \(text)")
        XCTAssertTrue(text.contains("CZK"), "Unexpected format: \(text)")
    }

    func testAlwaysTwoFractionDigits() {
        let text = MoneyFormatter.string(Decimal(string: "1248.9")!, locale: czech)
        XCTAssertEqual(normalized(text), "1 248,90 Kč")
    }

    func testSignedIncomingAmountHasPlus() {
        let text = MoneyFormatter.signedString(Decimal(38_500), locale: czech)
        XCTAssertEqual(normalized(text), "+38 500,00 Kč")
    }

    func testSignedOutgoingAmountUsesMinusSign() {
        let text = MoneyFormatter.signedString(Decimal(string: "-1248.90")!, locale: czech)
        XCTAssertEqual(normalized(text), "\u{2212}1 248,90 Kč")
    }

    func testSignedZeroHasNoSign() {
        let text = MoneyFormatter.signedString(Decimal(0), locale: czech)
        XCTAssertEqual(normalized(text), "0,00 Kč")
    }

    func testDecimalKeepsCentsExactly() {
        // 0.1 + 0.2 is not exactly 0.3 with Double; with Decimal it is.
        let sum = Decimal(string: "0.1")! + Decimal(string: "0.2")!
        XCTAssertEqual(sum, Decimal(string: "0.3")!)
        XCTAssertEqual(normalized(MoneyFormatter.string(sum, locale: czech)), "0,30 Kč")
    }
}
