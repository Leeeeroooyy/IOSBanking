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

        let seed = DemoDataSeeder.makeSeed(for: user, now: now())
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
