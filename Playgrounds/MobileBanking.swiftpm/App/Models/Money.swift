import Foundation

/// An amount of money.
///
/// The database stores whole minor units (haléře, 1 Kč = 100 haléřů) as `Int64`,
/// calculations and the screen use `Decimal`. `Float` and `Double` are never used
/// for money: they cannot store values like 0.10 exactly.
struct Money: Hashable {
    static let minorUnitsPerUnit: Int64 = 100

    let minorUnits: Int64
    let currencyCode: String

    init(minorUnits: Int64, currencyCode: String = "CZK") {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }

    /// Fails for amounts with more than two decimal places or too large to store.
    init?(amount: Decimal, currencyCode: String = "CZK") {
        var scaled = amount * Decimal(Self.minorUnitsPerUnit)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        guard rounded == scaled else { return nil }

        let number = NSDecimalNumber(decimal: rounded)
        guard
            number.compare(NSDecimalNumber(value: Int64.max)) != .orderedDescending,
            number.compare(NSDecimalNumber(value: Int64.min)) != .orderedAscending
        else { return nil }

        self.minorUnits = number.int64Value
        self.currencyCode = currencyCode
    }

    /// 4_525_000 minor units → 45250.00
    var amount: Decimal {
        Decimal(minorUnits) / Decimal(Self.minorUnitsPerUnit)
    }
}
