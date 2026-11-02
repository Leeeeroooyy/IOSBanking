import Foundation
import SwiftData

@MainActor
protocol WatchlistService {
    func symbols(ownerID: UUID) throws -> [String]
    func add(_ symbol: String, ownerID: UUID) throws
    func remove(_ symbol: String, ownerID: UUID) throws
}

/// The watchlist in SwiftData, separately for every user.
@MainActor
final class LocalWatchlistService: WatchlistService {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    func symbols(ownerID: UUID) throws -> [String] {
        try items(ownerID: ownerID).map(\.symbol)
    }

    func add(_ symbol: String, ownerID: UUID) throws {
        // Adding twice does nothing.
        guard try !items(ownerID: ownerID).contains(where: { $0.symbol == symbol }) else { return }
        context.insert(WatchlistItem(ownerID: ownerID, symbol: symbol))
        try save()
    }

    func remove(_ symbol: String, ownerID: UUID) throws {
        for item in try items(ownerID: ownerID) where item.symbol == symbol {
            context.delete(item)
        }
        try save()
    }

    private func items(ownerID: UUID) throws -> [WatchlistItem] {
        let descriptor = FetchDescriptor<WatchlistItem>(
            predicate: #Predicate { $0.ownerID == ownerID },
            sortBy: [SortDescriptor(\.addedAt)]
        )
        return try context.fetch(descriptor)
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
