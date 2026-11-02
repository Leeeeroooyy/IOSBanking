import Foundation

/// Formats money amounts for a given locale.
///
/// Uses Foundation's `FormatStyle`, so separators and the position of the currency
/// follow the locale: Czech "45 250,00 Kč", English "CZK 45,250.00".
/// Amounts are always `Decimal` — never `Double` — to avoid rounding errors.
enum MoneyFormatter {

    static func string(_ amount: Decimal, currencyCode: String = "CZK", locale: Locale) -> String {
        amount.formatted(
            .currency(code: currencyCode)
                .locale(locale)
                .precision(.fractionLength(2))
        )
    }

    /// "+38 500,00 Kč" for incoming and "−1 248,90 Kč" for outgoing amounts.
    /// The minus is the typographic minus sign (U+2212), as in the design.
    static func signedString(_ amount: Decimal, currencyCode: String = "CZK", locale: Locale) -> String {
        let body = string(abs(amount), currencyCode: currencyCode, locale: locale)
        if amount > 0 { return "+" + body }
        if amount < 0 { return "\u{2212}" + body }
        return body
    }
}
