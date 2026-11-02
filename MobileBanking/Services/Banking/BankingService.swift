import Foundation

enum BankingError: Error, Equatable {
    case storageFailed
}

/// Accounts and transactions of the signed-in user.
///
/// The app uses `LocalBankingService` (SwiftData on this device). A real bank backend
/// would be another implementation of this protocol; the screens would not change.
@MainActor
protocol BankingService {
    /// Opens the demo accounts of a user the first time; does nothing afterwards.
    func prepareDemoAccounts(for user: User) throws
    /// Accounts of a user: current account first, then savings.
    func accounts(ownerID: UUID) throws -> [Account]
    /// Transactions of the given accounts, newest first.
    func transactions(accountIDs: [UUID], limit: Int?) throws -> [BankTransaction]
}
