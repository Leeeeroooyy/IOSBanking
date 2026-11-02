import Foundation
import Observation

/// Transaction history of one or more accounts, with the incoming / outgoing filter.
@MainActor
@Observable
final class TransactionsViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case incoming
        case outgoing

        var id: String { rawValue }
    }

    var filter: Filter = .all
    private(set) var transactions: [BankTransaction] = []
    private(set) var loadFailed = false

    @ObservationIgnored private let accountIDs: [UUID]
    @ObservationIgnored private let banking: any BankingService

    init(accountIDs: [UUID], banking: any BankingService) {
        self.accountIDs = accountIDs
        self.banking = banking
    }

    func load() {
        do {
            transactions = try banking.transactions(accountIDs: accountIDs, limit: nil)
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    var filtered: [BankTransaction] {
        switch filter {
        case .all: return transactions
        case .incoming: return transactions.filter { $0.direction == .incoming }
        case .outgoing: return transactions.filter { $0.direction == .outgoing }
        }
    }

    var days: [TransactionDay] {
        TransactionDay.group(filtered)
    }
}
