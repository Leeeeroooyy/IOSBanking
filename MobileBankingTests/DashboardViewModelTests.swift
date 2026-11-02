import SwiftData
import XCTest
@testable import MobileBanking

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private func makeBanking() throws -> (LocalBankingService, ModelContainer) {
        let container = try makeTestContainer()
        return (LocalBankingService(container: container), container)
    }

    func testLoadShowsAccountsTotalAndRecentTransactions() throws {
        let (banking, _) = try makeBanking()
        let model = DashboardViewModel(user: User(fullName: "Jana Nováková", email: "jana@example.cz"), banking: banking)
        XCTAssertEqual(model.state, .loading)

        model.load()

        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.accounts.count, 2)
        XCTAssertEqual(model.totalBalance, Decimal(165_250))
        XCTAssertEqual(model.recentTransactions.count, DashboardViewModel.recentLimit)
    }

    func testFailingStorageShowsErrorState() {
        let model = DashboardViewModel(user: User(fullName: "Jana", email: "jana@example.cz"), banking: FailingBankingService())
        model.load()
        XCTAssertEqual(model.state, .failed)
        XCTAssertTrue(model.accounts.isEmpty)
    }

    func testTransactionFilter() throws {
        let (banking, _) = try makeBanking()
        let user = User(fullName: "Jana", email: "jana@example.cz")
        try banking.prepareDemoAccounts(for: user)
        let ids = try banking.accounts(ownerID: user.id).map(\.id)
        let model = TransactionsViewModel(accountIDs: ids, banking: banking)
        model.load()

        let all = model.filtered.count
        model.filter = .incoming
        XCTAssertTrue(model.filtered.allSatisfy { $0.direction == .incoming })
        let incoming = model.filtered.count
        model.filter = .outgoing
        XCTAssertTrue(model.filtered.allSatisfy { $0.direction == .outgoing })
        XCTAssertEqual(incoming + model.filtered.count, all)
    }

    func testGroupingByDayKeepsOrder() {
        let calendar = Calendar(identifier: .gregorian)
        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        let make = { (date: Date) in
            BankTransaction(accountID: UUID(), direction: .outgoing, amount: Money(minorUnits: 100),
                            counterpartyName: "X", date: date, category: .other)
        }
        let newest = make(day1)
        let sameDay = make(day1.addingTimeInterval(-60))
        let dayBefore = make(day1.addingTimeInterval(-86_400 * 2))

        let days = TransactionDay.group([newest, sameDay, dayBefore], calendar: calendar)

        XCTAssertEqual(days.count, 2)
        XCTAssertEqual(days[0].transactions.map(\.id), [newest.id, sameDay.id])
        XCTAssertEqual(days[1].transactions.map(\.id), [dayBefore.id])
    }
}

/// Simulates a broken database.
@MainActor
private final class FailingBankingService: BankingService {
    func prepareDemoAccounts(for user: User) throws { throw BankingError.storageFailed }
    func accounts(ownerID: UUID) throws -> [Account] { throw BankingError.storageFailed }
    func transactions(accountIDs: [UUID], limit: Int?) throws -> [BankTransaction] { throw BankingError.storageFailed }
}
