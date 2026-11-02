import Foundation

/// A checked payment, ready to be executed.
///
/// `id` is created when the user opens the confirmation screen. It becomes the
/// `transferID` of the transactions, so sending the same request twice (a double tap,
/// a retry) never moves the money twice.
struct TransferRequest: Equatable {
    let id: UUID
    let fromAccountID: UUID
    /// Optional; when empty the recipient's account number is shown instead.
    let recipientName: String
    let recipientAccount: CzechAccountNumber
    let amount: Money
    let variableSymbol: String?
    let constantSymbol: String?
    let specificSymbol: String?
    let message: String?
}

/// The result of a successful payment.
struct TransferReceipt {
    let transaction: BankTransaction
    let newBalance: Money
    /// The recipient is outside the demo bank: the money only left (simulation).
    let isExternal: Bool
}

/// Why the bank refused or could not finish a payment.
enum TransferError: Error, Equatable {
    case sourceAccountMissing
    case sameAccount
    case invalidAmount
    case insufficientFunds
    case storageFailed
}

/// Problems with one field of the payment form.
enum TransferFieldError: Equatable {
    case required
    case invalidAccountNumber
    case sameAccount
    case invalidAmount
    case tooManyDecimals
    case amountTooLarge
    case insufficientFunds
    case digitsOnly(maxLength: Int)
    case tooLong(maxLength: Int)
}

/// Input rules of the payment form. Pure functions, no storage.
enum TransferRules {
    static let maxAmount = Decimal(string: "999999999.99")!
    static let maxSymbolLength = 10
    static let maxMessageLength = 140
    static let maxNameLength = 70

    /// Accepts "1 250,50", "1250.50", "1250" and "1 250 Kč". Returns nil for anything else.
    static func parseAmount(_ text: String) -> Decimal? {
        var cleaned = text
            .replacingOccurrences(of: "Kč", with: "")
            .replacingOccurrences(of: "CZK", with: "")
            .filter { !$0.isWhitespace }
            .replacingOccurrences(of: ",", with: ".")
        if cleaned.hasPrefix("+") { cleaned.removeFirst() }
        guard
            !cleaned.isEmpty,
            cleaned.filter({ $0 == "." }).count <= 1,
            cleaned.allSatisfy({ $0.isNumber || $0 == "." }),
            cleaned.first != ".", cleaned.last != "."
        else { return nil }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func amountError(_ text: String, availableMinorUnits: Int64?) -> TransferFieldError? {
        if text.trimmingCharacters(in: .whitespaces).isEmpty { return .required }
        guard let amount = parseAmount(text), amount > 0 else { return .invalidAmount }
        guard let money = Money(amount: amount) else { return .tooManyDecimals }
        if amount > maxAmount { return .amountTooLarge }
        if let available = availableMinorUnits, money.minorUnits > available { return .insufficientFunds }
        return nil
    }

    /// Optional digits-only field (VS, KS, SS).
    static func symbolError(_ text: String) -> TransferFieldError? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let valid = trimmed.count <= maxSymbolLength && trimmed.allSatisfy { ("0"..."9").contains($0) }
        return valid ? nil : .digitsOnly(maxLength: maxSymbolLength)
    }

    static func textError(_ text: String, maxLength: Int) -> TransferFieldError? {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count > maxLength ? .tooLong(maxLength: maxLength) : nil
    }

    /// `nil` for an empty field, so optional texts are not stored as "".
    static func optional(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
