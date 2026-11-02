import SwiftData

/// Every SwiftData model of the app. The app, previews and tests all build
/// their `ModelContainer` from this list, so a new model cannot be forgotten in one of them.
enum AppSchema {
    static let schema = Schema([
        User.self,
        Account.self,
        BankTransaction.self,
        WatchlistItem.self,
        PaymentTemplate.self,
    ])

    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
