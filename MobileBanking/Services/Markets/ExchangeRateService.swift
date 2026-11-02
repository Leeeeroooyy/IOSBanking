import Foundation

/// One currency of the ČNB exchange rate list: `amount` units of `code` cost `rate` Kč.
struct ExchangeRate: Identifiable, Hashable {
    let country: String
    let currencyName: String
    let amount: Int
    let code: String
    let rate: Decimal

    var id: String { code }

    /// Price of one unit in Kč (e.g. 100 JPY = 15,4 Kč → 0,154 Kč).
    var ratePerUnit: Decimal { rate / Decimal(amount) }
}

/// The rate list valid for one day.
struct ExchangeRateList: Equatable {
    let date: Date
    let rates: [ExchangeRate]
}

@MainActor
protocol ExchangeRateService {
    func latestRates() async throws -> ExchangeRateList
}

/// Official daily exchange rates of the Czech National Bank. Free, no API key.
/// Published every working day around 14:30; the file is meant for machine processing.
/// https://www.cnb.cz/cs/casto-kladene-dotazy/Kurzy-devizoveho-trhu-na-www-strankach-CNB
@MainActor
final class CNBExchangeRateService: ExchangeRateService {
    static let url = URL(string: "https://www.cnb.cz/cs/financni-trhy/devizovy-trh/kurzy-devizoveho-trhu/kurzy-devizoveho-trhu/denni_kurz.txt")!

    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func latestRates() async throws -> ExchangeRateList {
        let data = try await client.data(from: Self.url)
        guard let text = String(data: data, encoding: .utf8), let list = Self.parse(text) else {
            throw NetworkError.invalidResponse
        }
        return list
    }

    /// Format:
    /// ```
    /// 30.10.2026 #210
    /// země|měna|množství|kód|kurz
    /// Austrálie|dolar|1|AUD|15,250
    /// ```
    nonisolated static func parse(_ text: String) -> ExchangeRateList? {
        let lines = text.split(whereSeparator: \.isNewline).map(String.init)
        guard lines.count > 2, let dateText = lines[0].split(separator: " ").first else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "cs_CZ")
        formatter.timeZone = TimeZone(identifier: "Europe/Prague")
        formatter.dateFormat = "dd.MM.yyyy"
        guard let date = formatter.date(from: String(dateText)) else { return nil }

        let rates = lines.dropFirst(2).compactMap { line -> ExchangeRate? in
            let fields = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard
                fields.count == 5,
                let amount = Int(fields[2]),
                let rate = Decimal(string: fields[4].replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX"))
            else { return nil }
            return ExchangeRate(country: fields[0], currencyName: fields[1], amount: amount, code: fields[3], rate: rate)
        }
        return rates.isEmpty ? nil : ExchangeRateList(date: date, rates: rates)
    }
}
