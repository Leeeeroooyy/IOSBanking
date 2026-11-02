import SwiftUI
import UIKit

/// One account: number (with copying), balance and its own transaction history.
struct AccountDetailView: View {
    let account: Account

    @State private var model: TransactionsViewModel
    @State private var showsCopied = false

    init(account: Account, banking: any BankingService) {
        self.account = account
        _model = State(initialValue: TransactionsViewModel(accountIDs: [account.id], banking: banking))
    }

    var body: some View {
        BrandScaffold {
            header
        } content: {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                SectionTitle(titleKey: "transactions.title")
                TransactionFilterPicker(filter: $model.filter)
                TransactionHistory(model: model)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            HStack {
                Text(account.kind.titleKey)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.onBrand)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("accountDetail.title")
                Spacer()
                DemoBadge()
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("account.balance")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.onBrandSecondary)
                AmountText(
                    amount: account.balance.amount,
                    currencyCode: account.currencyCode,
                    font: Theme.Typography.balance,
                    color: Theme.Colors.onBrand
                )
            }
            .accessibilityElement(children: .combine)

            numberRow
        }
    }

    private var copyTitleKey: LocalizedStringKey {
        showsCopied ? "account.copied" : "account.copy"
    }

    private var numberRow: some View {
        HStack(spacing: Theme.Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text("account.number")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.onBrandSecondary)
                Text(verbatim: account.number)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.Colors.onBrand)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = account.number
                showsCopied = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    showsCopied = false
                }
            } label: {
                Label(copyTitleKey, systemImage: showsCopied ? "checkmark" : "doc.on.doc")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.Colors.onBrand)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(minHeight: 44)
                .background(Theme.Colors.onBrand.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("accountDetail.copy")
        }
    }
}
