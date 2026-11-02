import Foundation
import Observation

/// The user's personal Finnhub API key, stored in the Keychain (never in the source code or git).
/// Without a key the app shows demo quotes.
@MainActor
@Observable
final class StockAPIKeyStore {
    static let account = "finnhub.apiKey"

    private(set) var hasKey: Bool
    @ObservationIgnored private let keychain: any KeychainService

    init(keychain: any KeychainService) {
        self.keychain = keychain
        hasKey = (try? keychain.read(account: Self.account)) != nil
    }

    func key() -> String? {
        guard let data = try? keychain.read(account: Self.account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try keychain.save(Data(trimmed.utf8), account: Self.account)
        hasKey = true
    }

    func remove() throws {
        try keychain.delete(account: Self.account)
        hasKey = false
    }
}

/// Real quotes from Finnhub (https://finnhub.io), free plan: 60 requests per minute, US stocks.
/// The free plan has no price history, so the chart is not available with live data.
@MainActor
final class FinnhubStockService: StockService {
    let isDemo = false
    let hasHistory = false

    /// Shown in the list. Names are kept here, so one request per stock is enough.
    static let companies: [(symbol: String, name: String)] = [
        ("AAPL", "Apple"),
        ("MSFT", "Microsoft"),
        ("NVDA", "NVIDIA"),
        ("AMZN", "Amazon"),
        ("GOOGL", "Alphabet (Google)"),
        ("META", "Meta Platforms"),
        ("TSLA", "Tesla"),
        ("NFLX", "Netflix"),
        ("AMD", "AMD"),
        ("JPM", "JPMorgan Chase"),
    ]

    private struct Quote: Decodable {
        /// Current price.
        let c: Double
        /// Previous close.
        let pc: Double
    }

    private let apiKey: String
    private let client: APIClient

    init(apiKey: String, client: APIClient = APIClient()) {
        self.apiKey = apiKey
        self.client = client
    }

    func quotes() async throws -> [StockQuote] {
        var results: [String: StockQuote] = [:]
        var firstError: Error?

        await withTaskGroup(of: (String, Result<StockQuote?, Error>).self) { group in
            for company in Self.companies {
                group.addTask { @MainActor in
                    do {
                        return (company.symbol, .success(try await self.quote(symbol: company.symbol, name: company.name)))
                    } catch {
                        return (company.symbol, .failure(error))
                    }
                }
            }
            for await (symbol, result) in group {
                switch result {
                case .success(let quote): results[symbol] = quote
                case .failure(let error): firstError = firstError ?? error
                }
            }
        }

        // Keep the order of the list; a stock that failed is left out.
        let quotes = Self.companies.compactMap { results[$0.symbol] }
        if quotes.isEmpty, let firstError { throw firstError }
        return quotes
    }

    func history(symbol: String, days: Int) async throws -> [PricePoint] {
        []
    }

    private func quote(symbol: String, name: String) async throws -> StockQuote? {
        var components = URLComponents(string: "https://finnhub.io/api/v1/quote")!
        components.queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        let quote = try await client.decode(
            Quote.self,
            from: components.url!,
            headers: ["X-Finnhub-Token": apiKey]
        )
        // Finnhub answers 0 for a symbol it does not know.
        guard quote.c > 0 else { return nil }
        return StockQuote(
            symbol: symbol,
            name: name,
            exchange: "US",
            currencyCode: "USD",
            price: Self.decimal(quote.c),
            previousClose: Self.decimal(quote.pc)
        )
    }

    /// The API sends prices as JSON numbers; they are turned into `Decimal` with two decimal places.
    private static func decimal(_ value: Double) -> Decimal {
        Decimal(string: String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)) ?? 0
    }
}

/// Finnhub when the user has saved an API key, demo data otherwise.
@MainActor
final class SwitchingStockService: StockService {
    private let keyStore: StockAPIKeyStore
    private let demo: DemoStockService
    private let client: APIClient

    init(keyStore: StockAPIKeyStore, demo: DemoStockService = DemoStockService(), client: APIClient = APIClient()) {
        self.keyStore = keyStore
        self.demo = demo
        self.client = client
    }

    private var current: any StockService {
        if let key = keyStore.key() {
            return FinnhubStockService(apiKey: key, client: client)
        }
        return demo
    }

    var isDemo: Bool { !keyStore.hasKey }
    var hasHistory: Bool { current.hasHistory }

    func quotes() async throws -> [StockQuote] {
        try await current.quotes()
    }

    func history(symbol: String, days: Int) async throws -> [PricePoint] {
        try await current.history(symbol: symbol, days: days)
    }
}
