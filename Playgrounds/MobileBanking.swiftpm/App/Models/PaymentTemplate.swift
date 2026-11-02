import Foundation
import SwiftData

/// A saved payment ("šablona"): recipient and payment details to reuse with one tap.
/// The amount is optional, so a template can also be just a favourite recipient.
@Model
final class PaymentTemplate {
    var ownerID: UUID
    var name: String
    var recipientName: String
    var recipientAccount: String
    var amountMinorUnits: Int64?
    var variableSymbol: String?
    var constantSymbol: String?
    var specificSymbol: String?
    var message: String?
    var createdAt: Date

    init(
        ownerID: UUID,
        name: String,
        recipientName: String,
        recipientAccount: String,
        amountMinorUnits: Int64? = nil,
        variableSymbol: String? = nil,
        constantSymbol: String? = nil,
        specificSymbol: String? = nil,
        message: String? = nil,
        createdAt: Date = .now
    ) {
        self.ownerID = ownerID
        self.name = name
        self.recipientName = recipientName
        self.recipientAccount = recipientAccount
        self.amountMinorUnits = amountMinorUnits
        self.variableSymbol = variableSymbol
        self.constantSymbol = constantSymbol
        self.specificSymbol = specificSymbol
        self.message = message
        self.createdAt = createdAt
    }

    var amount: Money? {
        amountMinorUnits.map { Money(minorUnits: $0) }
    }
}
