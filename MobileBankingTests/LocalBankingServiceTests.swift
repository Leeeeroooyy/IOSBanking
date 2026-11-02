import SwiftData
import XCTest
@testable import MobileBanking

@MainActor
final class LocalBankingServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var service: LocalBankingService!
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() async throws {
        container = try makeTestContainer()
        service = LocalBankingService(container: container, now: { [now] in now })
    }

    override func tearDown() async throws {
        service = nil
        container = nil
    }

    /// A test profile (starts with money) unless `email` says otherwise.
    private func makeUser(_ name: String = "Jana Nováková", email: String = TestAccounts.profiles[0].email) -> User {
        let user = User(fullName: name, email: email)
        container.mainContext.insert(user)
        return user
    }

    func testNewUserGetsCurrentAndSavingsAccount() throws {
        let user = makeUser()
        try service.prepareDemoAccounts(for: user)

        let accounts = try service.accounts(ownerID: user.id)
        XCTAssertEqual(accounts.map(\.kind), [.current, .savings])
        XCTAssertEqual(accounts.map(\.balance.amount), [Decimal(45_250), Decimal(120_000)])
        XCTAssertTrue(accounts.allSatisfy { $0.holderName == "Jana Nováková" })
        XCTAssertTrue(accounts.allSatisfy { CzechAccountNumber($0.number) != nil }, "Numbers must be valid")
    }

    func testPreparingTwiceDoesNotDuplicateAnything() throws {
        let user = makeUser()
        try service.prepareDemoAccounts(for: user)
        let firstIDs = try service.accounts(ownerID: user.id).map(\.id)

        try service.prepareDemoAccounts(for: user)

        XCTAssertEqual(try service.accounts(ownerID: user.id).map(\.id), firstIDs)
        let all = try container.mainContext.fetch(FetchDescriptor<BankTransaction>())
        XCTAssertEqual(all.count, try service.transactions(accountIDs: firstIDs, limit: nil).count)
    }

    /// The core rule of the demo bank: an account balance equals the sum of its movements.
    func testBalanceEqualsSumOfTransactions() throws {
        let user = makeUser()
        try service.prepareDemoAccounts(for: user)

        for account in try service.accounts(ownerID: user.id) {
            let history = try service.transactions(accountIDs: [account.id], limit: nil)
            let sum = history.reduce(Int64(0)) { $0 + $1.signedMinorUnits }
            XCTAssertEqual(sum, account.balanceMinorUnits, "\(account.kind)")
            XCTAssertTrue(history.allSatisfy { $0.amountMinorUnits > 0 })
        }
    }

    /// Only the test profiles start with money; a registered user starts with two empty accounts.
    func testRegisteredUserStartsWithEmptyAccounts() throws {
        let user = makeUser("Nový klient", email: "novy@example.cz")
        try service.prepareDemoAccounts(for: user)

        let accounts = try service.accounts(ownerID: user.id)
        XCTAssertEqual(accounts.map(\.kind), [.current, .savings])
        XCTAssertTrue(accounts.allSatisfy { $0.balanceMinorUnits == 0 })
        XCTAssertTrue(try service.transactions(accountIDs: accounts.map(\.id), limit: nil).isEmpty)
    }

    func testTestProfileHasOnlyOpeningDeposits() throws {
        let user = makeUser()
        try service.prepareDemoAccounts(for: user)
        let ids = try service.accounts(ownerID: user.id).map(\.id)

        let history = try service.transactions(accountIDs: ids, limit: nil)
        XCTAssertEqual(history.count, 2)
        XCTAssertTrue(history.allSatisfy { $0.category == .opening && $0.direction == .incoming })
    }

    func testTransactionsAreNewestFirstAndLimited() throws {
        let user = makeUser()
        try service.prepareDemoAccounts(for: user)
        let ids = try service.accounts(ownerID: user.id).map(\.id)

        let all = try service.transactions(accountIDs: ids, limit: nil)
        XCTAssertEqual(all.map(\.date), all.map(\.date).sorted(by: >))
        XCTAssertTrue(all.allSatisfy { $0.date <= now })

        let recent = try service.transactions(accountIDs: ids, limit: 1)
        XCTAssertEqual(recent.map(\.id), Array(all.prefix(1)).map(\.id))
    }

    func testUsersSeeOnlyTheirOwnAccounts() throws {
        let jana = makeUser("Jana Nováková", email: TestAccounts.profiles[0].email)
        let petr = makeUser("Petr Svoboda", email: TestAccounts.profiles[1].email)
        try service.prepareDemoAccounts(for: jana)
        try service.prepareDemoAccounts(for: petr)

        let janaAccounts = try service.accounts(ownerID: jana.id)
        let petrAccounts = try service.accounts(ownerID: petr.id)
        XCTAssertEqual(janaAccounts.count, 2)
        XCTAssertEqual(petrAccounts.count, 2)
        XCTAssertTrue(Set(janaAccounts.map(\.id)).isDisjoint(with: petrAccounts.map(\.id)))

        let janaHistory = try service.transactions(accountIDs: janaAccounts.map(\.id), limit: nil)
        XCTAssertTrue(janaHistory.allSatisfy { Set(janaAccounts.map(\.id)).contains($0.accountID) })
    }
}
