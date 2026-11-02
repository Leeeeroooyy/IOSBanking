import Foundation
import SwiftData

/// `BankingService` on this device: accounts and transactions in SwiftData.
@MainActor
final class LocalBankingService: BankingService {
    private let container: ModelContainer
    private let now: () -> Date

    private var context: ModelContext { container.mainContext }

    /// - Parameter now: injectable clock, so tests get stable dates.
    init(container: ModelContainer, now: @escaping () -> Date = { .now }) {
        self.container = container
        self.now = now
    }

    func prepareDemoAccounts(for user: User) throws {
        guard try accounts(ownerID: user.id).isEmpty else { return }

        // Only the built-in test profiles start with money.
        let seed = DemoDataSeeder.makeSeed(for: user, funded: TestAccounts.emails.contains(user.email), now: now())
        for account in seed.accounts { context.insert(account) }
        for transaction in seed.transactions { context.insert(transaction) }
        do {
            try context.save()
        } catch {
            // Never leave half of the demo data behind.
            context.rollback()
            throw BankingError.storageFailed
        }
    }

    /// Version of the demo data. Raising it clears old accounts and transactions once
    /// (e.g. after the invented history was removed); users and passwords stay.
    static let demoDataVersion = 2
    static let demoDataVersionKey = "demoDataVersion"

    func resetDemoDataIfNeeded(defaults: UserDefaults = .standard) {
        guard defaults.integer(forKey: Self.demoDataVersionKey) < Self.demoDataVersion else { return }
        do {
            try context.delete(model: BankTransaction.self)
            try context.delete(model: Account.self)
            try context.save()
            defaults.set(Self.demoDataVersion, forKey: Self.demoDataVersionKey)
        } catch {
            context.rollback()
        }
    }

    func accounts(ownerID: UUID) throws -> [Account] {
        let owner: UUID? = ownerID
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate { $0.ownerID == owner },
            sortBy: [SortDescriptor(\.kindRaw), SortDescriptor(\.createdAt)]
        )
        do {
            // "current" sorts before "savings", which is the order we want on screen.
            return try context.fetch(descriptor)
        } catch {
            throw BankingError.storageFailed
        }
    }

    func demoRecipients() throws -> [Account] {
        do {
            // The current accounts of the test profiles: payments to them really arrive.
            let testUserIDs = Set(try context.fetch(FetchDescriptor<User>())
                .filter { TestAccounts.emails.contains($0.email) }
                .map(\.id))
            let current = AccountKind.current.rawValue
            let descriptor = FetchDescriptor<Account>(
                predicate: #Predicate { $0.kindRaw == current },
                sortBy: [SortDescriptor(\.holderName)]
            )
            return try context.fetch(descriptor).filter { account in
                guard let owner = account.ownerID else { return false }
                return testUserIDs.contains(owner)
            }
        } catch {
            throw BankingError.storageFailed
        }
    }

    func executeTransfer(_ request: TransferRequest) throws -> TransferReceipt {
        // Idempotency: the request ID is the transfer ID, so a repeated request finds its first result.
        if let done = try existingOutgoing(transferID: request.id),
           let source = try account(id: done.accountID) {
            return TransferReceipt(transaction: done, newBalance: source.balance, isExternal: done.isExternal)
        }

        guard let source = try account(id: request.fromAccountID) else { throw TransferError.sourceAccountMissing }
        let targetNumber = request.recipientAccount.formatted
        guard targetNumber != source.number else { throw TransferError.sameAccount }
        let amount = request.amount.minorUnits
        guard amount > 0 else { throw TransferError.invalidAmount }
        // Checked again here: the balance may have changed since the form was filled in.
        guard source.balanceMinorUnits >= amount else { throw TransferError.insufficientFunds }

        let recipient = try account(number: targetNumber)
        let isOwnTransfer = recipient != nil && recipient?.ownerID == source.ownerID
        let category: TransactionCategory = isOwnTransfer ? .transfer : .other
        let date = now()
        let name = request.recipientName.isEmpty ? (recipient?.holderName ?? targetNumber) : request.recipientName

        source.balanceMinorUnits -= amount
        let outgoing = BankTransaction(
            transferID: request.id, accountID: source.id, direction: .outgoing, amount: request.amount,
            counterpartyName: name, counterpartyAccount: targetNumber,
            variableSymbol: request.variableSymbol, constantSymbol: request.constantSymbol,
            specificSymbol: request.specificSymbol, message: request.message,
            date: date, category: category, isExternal: recipient == nil
        )
        context.insert(outgoing)

        if let recipient {
            recipient.balanceMinorUnits += amount
            context.insert(BankTransaction(
                transferID: request.id, accountID: recipient.id, direction: .incoming, amount: request.amount,
                counterpartyName: source.holderName, counterpartyAccount: source.number,
                variableSymbol: request.variableSymbol, constantSymbol: request.constantSymbol,
                specificSymbol: request.specificSymbol, message: request.message,
                date: date, category: category
            ))
        }

        do {
            // One save: both balances and both records change together, or not at all.
            try context.save()
        } catch {
            context.rollback()
            throw TransferError.storageFailed
        }
        return TransferReceipt(transaction: outgoing, newBalance: source.balance, isExternal: recipient == nil)
    }

    private func account(id: UUID) throws -> Account? {
        var descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        do { return try context.fetch(descriptor).first } catch { throw TransferError.storageFailed }
    }

    private func account(number: String) throws -> Account? {
        var descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.number == number })
        descriptor.fetchLimit = 1
        do { return try context.fetch(descriptor).first } catch { throw TransferError.storageFailed }
    }

    private func existingOutgoing(transferID: UUID) throws -> BankTransaction? {
        let outgoing = TransactionDirection.outgoing.rawValue
        var descriptor = FetchDescriptor<BankTransaction>(
            predicate: #Predicate { $0.transferID == transferID && $0.directionRaw == outgoing }
        )
        descriptor.fetchLimit = 1
        do { return try context.fetch(descriptor).first } catch { throw TransferError.storageFailed }
    }

    func transactions(accountIDs: [UUID], limit: Int?) throws -> [BankTransaction] {
        var descriptor = FetchDescriptor<BankTransaction>(
            predicate: #Predicate { accountIDs.contains($0.accountID) },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            return try context.fetch(descriptor)
        } catch {
            throw BankingError.storageFailed
        }
    }
}
