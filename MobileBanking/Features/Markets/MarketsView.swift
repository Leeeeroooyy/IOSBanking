import SwiftUI

/// Tab "Trhy": official ČNB exchange rates (live data from the internet) with a calculator,
/// and stocks with the user's watchlist.
struct MarketsView: View {
    enum Segment: Hashable {
        case rates
        case stocks
    }

    @State private var model: MarketsViewModel
    @State private var stocks: StocksViewModel
    @State private var segment: Segment = .rates
    @FocusState private var amountFocused: Bool

    init(user: User, exchangeRates: any ExchangeRateService, stocks: any StockService, watchlist: any WatchlistService) {
        _model = State(initialValue: MarketsViewModel(service: exchangeRates))
        _stocks = State(initialValue: StocksViewModel(user: user, service: stocks, watchlistService: watchlist))
    }

    var body: some View {
        BrandScaffold {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(segment == .rates ? LocalizedStringKey("markets.title") : LocalizedStringKey("stocks.title"))
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.onBrand)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("markets.title")
                    subtitle
                        .font(.subheadline)
                        .foregroundStyle(Theme.Colors.onBrandSecondary)
                }
                Spacer()
                if segment == .stocks && stocks.isDemo {
                    DemoBadge()
                }
            }
        } content: {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Picker("markets.segment", selection: $segment) {
                    Text("markets.segment.rates").tag(Segment.rates)
                    Text("markets.segment.stocks").tag(Segment.stocks)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("markets.segment")

                switch segment {
                case .rates:
                    content
                case .stocks:
                    StocksContent(model: stocks)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            switch segment {
            case .rates: await model.load()
            case .stocks: await stocks.load()
            }
        }
        .task { await model.loadIfNeeded() }
        .task(id: segment) {
            if segment == .stocks { await stocks.loadIfNeeded() }
        }
        .navigationDestination(for: StockQuote.self) { quote in
            StockDetailView(quote: quote, model: stocks)
        }
    }

    @ViewBuilder
    private var subtitle: some View {
        if segment == .stocks {
            Text("stocks.subtitle")
        } else if let list = model.list {
            Text("markets.validFor \(list.date, format: .dateTime.day().month(.wide).year())")
        } else {
            Text("markets.subtitle")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView("common.loading")
                .frame(maxWidth: .infinity, minHeight: 200)
        case .failed(let error):
            ErrorStateView(message: error.messageKey) {
                Task { await model.load() }
            }
        case .loaded:
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                calculator
                rateSections
                Text("markets.source")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("transfer.keyboard.done") { amountFocused = false }
                }
            }
        }
    }

    // MARK: - Calculator

    private var calculator: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("markets.calculator")
                .font(Theme.Typography.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack(alignment: .bottom, spacing: Theme.Spacing.m) {
                AppTextField(
                    titleKey: "markets.calculator.amount",
                    text: $model.amountText,
                    kind: .amount,
                    identifier: "markets.amount"
                )
                .focused($amountFocused)

                Picker("markets.calculator.currency", selection: $model.calculatorCode) {
                    ForEach(model.list?.rates ?? [], id: \.code) { rate in
                        Text(verbatim: rate.code).tag(rate.code)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Colors.primary)
                .frame(minHeight: 48)
                .padding(.horizontal, Theme.Spacing.s)
                .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous).stroke(Theme.Colors.border))
            }

            HStack {
                Text("markets.calculator.result")
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                if let result = model.convertedAmount {
                    AmountText(amount: result, font: Theme.Typography.sectionTitle)
                        .accessibilityIdentifier("markets.result")
                } else {
                    Text(verbatim: "—").foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(Theme.Spacing.m)
            .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Rates

    @ViewBuilder
    private var rateSections: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("markets.rates")
                .font(Theme.Typography.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.Colors.textSecondary)
                TextField("markets.search", text: $model.searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("markets.search")
            }
            .padding(.horizontal, Theme.Spacing.m)
            .frame(minHeight: 44)
            .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))

            ForEach(model.mainRates) { rate in
                rateRow(rate)
            }
            if !model.mainRates.isEmpty && !model.otherRates.isEmpty {
                Text("markets.otherCurrencies")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .padding(.top, Theme.Spacing.m)
            }
            ForEach(model.otherRates) { rate in
                rateRow(rate)
            }
            if model.mainRates.isEmpty && model.otherRates.isEmpty {
                Text("markets.noResults")
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            }
        }
    }

    private func rateRow(_ rate: ExchangeRate) -> some View {
        Button {
            model.calculatorCode = rate.code
        } label: {
            HStack(spacing: Theme.Spacing.m) {
                Text(verbatim: rate.code)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Theme.Colors.onBrand)
                    .frame(width: 44, height: 44)
                    .background(BrandGradient().clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: rate.country)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(verbatim: "\(rate.amount) \(rate.code) · \(rate.currencyName)")
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                Spacer(minLength: Theme.Spacing.s)
                Text(rate.rate, format: .number.precision(.fractionLength(3)))
                    .font(Theme.Typography.amount)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textPrimary)
                + Text(verbatim: " Kč")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.m)
            .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .stroke(model.calculatorCode == rate.code ? Theme.Colors.primary : Theme.Colors.border,
                            lineWidth: model.calculatorCode == rate.code ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("markets.row.hint"))
        .accessibilityIdentifier("markets.rate.\(rate.code)")
    }
}
