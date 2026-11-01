import SwiftUI

/// Displays a money amount formatted for the current app locale.
///
/// `.plain`  → "45 250,00 Kč" (balances)
/// `.signed` → "+38 500,00 Kč" in the positive color, or "−1 248,90 Kč" (transactions)
struct AmountText: View {
    enum Kind {
        case plain
        case signed
    }

    let amount: Decimal
    var currencyCode: String = "CZK"
    var kind: Kind = .plain
    var font: Font = Theme.Typography.amount

    @Environment(\.locale) private var locale

    var body: some View {
        Text(formatted)
            .font(font)
            .monospacedDigit()          // digits keep the same width, amounts do not "jump"
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)    // very large amounts shrink instead of being cut off
    }

    private var formatted: String {
        switch kind {
        case .plain:
            return MoneyFormatter.string(amount, currencyCode: currencyCode, locale: locale)
        case .signed:
            return MoneyFormatter.signedString(amount, currencyCode: currencyCode, locale: locale)
        }
    }

    private var color: Color {
        kind == .signed && amount > 0 ? Theme.Colors.positive : Theme.Colors.textPrimary
    }
}

#Preview {
    VStack(alignment: .trailing, spacing: Theme.Spacing.s) {
        AmountText(amount: 165_250, font: Theme.Typography.balance)
        AmountText(amount: 38_500, kind: .signed)
        AmountText(amount: Decimal(string: "-1248.90")!, kind: .signed)
    }
    .padding()
    .environment(\.locale, AppLanguage.czech.locale)
}
