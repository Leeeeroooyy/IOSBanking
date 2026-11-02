import Foundation
import SwiftData

/// A bank account in the demo bank.
@Model
final class Account {
    enum Kind: String, CaseIterable {
        case current
        case savings
    }

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
        kind: Kind,
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

    var kind: Kind {
        Kind(rawValue: kindRaw) ?? .current
    }

    var balance: Money {
        Money(minorUnits: balanceMinorUnits, currencyCode: currencyCode)
    }

    /// `•• 5399`
    var maskedNumber: String {
        CzechAccountNumber(number)?.masked ?? number
    }
}
