import Foundation
import SwiftData

/// Type of a bank account. Top-level on purpose: types nested inside a `@Model` class
/// can confuse the compiler's handling of the macro-generated conformances.
enum AccountKind: String, CaseIterable {
    case current
    case savings
}

/// A bank account in the demo bank.
@Model
final class Account {
    @Attribute(.unique) var id: UUID
    /// The `User` who owns the account. `nil` means an account of another, imaginary
    /// client of the demo bank (a payment recipient in stage 5).
    var ownerID: UUID?
    var holderName: String
    var kindRaw: String
    /// Formatted Czech account number, e.g. `2000145399/9999`.
    @Attribute(.unique) var number: String
    /// Stored in minor units (haléře), see `Money`.
    var balanceMinorUnits: Int64
    var currencyCode: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        ownerID: UUID?,
        holderName: String,
        kind: AccountKind,
        number: CzechAccountNumber,
        balance: Money,
        createdAt: Date = .now
    ) {
        self.id = id
        self.ownerID = ownerID
        self.holderName = holderName
        self.kindRaw = kind.rawValue
        self.number = number.formatted
        self.balanceMinorUnits = balance.minorUnits
        self.currencyCode = balance.currencyCode
        self.createdAt = createdAt
    }

    var kind: AccountKind {
        AccountKind(rawValue: kindRaw) ?? .current
    }

    var balance: Money {
        Money(minorUnits: balanceMinorUnits, currencyCode: currencyCode)
    }

    /// `•• 5399`
    var maskedNumber: String {
        CzechAccountNumber(number)?.masked ?? number
    }
}
