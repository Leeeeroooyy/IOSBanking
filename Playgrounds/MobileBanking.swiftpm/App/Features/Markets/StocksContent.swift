import SwiftUI

/// Stocks segment of the "Trhy" tab: the watchlist first, then all other stocks.
struct StocksContent: View {
    let model: StocksViewModel

    var body: some View {
        switch model.state {
        case .loading:
            ProgressView("common.loading")
                .frame(maxWidth: .infinity, minHeight: 200)
        case .failed(let error):
            ErrorStateView(message: error.messageKey) {
                Task { await model.load() }
            }
        case .loaded:
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                sectionTitle("stocks.watchlist")
                if model.watchedQuotes.isEmpty {
                    Text("stocks.watchlist.empty")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.m)
                        .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
                        .accessibilityIdentifier("stocks.watchlist.empty")
                } else {
                    ForEach(model.watchedQuotes) { quote in
                        row(quote)
                    }
                }

                if !model.otherQuotes.isEmpty {
                    sectionTitle("stocks.all")
                        .padding(.top, Theme.Spacing.l)
                    ForEach(model.otherQuotes) { quote in
                        row(quote)
                    }
                }

                Text(model.isDemo ? LocalizedStringKey("stocks.demoNote.list") : LocalizedStringKey("stocks.source.finnhub"))
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.top, Theme.Spacing.m)
            }
            .alert("stocks.watchlist.error", isPresented: Binding(
                get: { model.watchlistFailed },
                set: { if !$0 { model.dismissWatchlistError() } }
            )) {
                Button("common.ok", role: .cancel) {}
            }
        }
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(Theme.Typography.sectionTitle)
            .foregroundStyle(Theme.Colors.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private func row(_ quote: StockQuote) -> some View {
        NavigationLink(value: quote) {
            StockRow(quote: quote, isWatched: model.isWatched(quote.symbol))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("stocks.row.\(quote.symbol)")
    }
}

/// One stock: ticker, name, price and today's change.
struct StockRow: View {
    let quote: StockQuote
    var isWatched = false

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(verbatim: quote.symbol)
                .font(.caption2.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Theme.Colors.onBrand)
                .frame(width: 48, height: 44)
                .background(BrandGradient(decorated: false).clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(verbatim: quote.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)
                    if isWatched {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.accent)
                            .accessibilityLabel(Text("stocks.watched"))
                    }
                }
                Text(verbatim: "\(quote.symbol) · \(quote.exchange)")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer(minLength: Theme.Spacing.s)

            VStack(alignment: .trailing, spacing: 2) {
                AmountText(amount: quote.price, currencyCode: quote.currencyCode)
                StockChangeText(ratio: quote.changeRatio)
            }
        }
        .padding(Theme.Spacing.m)
        .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous).stroke(Theme.Colors.border))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// "+1,25 %" in green or "−0,80 %" in red, with an arrow so color is not the only signal.
struct StockChangeText: View {
    let ratio: Double
    var font: Font = .footnote.weight(.bold)

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: ratio >= 0 ? "arrow.up.right" : "arrow.down.right")
                .accessibilityHidden(true)
            Text(ratio, format: .percent.precision(.fractionLength(2)).sign(strategy: .always()))
        }
        .font(font)
        .monospacedDigit()
        .foregroundStyle(ratio >= 0 ? Theme.Colors.positive : Theme.Colors.negative)
    }
}

/// A round arrow in green or red, next to the price on the stock detail.
struct StockChangeIcon: View {
    let ratio: Double

    var body: some View {
        let rising = ratio >= 0
        Image(systemName: rising ? "arrow.up.right" : "arrow.down.right")
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(rising ? Theme.Colors.positive : Theme.Colors.negative, in: Circle())
            .accessibilityHidden(true)
    }
}
