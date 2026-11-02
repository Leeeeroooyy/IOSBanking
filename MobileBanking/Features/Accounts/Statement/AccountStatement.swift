import Foundation

/// The data of a monthly account statement ("výpis z účtu").
/// Pure calculation, no UI: the PDF renderer only draws what is here.
struct AccountStatement {
    let accountKind: AccountKind
    let accountNumber: String
    let iban: String?
    let holderName: String
    let currencyCode: String
    let period: DateInterval
    let openingBalance: Decimal
    let closingBalance: Decimal
    let totalIncoming: Decimal
    let totalOutgoing: Decimal
    /// Oldest first, as on a paper statement.
    let transactions: [BankTransaction]
    let createdAt: Date

    /// - Parameters:
    ///   - history: every transaction of the account (any order).
    ///   - month: any day of the wanted month.
    static func make(
        account: Account,
        history: [BankTransaction],
        month: Date,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> AccountStatement {
        let period = calendar.dateInterval(of: .month, for: month) ?? DateInterval(start: month, duration: 0)

        // The balance today minus everything that happened later gives the balance at any moment.
        func balance(at moment: Date) -> Int64 {
            account.balanceMinorUnits - history.filter { $0.date >= moment }.reduce(0) { $0 + $1.signedMinorUnits }
        }

        let inPeriod = history
            .filter { $0.date >= period.start && $0.date < period.end }
            .sorted { $0.date < $1.date }
        let incoming = inPeriod.filter { $0.direction == .incoming }.reduce(Int64(0)) { $0 + $1.amountMinorUnits }
        let outgoing = inPeriod.filter { $0.direction == .outgoing }.reduce(Int64(0)) { $0 + $1.amountMinorUnits }

        return AccountStatement(
            accountKind: account.kind,
            accountNumber: account.number,
            iban: CzechAccountNumber(account.number)?.iban,
            holderName: account.holderName,
            currencyCode: account.currencyCode,
            period: period,
            openingBalance: Money(minorUnits: balance(at: period.start)).amount,
            closingBalance: Money(minorUnits: balance(at: period.end)).amount,
            totalIncoming: Money(minorUnits: incoming).amount,
            totalOutgoing: Money(minorUnits: outgoing).amount,
            transactions: inPeriod,
            createdAt: now
        )
    }

    /// Months that can be chosen: from the month the account was opened up to this month, newest first.
    static func availableMonths(since opened: Date, now: Date = .now, calendar: Calendar = .current) -> [Date] {
        guard
            let first = calendar.dateInterval(of: .month, for: opened)?.start,
            let last = calendar.dateInterval(of: .month, for: now)?.start
        else { return [now] }
        var months: [Date] = []
        var month = last
        while month >= first && months.count < 24 {
            months.append(month)
            guard let previous = calendar.date(byAdding: .month, value: -1, to: month) else { break }
            month = previous
        }
        return months
    }
}
