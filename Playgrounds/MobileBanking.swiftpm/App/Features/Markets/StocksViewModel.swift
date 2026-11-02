import Foundation
import Observation
import SwiftUI

/// Stocks part of the "Trhy" tab: quotes, the user's watchlist and one stock's chart.
@MainActor
@Observable
final class StocksViewModel {
    private(set) var state: LoadState<[StockQuote]> = .loading
    private(set) var watchlist: [String] = []
    private(set) var watchlistFailed = false

    let user: User
    @ObservationIgnored let service: any StockService
    @ObservationIgnored private let watchlistService: any WatchlistService

    init(user: User, service: any StockService, watchlistService: any WatchlistService) {
        self.user = user
        self.service = service
        self.watchlistService = watchlistService
    }

    var isDemo: Bool { service.isDemo }

    func load() async {
        loadWatchlist()
        do {
            state = .loaded(try await service.quotes())
        } catch {
            state = .failed(error as? NetworkError ?? .invalidResponse)
        }
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    private var quotes: [StockQuote] {
        if case .loaded(let quotes) = state { return quotes }
        return []
    }

    /// Followed stocks, in the order they were added.
    var watchedQuotes: [StockQuote] {
        watchlist.compactMap { symbol in quotes.first { $0.symbol == symbol } }
    }

    var otherQuotes: [StockQuote] {
        quotes.filter { !watchlist.contains($0.symbol) }
    }

    func isWatched(_ symbol: String) -> Bool {
        watchlist.contains(symbol)
    }

    func toggleWatch(_ symbol: String) {
        do {
            if isWatched(symbol) {
                try watchlistService.remove(symbol, ownerID: user.id)
            } else {
                try watchlistService.add(symbol, ownerID: user.id)
            }
            loadWatchlist()
        } catch {
            watchlistFailed = true
        }
    }

    func dismissWatchlistError() {
        watchlistFailed = false
    }

    private func loadWatchlist() {
        do {
            watchlist = try watchlistService.symbols(ownerID: user.id)
        } catch {
            watchlistFailed = true
        }
    }
}
