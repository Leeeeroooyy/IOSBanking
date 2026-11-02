import Foundation
import SwiftData

/// One movement on one account. Named `BankTransaction` so it does not clash with SwiftUI's `Transaction`.
///
/// A payment between two accounts of the demo bank creates two records, one per account,
/// with the same `transferID`.
@Model
final class BankTransaction {
    enum Direction: String {
        case incoming
        case outgoing
    }

    enum Status: String {
        case completed
        case failed
    }

    enum Category: String, CaseIterable {
        case opening
        case salary
        case rent
        case groceries
        case utilities
        case restaurant
        case transfer
        case interest
        case other
    }

    @Attribute(.unique) var id: UUID
    var transferID: UUID
    var accountID: UUID
    var directionRaw: String
    /// Always positive; `direction` says whether money came in or went out.
    var amountMinorUnits: Int64
    var currencyCode: String
    var counterpartyName: String
    var counterpartyAccount: String?
    var variableSymbol: String?
    var constantSymbol: String?
    var specificSymbol: String?
    var message: String?
    var date: Date
    var statusRaw: String
    var categoryRaw: String
    /// A payment to an account outside the demo bank (simulated: the money only leaves).
    var isExternal: Bool

    init(
        id: UUID = UUID(),
        transferID: UUID = UUID(),
        accountID: UUID,
        direction: Direction,
        amount: Money,
        counterpartyName: String,
        counterpartyAccount: String? = nil,
        variableSymbol: String? = nil,
        constantSymbol: String? = nil,
        specificSymbol: String? = nil,
        message: String? = nil,
        date: Date,
        status: Status = .completed,
        category: Category,
        isExternal: Bool = false
    ) {
        self.id = id
        self.transferID = transferID
        self.accountID = accountID
        self.directionRaw = direction.rawValue
        self.amountMinorUnits = amount.minorUnits
        self.currencyCode = amount.currencyCode
        self.counterpartyName = counterpartyName
        self.counterpartyAccount = counterpartyAccount
        self.variableSymbol = variableSymbol
        self.constantSymbol = constantSymbol
        self.specificSymbol = specificSymbol
        self.message = message
        self.date = date
        self.statusRaw = status.rawValue
        self.categoryRaw = category.rawValue
        self.isExternal = isExternal
    }

    var direction: Direction { Direction(rawValue: directionRaw) ?? .outgoing }
    var status: Status { Status(rawValue: statusRaw) ?? .completed }
    var category: Category { Category(rawValue: categoryRaw) ?? .other }

    var amount: Money {
        Money(minorUnits: amountMinorUnits, currencyCode: currencyCode)
    }

    /// Positive for incoming, negative for outgoing money.
    var signedAmount: Decimal {
        direction == .incoming ? amount.amount : -amount.amount
    }

    /// The same as `signedAmount`, in minor units, for exact sums.
    var signedMinorUnits: Int64 {
        direction == .incoming ? amountMinorUnits : -amountMinorUnits
    }
}
