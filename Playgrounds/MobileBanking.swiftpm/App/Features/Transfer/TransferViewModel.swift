import Foundation
import Observation
import SwiftUI

/// The payment flow of the "Platby" tab: form → confirmation → result.
@MainActor
@Observable
final class TransferViewModel {
    enum Field: Hashable {
        case recipientName
        case recipientAccount
        case amount
        case variableSymbol
        case constantSymbol
        case specificSymbol
        case message
    }

    enum Outcome {
        case success(TransferReceipt)
        case failure(TransferError)
    }

    // Form
    var fromAccountID: UUID?
    var recipientName = ""
    var recipientAccount = ""
    var amountText = ""
    var variableSymbol = ""
    var constantSymbol = ""
    var specificSymbol = ""
    var message = ""

    // Navigation
    var isConfirmationPresented = false
    var isResultPresented = false

    private(set) var accounts: [Account] = []
    private(set) var recipients: [Account] = []
    private(set) var loadFailed = false
    private(set) var errors: [Field: TransferFieldError] = [:]
    private(set) var request: TransferRequest?
    private(set) var isProcessing = false
    private(set) var outcome: Outcome?

    let user: User
    @ObservationIgnored private let banking: any BankingService

    init(user: User, banking: any BankingService) {
        self.user = user
        self.banking = banking
    }

    var sourceAccount: Account? {
        accounts.first { $0.id == fromAccountID }
    }

    /// Own accounts other than the source, then other clients of the demo bank.
    var suggestedRecipients: [Account] {
        accounts.filter { $0.id != fromAccountID } + recipients.filter { $0.ownerID != user.id }
    }

    func load() {
        do {
            try banking.prepareDemoAccounts(for: user)
            accounts = try banking.accounts(ownerID: user.id)
            recipients = try banking.demoRecipients()
            if fromAccountID == nil || sourceAccount == nil {
                fromAccountID = accounts.first?.id
            }
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    func fill(recipient account: Account) {
        recipientAccount = account.number
        recipientName = account.ownerID == user.id ? "" : account.holderName
        errors[.recipientAccount] = nil
        errors[.recipientName] = nil
    }

    // MARK: - Step 1: check the form

    /// Checks every field. When everything is fine, prepares the request and opens the confirmation.
    func review() {
        var problems: [Field: TransferFieldError] = [:]
        let source = sourceAccount

        let number = CzechAccountNumber(recipientAccount)
        if recipientAccount.trimmingCharacters(in: .whitespaces).isEmpty {
            problems[.recipientAccount] = .required
        } else if number == nil {
            problems[.recipientAccount] = .invalidAccountNumber
        } else if number?.formatted == source?.number {
            problems[.recipientAccount] = .sameAccount
        }

        problems[.amount] = TransferRules.amountError(amountText, availableMinorUnits: source?.balanceMinorUnits)
        problems[.recipientName] = TransferRules.textError(recipientName, maxLength: TransferRules.maxNameLength)
        problems[.message] = TransferRules.textError(message, maxLength: TransferRules.maxMessageLength)
        problems[.variableSymbol] = TransferRules.symbolError(variableSymbol)
        problems[.constantSymbol] = TransferRules.symbolError(constantSymbol)
        problems[.specificSymbol] = TransferRules.symbolError(specificSymbol)

        errors = problems.compactMapValues { $0 }
        guard
            errors.isEmpty,
            let source,
            let number,
            let amount = TransferRules.parseAmount(amountText).flatMap({ Money(amount: $0, currencyCode: source.currencyCode) })
        else { return }

        // A new ID for every confirmation screen: it protects this payment from being sent twice.
        request = TransferRequest(
            id: UUID(),
            fromAccountID: source.id,
            recipientName: recipientName.trimmingCharacters(in: .whitespacesAndNewlines),
            recipientAccount: number,
            amount: amount,
            variableSymbol: TransferRules.optional(variableSymbol),
            constantSymbol: TransferRules.optional(constantSymbol),
            specificSymbol: TransferRules.optional(specificSymbol),
            message: TransferRules.optional(message)
        )
        isConfirmationPresented = true
    }

    /// Balance of the source account after the payment, shown on the confirmation screen.
    var balanceAfterTransfer: Decimal? {
        guard let source = sourceAccount, let request else { return nil }
        return source.balance.amount - request.amount.amount
    }

    // MARK: - Step 2: send

    func confirm() {
        guard let request, !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        do {
            outcome = .success(try banking.executeTransfer(request))
        } catch let error as TransferError {
            outcome = .failure(error)
        } catch {
            outcome = .failure(.storageFailed)
        }
        isResultPresented = true
    }

    // MARK: - Step 3: finish

    /// After a successful payment: an empty form, back at the start.
    func startNewPayment() {
        recipientName = ""
        recipientAccount = ""
        amountText = ""
        variableSymbol = ""
        constantSymbol = ""
        specificSymbol = ""
        message = ""
        errors = [:]
        request = nil
        outcome = nil
        isResultPresented = false
        isConfirmationPresented = false
        load()
    }

    /// After a failure: back to the form with everything filled in.
    func editPayment() {
        outcome = nil
        isResultPresented = false
        isConfirmationPresented = false
        load()
    }
}

extension TransferFieldError {
    var messageKey: LocalizedStringKey {
        switch self {
        case .required: return "transfer.error.required"
        case .invalidAccountNumber: return "transfer.error.accountNumber"
        case .sameAccount: return "transfer.error.sameAccount"
        case .invalidAmount: return "transfer.error.amount"
        case .tooManyDecimals: return "transfer.error.decimals"
        case .amountTooLarge: return "transfer.error.amountTooLarge"
        case .insufficientFunds: return "transfer.error.insufficientFunds"
        case .digitsOnly(let maxLength): return "transfer.error.digits \(maxLength)"
        case .tooLong(let maxLength): return "transfer.error.tooLong \(maxLength)"
        }
    }
}

extension TransferError {
    var messageKey: LocalizedStringKey {
        switch self {
        case .sourceAccountMissing: return "transfer.failure.sourceMissing"
        case .sameAccount: return "transfer.error.sameAccount"
        case .invalidAmount: return "transfer.error.amount"
        case .insufficientFunds: return "transfer.error.insufficientFunds"
        case .storageFailed: return "transfer.failure.storage"
        }
    }
}
