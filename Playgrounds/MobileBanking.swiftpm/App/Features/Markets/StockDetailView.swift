import Charts
import SwiftUI

/// One stock: price, change, a chart (Swift Charts) and adding to / removing from the watchlist.
struct StockDetailView: View {
    enum Period: Int, CaseIterable, Identifiable {
        case week = 7
        case month = 30
        case quarter = 90

        var id: Int { rawValue }

        var titleKey: LocalizedStringKey {
            switch self {
            case .week: return "stocks.period.week"
            case .month: return "stocks.period.month"
            case .quarter: return "stocks.period.quarter"
            }
        }
    }

    let quote: StockQuote
    let model: StocksViewModel

    @State private var period: Period = .month
    @State private var history: LoadState<[PricePoint]> = .loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                header

                if model.hasHistory {
                    Picker("stocks.period", selection: $period) {
                        ForEach(Period.allCases) { period in
                            Text(period.titleKey).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    chart
                        .frame(height: 220)
                } else {
                    // The free Finnhub plan has no price history: say so instead of drawing invented data.
                    Label("stocks.chart.unavailable", systemImage: "chart.xyaxis.line")
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.m)
                        .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
                }

                details

                watchButton

                Text(model.isDemo ? LocalizedStringKey("stocks.demoNote") : LocalizedStringKey("stocks.source.finnhub"))
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationTitle(Text(verbatim: quote.symbol))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: period) { await loadHistory() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(verbatim: quote.name)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("stocks.detail.name")
                Spacer()
                if model.isDemo { DemoBadge() }
            }
            Text(verbatim: "\(quote.symbol) · \(quote.exchange)")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                AmountText(amount: quote.price, currencyCode: quote.currencyCode, font: Theme.Typography.balance)
                StockChangeText(ratio: quote.changeRatio, font: .headline)
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    @ViewBuilder
    private var chart: some View {
        switch history {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ErrorStateView(message: error.messageKey) {
                Task { await loadHistory() }
            }
        case .loaded(let points) where points.isEmpty:
            ContentUnavailableView("stocks.chart.empty", systemImage: "chart.xyaxis.line")
        case .loaded(let points):
            let closes = points.map(\.close)
            let low = closes.min() ?? 0
            let high = closes.max() ?? 0
            let padding = max((high - low) * 0.1, 0.01)
            let rising = (points.last?.close ?? 0) >= (points.first?.close ?? 0)
            let color = rising ? Theme.Colors.positive : Theme.Colors.negative

            Chart(points) { point in
                AreaMark(
                    x: .value("stocks.chart.date", point.date),
                    yStart: .value("stocks.chart.price", low - padding),
                    yEnd: .value("stocks.chart.price", point.close)
                )
                .foregroundStyle(.linearGradient(colors: [color.opacity(0.25), color.opacity(0)], startPoint: .top, endPoint: .bottom))
                LineMark(
                    x: .value("stocks.chart.date", point.date),
                    y: .value("stocks.chart.price", point.close)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartYScale(domain: (low - padding)...(high + padding))
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .accessibilityLabel(Text("stocks.chart.accessibility"))
        }
    }

    private var details: some View {
        VStack(spacing: 0) {
            detailRow("stocks.detail.price") {
                AmountText(amount: quote.price, currencyCode: quote.currencyCode)
            }
            Divider()
            detailRow("stocks.detail.previousClose") {
                AmountText(amount: quote.previousClose, currencyCode: quote.currencyCode)
            }
            Divider()
            detailRow("stocks.detail.change") {
                AmountText(amount: quote.change, currencyCode: quote.currencyCode, kind: .signed)
            }
            Divider()
            detailRow("stocks.detail.currency") {
                Text(verbatim: quote.currencyCode).foregroundStyle(Theme.Colors.textPrimary)
            }
        }
        .padding(.horizontal, Theme.Spacing.m)
        .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
    }

    private func detailRow<Value: View>(_ key: LocalizedStringKey, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(key).foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
            value()
        }
        .padding(.vertical, Theme.Spacing.m)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var watchButton: some View {
        if model.isWatched(quote.symbol) {
            Button {
                model.toggleWatch(quote.symbol)
            } label: {
                Label("stocks.watch.remove", systemImage: "star.slash")
            }
            .buttonStyle(.secondary)
            .accessibilityIdentifier("stocks.watch")
        } else {
            Button {
                model.toggleWatch(quote.symbol)
            } label: {
                Label("stocks.watch.add", systemImage: "star")
            }
            .buttonStyle(.primary)
            .accessibilityIdentifier("stocks.watch")
        }
    }

    private func loadHistory() async {
        guard model.hasHistory else { return }
        history = .loading
        do {
            history = .loaded(try await model.service.history(symbol: quote.symbol, days: period.rawValue))
        } catch {
            history = .failed(error as? NetworkError ?? .invalidResponse)
        }
    }
}
