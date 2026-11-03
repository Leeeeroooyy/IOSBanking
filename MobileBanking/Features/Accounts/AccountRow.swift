import SwiftUI

/// One account in a list: type, the last digits of its number and the balance.
struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: account.kind.systemImage)
                .font(.body.weight(.bold))
                .foregroundStyle(Theme.Colors.onBrand)
                .frame(width: 40, height: 40)
                .background(BrandGradient(decorated: false).clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.kind.titleKey)
                    .font(.body.weight(.bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(verbatim: account.maskedNumber)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer(minLength: Theme.Spacing.s)

            AmountText(amount: account.balance.amount, currencyCode: account.currencyCode)
        }
        .padding(Theme.Spacing.m)
        .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous).stroke(Theme.Colors.border))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("account.\(account.kind.rawValue)")
    }
}
