import SwiftUI

/// Everything about one transaction.
struct TransactionDetailView: View {
    let transaction: BankTransaction

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                summary
                details
                Label("transaction.detail.demoNote", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("transaction.detail.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summary: some View {
        VStack(spacing: Theme.Spacing.s) {
            Image(systemName: transaction.category.systemImage)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.Colors.onBrand)
                .frame(width: 64, height: 64)
                .background(BrandGradient(), in: Circle())
                .accessibilityHidden(true)

            Group {
                if transaction.category == .transfer {
                    Text(transaction.ownTransferTitleKey)
                } else {
                    Text(verbatim: transaction.counterpartyName)
                }
            }
            .font(Theme.Typography.sectionTitle)
            .foregroundStyle(Theme.Colors.textPrimary)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier("transactionDetail.counterparty")

            AmountText(
                amount: transaction.signedAmount,
                currencyCode: transaction.currencyCode,
                kind: .signed,
                font: Theme.Typography.balance
            )
            .accessibilityIdentifier("transactionDetail.amount")

            Text(transaction.status.titleKey)
                .font(.footnote.weight(.bold))
                .foregroundStyle(transaction.status == .completed ? Theme.Colors.positive : Theme.Colors.negative)
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.surfaceRaised, in: Capsule())
        }
        .frame(maxWidth: .infinity)
    }

    private var details: some View {
        VStack(spacing: 0) {
            DetailRow(titleKey: "transaction.detail.date") {
                Text(transaction.date, format: .dateTime.day().month(.wide).year().hour().minute())
            }
            DetailRow(titleKey: "transaction.detail.direction") {
                Text(transaction.direction.titleKey)
            }
            DetailRow(titleKey: "transaction.detail.category") {
                Text(transaction.category.titleKey)
            }
            if let account = transaction.counterpartyAccount {
                DetailRow(titleKey: "transaction.detail.counterpartyAccount") {
                    Text(verbatim: account).monospacedDigit()
                }
            }
            if let symbol = transaction.variableSymbol {
                DetailRow(titleKey: "transaction.detail.variableSymbol") { Text(verbatim: symbol) }
            }
            if let symbol = transaction.constantSymbol {
                DetailRow(titleKey: "transaction.detail.constantSymbol") { Text(verbatim: symbol) }
            }
            if let symbol = transaction.specificSymbol {
                DetailRow(titleKey: "transaction.detail.specificSymbol") { Text(verbatim: symbol) }
            }
            if let message = transaction.message {
                DetailRow(titleKey: "transaction.detail.message", isLast: true) { Text(verbatim: message) }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous).stroke(Theme.Colors.border))
    }
}

/// "Label …… value" row of the detail card.
private struct DetailRow<Value: View>: View {
    let titleKey: LocalizedStringKey
    var isLast = false
    @ViewBuilder let value: Value

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Text(titleKey)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer(minLength: Theme.Spacing.m)
                value
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.trailing)
            }
            .font(.subheadline)
            .padding(.vertical, Theme.Spacing.m)
            .accessibilityElement(children: .combine)

            if !isLast {
                Divider().overlay(Theme.Colors.border)
            }
        }
    }
}
