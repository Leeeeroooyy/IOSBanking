import SwiftUI

/// Tab "Trhy": stocks with the user's watchlist.
/// Quotes are demo data until a real provider (with an API key) is connected.
struct MarketsView: View {
    @State private var stocks: StocksViewModel

    init(user: User, stocks: any StockService, watchlist: any WatchlistService) {
        _stocks = State(initialValue: StocksViewModel(user: user, service: stocks, watchlistService: watchlist))
    }

    var body: some View {
        BrandScaffold {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("stocks.title")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.onBrand)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("markets.title")
                    Text(stocks.isDemo ? LocalizedStringKey("stocks.subtitle") : LocalizedStringKey("stocks.subtitle.live"))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.onBrandSecondary)
                }
                Spacer()
                HeaderIcon(systemImage: "chart.line.uptrend.xyaxis")
            }
        } content: {
            StocksContent(model: stocks)
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await stocks.load() }
        .task { await stocks.loadIfNeeded() }
        .navigationDestination(for: StockQuote.self) { quote in
            StockDetailView(quote: quote, model: stocks)
        }
    }
}
