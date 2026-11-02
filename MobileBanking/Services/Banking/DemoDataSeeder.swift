import Foundation

/// The starting data of a new user of the demo bank: a current account (45 250,00 Kč)
/// and a savings account (120 000,00 Kč), each with about a month of history.
///
/// Every account starts with an opening deposit computed so that the balance always equals
/// the sum of its transactions. Counterparties are invented names with account numbers
/// in the made-up demo bank, so no real account appears in the app.
enum DemoDataSeeder {
    static let currentBalance = Money(minorUnits: 4_525_000)
    static let savingsBalance = Money(minorUnits: 12_000_000)
    static let bankName = "Demo banka"

    struct Seed {
        let accounts: [Account]
        let transactions: [BankTransaction]
    }

    static func makeSeed(for user: User, now: Date = .now) -> Seed {
        let current = Account(
            ownerID: user.id, holderName: user.fullName, kind: .current,
            number: .generate(), balance: currentBalance, createdAt: now
        )
        let savings = Account(
            ownerID: user.id, holderName: user.fullName, kind: .savings,
            number: .generate(), balance: savingsBalance, createdAt: now
        )

        func ago(days: Double, hours: Double = 0) -> Date {
            now.addingTimeInterval(-(days * 86_400 + hours * 3_600))
        }

        // One transfer from the current account to savings: two records, one transfer ID.
        let savingsTransferID = UUID()

        var currentHistory: [BankTransaction] = [
            BankTransaction(
                accountID: current.id, direction: .incoming, amount: Money(minorUnits: 3_850_000),
                counterpartyName: "Demo Firma s.r.o.", counterpartyAccount: CzechAccountNumber.generate().formatted,
                variableSymbol: "202610", message: "Mzda", date: ago(days: 28, hours: 3), category: .salary
            ),
            BankTransaction(
                accountID: current.id, direction: .outgoing, amount: Money(minorUnits: 1_400_000),
                counterpartyName: "Bytové družstvo Demo", counterpartyAccount: CzechAccountNumber.generate().formatted,
                variableSymbol: "1024", message: "Nájem", date: ago(days: 27, hours: 5), category: .rent
            ),
            BankTransaction(
                accountID: current.id, direction: .outgoing, amount: Money(minorUnits: 189_000),
                counterpartyName: "Demo Energie a.s.", variableSymbol: "8800123",
                date: ago(days: 25, hours: 2), category: .utilities
            ),
            BankTransaction(
                accountID: current.id, direction: .outgoing, amount: Money(minorUnits: 124_890),
                counterpartyName: "Supermarket", date: ago(days: 22, hours: 6), category: .groceries
            ),
            BankTransaction(
                transferID: savingsTransferID, accountID: current.id, direction: .outgoing,
                amount: Money(minorUnits: 500_000), counterpartyName: user.fullName,
                counterpartyAccount: savings.number, message: "Spoření",
                date: ago(days: 20, hours: 1), category: .transfer
            ),
            BankTransaction(
                accountID: current.id, direction: .outgoing, amount: Money(minorUnits: 34_500),
                counterpartyName: "Kavárna U Rohu", date: ago(days: 15, hours: 4), category: .restaurant
            ),
            BankTransaction(
                accountID: current.id, direction: .incoming, amount: Money(minorUnits: 35_000),
                counterpartyName: "Jana Nováková", counterpartyAccount: CzechAccountNumber.generate().formatted,
                message: "Za lístky do kina", date: ago(days: 10, hours: 2), category: .other
            ),
            BankTransaction(
                accountID: current.id, direction: .outgoing, amount: Money(minorUnits: 87_640),
                counterpartyName: "Supermarket", date: ago(days: 6, hours: 5), category: .groceries
            ),
            BankTransaction(
                accountID: current.id, direction: .outgoing, amount: Money(minorUnits: 49_900),
                counterpartyName: "Demo Mobil", variableSymbol: "7712",
                date: ago(days: 4, hours: 3), category: .utilities
            ),
            BankTransaction(
                accountID: current.id, direction: .outgoing, amount: Money(minorUnits: 18_900),
                counterpartyName: "Bistro", date: ago(days: 2, hours: 1), category: .restaurant
            ),
            BankTransaction(
                accountID: current.id, direction: .incoming, amount: Money(minorUnits: 120_000),
                counterpartyName: "Petr Svoboda", message: "Vracím půjčku",
                date: ago(days: 0, hours: 2), category: .other
            ),
        ]

        var savingsHistory: [BankTransaction] = [
            BankTransaction(
                transferID: savingsTransferID, accountID: savings.id, direction: .incoming,
                amount: Money(minorUnits: 500_000), counterpartyName: user.fullName,
                counterpartyAccount: current.number, message: "Spoření",
                date: ago(days: 20, hours: 1), category: .transfer
            ),
            BankTransaction(
                accountID: savings.id, direction: .incoming, amount: Money(minorUnits: 41_250),
                counterpartyName: bankName, date: ago(days: 1, hours: 8), category: .interest
            ),
        ]

        currentHistory.append(openingDeposit(for: current, history: currentHistory, date: ago(days: 45)))
        savingsHistory.append(openingDeposit(for: savings, history: savingsHistory, date: ago(days: 60)))

        return Seed(accounts: [current, savings], transactions: currentHistory + savingsHistory)
    }

    /// The deposit that makes "balance = sum of all transactions" true from the first day.
    private static func openingDeposit(for account: Account, history: [BankTransaction], date: Date) -> BankTransaction {
        let net = history.reduce(Int64(0)) { $0 + $1.signedMinorUnits }
        return BankTransaction(
            accountID: account.id, direction: .incoming,
            amount: Money(minorUnits: account.balanceMinorUnits - net),
            counterpartyName: bankName, date: date, category: .opening
        )
    }
}
