import SwiftUI

// Texts and icons of the banking models. They live here, next to the screens,
// so the models themselves stay free of SwiftUI.

extension Account.Kind {
    var titleKey: LocalizedStringKey {
        switch self {
        case .current: return "account.kind.current"
        case .savings: return "account.kind.savings"
        }
    }

    var systemImage: String {
        switch self {
        case .current: return "creditcard"
        case .savings: return "banknote"
        }
    }
}

extension BankTransaction.Category {
    var titleKey: LocalizedStringKey {
        switch self {
        case .opening: return "category.opening"
        case .salary: return "category.salary"
        case .rent: return "category.rent"
        case .groceries: return "category.groceries"
        case .utilities: return "category.utilities"
        case .restaurant: return "category.restaurant"
        case .transfer: return "category.transfer"
        case .interest: return "category.interest"
        case .other: return "category.other"
        }
    }

    var systemImage: String {
        switch self {
        case .opening: return "building.columns"
        case .salary: return "briefcase"
        case .rent: return "house"
        case .groceries: return "cart"
        case .utilities: return "bolt"
        case .restaurant: return "cup.and.saucer"
        case .transfer: return "arrow.left.arrow.right"
        case .interest: return "percent"
        case .other: return "person"
        }
    }
}

extension BankTransaction.Direction {
    var titleKey: LocalizedStringKey {
        switch self {
        case .incoming: return "transaction.direction.incoming"
        case .outgoing: return "transaction.direction.outgoing"
        }
    }
}

extension BankTransaction.Status {
    var titleKey: LocalizedStringKey {
        switch self {
        case .completed: return "transaction.status.completed"
        case .failed: return "transaction.status.failed"
        }
    }
}

extension BankTransaction {
    /// Title of a transfer between the user's own accounts.
    var ownTransferTitleKey: LocalizedStringKey {
        direction == .outgoing ? "transaction.toOwnAccount" : "transaction.fromOwnAccount"
    }
}

/// Transactions of one calendar day, for lists grouped by date.
struct TransactionDay: Identifiable {
    let day: Date
    let transactions: [BankTransaction]

    var id: Date { day }

    /// Keeps the order of `transactions` (newest first) inside each day and across days.
    static func group(_ transactions: [BankTransaction], calendar: Calendar = .current) -> [TransactionDay] {
        var days: [TransactionDay] = []
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            if let last = days.last, last.day == day {
                days[days.count - 1] = TransactionDay(day: day, transactions: last.transactions + [transaction])
            } else {
                days.append(TransactionDay(day: day, transactions: [transaction]))
            }
        }
        return days
    }
}
