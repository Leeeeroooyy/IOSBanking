import SwiftUI

/// The last check before the money moves.
struct TransferConfirmView: View {
    @Bindable var model: TransferViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                if let request = model.request {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("transfer.confirm.amount")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        AmountText(
                            amount: request.amount.amount,
                            currencyCode: request.amount.currencyCode,
                            font: Theme.Typography.balance
                        )
                        .accessibilityIdentifier("transferConfirm.amount")
                    }
                    .frame(maxWidth: .infinity)

                    summary(request)
                }

                Label("transfer.confirm.demoNote", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: Theme.Spacing.m) {
                    Button {
                        model.confirm()
                    } label: {
                        if model.isProcessing {
                            ProgressView().tint(Theme.Colors.onAccent)
                        } else {
                            Text("transfer.confirm.send")
                        }
                    }
                    .buttonStyle(.primary)
                    // Blocks a second tap while the first one is being processed.
                    .disabled(model.isProcessing || model.request == nil)
                    .accessibilityIdentifier("transferConfirm.send")

                    Button("transfer.confirm.edit") {
                        model.isConfirmationPresented = false
                    }
                    .buttonStyle(.secondary)
                    .disabled(model.isProcessing)
                }
            }
            .padding(Theme.Spacing.xl)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("transfer.confirm.title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(model.isProcessing)
        .navigationDestination(isPresented: $model.isResultPresented) {
            TransferResultView(model: model)
        }
    }

    private func summary(_ request: TransferRequest) -> some View {
        VStack(spacing: 0) {
            if let source = model.sourceAccount {
                SummaryRow(titleKey: "transfer.field.from") {
                    Text(source.kind.titleKey) + Text(verbatim: " \(source.maskedNumber)")
                }
            }
            SummaryRow(titleKey: "transfer.field.recipientAccount") {
                Text(verbatim: request.recipientAccount.formatted).monospacedDigit()
            }
            if !request.recipientName.isEmpty {
                SummaryRow(titleKey: "transfer.field.recipientName") { Text(verbatim: request.recipientName) }
            }
            if let symbol = request.variableSymbol {
                SummaryRow(titleKey: "transfer.field.variableSymbol") { Text(verbatim: symbol) }
            }
            if let symbol = request.constantSymbol {
                SummaryRow(titleKey: "transfer.field.constantSymbol") { Text(verbatim: symbol) }
            }
            if let symbol = request.specificSymbol {
                SummaryRow(titleKey: "transfer.field.specificSymbol") { Text(verbatim: symbol) }
            }
            if let message = request.message {
                SummaryRow(titleKey: "transfer.field.message") { Text(verbatim: message) }
            }
            if let after = model.balanceAfterTransfer {
                SummaryRow(titleKey: "transfer.confirm.balanceAfter", isLast: true) {
                    AmountText(amount: after, currencyCode: request.amount.currencyCode, font: .subheadline.weight(.semibold))
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l, style: .continuous).stroke(Theme.Colors.border))
    }
}

/// "Label …… value" row of a summary card.
struct SummaryRow<Value: View>: View {
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
