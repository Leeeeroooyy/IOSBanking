import Foundation

/// The current quote of one stock.
struct StockQuote: Identifiable, Hashable {
    let symbol: String
    let name: String
    let exchange: String
    let currencyCode: String
    let price: Decimal
    /// Price at the previous close; change and percent are calculated from it.
    let previousClose: Decimal

    var id: String { symbol }
    var change: Decimal { price - previousClose }
    /// E.g. 0.0125 = +1,25 %.
    var changeRatio: Double {
        guard previousClose != 0 else { return 0 }
        return NSDecimalNumber(decimal: change / previousClose).doubleValue
    }
}

/// One point of the price chart. `Double` is fine here: the chart only draws, it never calculates money.
struct PricePoint: Identifiable, Hashable {
    let date: Date
    let close: Double
    var id: Date { date }
}

/// Source of stock quotes: `DemoStockService`, or `FinnhubStockService` when the user saved an API key.
/// The screens only see this protocol.
@MainActor
protocol StockService {
    /// `true` while the quotes are demo data; the screens then show the DEMO badge.
    var isDemo: Bool { get }
    /// `false` when the source offers no price history (the chart is then not shown).
    var hasHistory: Bool { get }
    func quotes() async throws -> [StockQuote]
    func history(symbol: String, days: Int) async throws -> [PricePoint]
}

/// Demo quotes of well-known companies. NOT real market prices:
/// the numbers are generated so the screens, the chart and the watchlist can be shown and tested.
/// They are stable for one day (the same seed for the same date), so the app does not "jump" on every refresh.
@MainActor
final class DemoStockService: StockService {
    let isDemo = true
    let hasHistory = true

    private struct Company {
        let symbol: String
        let name: String
        let exchange: String
        let currencyCode: String
        let basePrice: Double
    }

    private let companies: [Company] = [
        Company(symbol: "CEZ", name: "ČEZ", exchange: "BCPP", currencyCode: "CZK", basePrice: 1_050),
        Company(symbol: "KOMB", name: "Komerční banka", exchange: "BCPP", currencyCode: "CZK", basePrice: 880),
        Company(symbol: "MONET", name: "Moneta Money Bank", exchange: "BCPP", currencyCode: "CZK", basePrice: 145),
        Company(symbol: "ERBAG", name: "Erste Group Bank", exchange: "BCPP", currencyCode: "CZK", basePrice: 1_520),
        Company(symbol: "AAPL", name: "Apple", exchange: "NASDAQ", currencyCode: "USD", basePrice: 225),
        Company(symbol: "MSFT", name: "Microsoft", exchange: "NASDAQ", currencyCode: "USD", basePrice: 430),
        Company(symbol: "NVDA", name: "NVIDIA", exchange: "NASDAQ", currencyCode: "USD", basePrice: 135),
        Company(symbol: "AMZN", name: "Amazon", exchange: "NASDAQ", currencyCode: "USD", basePrice: 195),
        Company(symbol: "TSLA", name: "Tesla", exchange: "NASDAQ", currencyCode: "USD", basePrice: 250),
        Company(symbol: "SAP", name: "SAP", exchange: "XETRA", currencyCode: "EUR", basePrice: 215),
    ]

    private let calendar = Calendar(identifier: .gregorian)
    private let now: () -> Date

    init(now: @escaping () -> Date = { .now }) {
        self.now = now
    }

    func quotes() async throws -> [StockQuote] {
        companies.map { company in
            let series = closes(for: company, days: 2)
            return StockQuote(
                symbol: company.symbol,
                name: company.name,
                exchange: company.exchange,
                currencyCode: company.currencyCode,
                price: Self.decimal(series[1]),
                previousClose: Self.decimal(series[0])
            )
        }
    }

    func history(symbol: String, days: Int) async throws -> [PricePoint] {
        guard let company = companies.first(where: { $0.symbol == symbol }), days > 1 else { return [] }
        let today = calendar.startOfDay(for: now())
        return closes(for: company, days: days).enumerated().compactMap { index, close in
            calendar.date(byAdding: .day, value: index - (days - 1), to: today).map { PricePoint(date: $0, close: close) }
        }
    }

    /// Closing prices of the last `days` days, the last one is today.
    /// A random walk from a seed made of the symbol and the day, so it is the same on every call that day.
    private func closes(for company: Company, days: Int) -> [Double] {
        let today = calendar.startOfDay(for: now())
        let dayNumber = Int(today.timeIntervalSince1970 / 86_400)
        return (0..<days).map { index in
            let day = dayNumber - (days - 1 - index)
            // Slow trend + daily noise, both from the seed; ±15 % around the base price at most.
            let trend = sin(Double(day) / 23 + Double(company.symbol.unicodeScalars.reduce(0) { $0 + Int($1.value) }))
            var generator = SeededGenerator(seed: UInt64(truncatingIfNeeded: company.symbol.hashValueStable &+ day))
            let noise = Double.random(in: -1...1, using: &generator)
            return company.basePrice * (1 + 0.10 * trend + 0.02 * noise)
        }
    }

    private static func decimal(_ value: Double) -> Decimal {
        // Two decimal places, like real quotes.
        Decimal(string: String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)) ?? 0
    }
}

/// Small deterministic random generator (SplitMix64), so demo data is reproducible.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private extension String {
    /// `hashValue` changes on every app launch; this one does not.
    var hashValueStable: Int {
        unicodeScalars.reduce(5381) { ($0 &* 33) &+ Int($1.value) }
    }
}
