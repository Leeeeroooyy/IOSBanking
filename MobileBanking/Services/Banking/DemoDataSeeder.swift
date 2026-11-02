import Foundation

/// The starting accounts of a user of the demo bank: a current account and a savings account.
///
/// Only the two built-in test profiles start with money (45 250,00 Kč and 120 000,00 Kč),
/// each balance backed by one opening deposit, so "balance = sum of transactions" holds from day one.
/// A newly registered user starts with two empty accounts and can receive money from a test profile.
/// There is no invented history: every other transaction comes from real payments made in the app.
enum DemoDataSeeder {
    static let currentBalance = Money(minorUnits: 4_525_000)
    static let savingsBalance = Money(minorUnits: 12_000_000)
    static let bankName = "Demo banka"

    struct Seed {
        let accounts: [Account]
        let transactions: [BankTransaction]
    }

    static func makeSeed(for user: User, funded: Bool, now: Date = .now) -> Seed {
        let current = Account(
            ownerID: user.id, holderName: user.fullName, kind: .current,
            number: .generate(), balance: funded ? currentBalance : Money(minorUnits: 0), createdAt: now
        )
        let savings = Account(
            ownerID: user.id, holderName: user.fullName, kind: .savings,
            number: .generate(), balance: funded ? savingsBalance : Money(minorUnits: 0), createdAt: now
        )
        guard funded else { return Seed(accounts: [current, savings], transactions: []) }

        return Seed(
            accounts: [current, savings],
            transactions: [openingDeposit(for: current, date: now), openingDeposit(for: savings, date: now)]
        )
    }

    private static func openingDeposit(for account: Account, date: Date) -> BankTransaction {
        BankTransaction(
            accountID: account.id, direction: .incoming,
            amount: account.balance,
            counterpartyName: bankName, date: date, category: .opening
        )
    }
}
