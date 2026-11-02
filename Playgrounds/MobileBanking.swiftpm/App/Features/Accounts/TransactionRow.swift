import SwiftUI

/// One transaction in a list: icon of the category, who, what and how much.
struct TransactionRow: View {
    let transaction: BankTransaction

    private var isIncoming: Bool { transaction.direction == .incoming }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: transaction.category.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isIncoming ? Theme.Colors.positive : Theme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    isIncoming ? Theme.Colors.positive.opacity(0.15) : Theme.Colors.surfaceRaised,
                    in: Circle()
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text(transaction.category.titleKey)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Theme.Spacing.s)

            AmountText(amount: transaction.signedAmount, currencyCode: transaction.currencyCode, kind: .signed)
        }
        .padding(.vertical, Theme.Spacing.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// A transfer between own accounts shows a localized title, not the user's own name.
    @ViewBuilder
    private var title: some View {
        if transaction.category == .transfer {
            Text(transaction.ownTransferTitleKey)
        } else {
            Text(verbatim: transaction.counterpartyName)
        }
    }
}

/// Section title of a list of transactions: "Dnes", "Včera" or the date.
struct TransactionDayHeader: View {
    let day: Date

    var body: some View {
        Group {
            if Calendar.current.isDateInToday(day) {
                Text("date.today")
            } else if Calendar.current.isDateInYesterday(day) {
                Text("date.yesterday")
            } else {
                Text(day, format: .dateTime.day().month(.wide).year())
            }
        }
        .font(.footnote.weight(.bold))
        .foregroundStyle(Theme.Colors.textSecondary)
        .textCase(.uppercase)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.m)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Transactions grouped by day. Each row opens its detail (`navigationDestination(for: BankTransaction.self)`).
struct TransactionDayList: View {
    let days: [TransactionDay]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(days) { day in
                TransactionDayHeader(day: day.day)
                ForEach(day.transactions) { transaction in
                    NavigationLink(value: transaction) {
                        TransactionRow(transaction: transaction)
                    }
                    .buttonStyle(.plain)
                    if transaction.id != day.transactions.last?.id {
                        Divider().overlay(Theme.Colors.border)
                    }
                }
            }
        }
    }
}
