import Foundation
import Observation
import SwiftUI

/// States of a screen that loads data from the internet.
enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed(NetworkError)
}

extension NetworkError {
    /// What the error screen says.
    var messageKey: LocalizedStringKey {
        switch self {
        case .offline: return "error.offline.message"
        case .timeout: return "error.timeout.message"
        case .server, .invalidResponse: return "error.server.message"
        }
    }
}

/// Tab "Trhy": live exchange rates of the Czech National Bank and a currency calculator.
@MainActor
@Observable
final class MarketsViewModel {
    /// Shown first: the currencies Czech clients use most.
    static let mainCurrencies = ["EUR", "USD", "GBP", "CHF", "PLN"]

    private(set) var state: LoadState<ExchangeRateList> = .loading
    var searchText = ""

    // Calculator: `amountText` units of `calculatorCode` → Kč.
    var calculatorCode = "EUR"
    var amountText = "100"

    @ObservationIgnored private let service: any ExchangeRateService

    init(service: any ExchangeRateService) {
        self.service = service
    }

    func load() async {
        do {
            state = .loaded(try await service.latestRates())
        } catch let error as NetworkError {
            state = .failed(error)
        } catch {
            state = .failed(.invalidResponse)
        }
    }

    /// Loads only the first time; pull-to-refresh calls `load()` directly.
    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    var list: ExchangeRateList? {
        if case .loaded(let list) = state { return list }
        return nil
    }

    var mainRates: [ExchangeRate] {
        guard let list, searchText.isEmpty else { return [] }
        return Self.mainCurrencies.compactMap { code in list.rates.first { $0.code == code } }
    }

    /// Everything else, or every match of the search (code, country or currency name).
    var otherRates: [ExchangeRate] {
        guard let list else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty {
            return list.rates.filter { !Self.mainCurrencies.contains($0.code) }
        }
        return list.rates.filter {
            $0.code.localizedCaseInsensitiveContains(query)
                || $0.country.localizedCaseInsensitiveContains(query)
                || $0.currencyName.localizedCaseInsensitiveContains(query)
        }
    }

    /// The calculator result in Kč, or nil when the amount is not a number.
    var convertedAmount: Decimal? {
        guard
            let rate = list?.rates.first(where: { $0.code == calculatorCode }),
            let amount = TransferRules.parseAmount(amountText)
        else { return nil }
        return amount * rate.ratePerUnit
    }
}
