import Foundation
import Observation

/// State of the "Přehled" tab: accounts, total balance and the latest transactions.
@MainActor
@Observable
final class DashboardViewModel {
    enum State: Equatable {
        case loading
        case loaded
        case failed
    }

    static let recentLimit = 5

    private(set) var state: State = .loading
    private(set) var accounts: [Account] = []
    private(set) var recentTransactions: [BankTransaction] = []

    let user: User
    @ObservationIgnored private let banking: any BankingService

    init(user: User, banking: any BankingService) {
        self.user = user
        self.banking = banking
    }

    /// Sum of all CZK accounts. Only CZK exists in the demo bank for now.
    var totalBalance: Decimal {
        accounts
            .filter { $0.currencyCode == "CZK" }
            .reduce(Decimal(0)) { $0 + $1.balance.amount }
    }

    var accountIDs: [UUID] { accounts.map(\.id) }

    /// Opens the demo accounts on the first visit, then reads fresh data
    /// (called again when the screen appears, so balances are never stale).
    func load() {
        do {
            try banking.prepareDemoAccounts(for: user)
            accounts = try banking.accounts(ownerID: user.id)
            recentTransactions = try banking.transactions(accountIDs: accountIDs, limit: Self.recentLimit)
            state = .loaded
        } catch {
            state = .failed
        }
    }
}
