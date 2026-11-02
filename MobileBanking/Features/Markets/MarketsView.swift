import SwiftUI

/// Tab "Trhy": official ČNB exchange rates (live data from the internet) and a calculator.
struct MarketsView: View {
    @State private var model: MarketsViewModel
    @FocusState private var amountFocused: Bool

    init(service: any ExchangeRateService) {
        _model = State(initialValue: MarketsViewModel(service: service))
    }

    var body: some View {
        BrandScaffold {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("markets.title")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.onBrand)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("markets.title")
                Group {
                    if let list = model.list {
                        Text("markets.validFor \(list.date, format: .dateTime.day().month(.wide).year())")
                    } else {
                        Text("markets.subtitle")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.onBrandSecondary)
            }
        } content: {
            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await model.load() }
        .task { await model.loadIfNeeded() }
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
