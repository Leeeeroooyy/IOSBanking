import SwiftUI

/// Success or failure of the payment.
struct TransferResultView: View {
    @Bindable var model: TransferViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            switch model.outcome {
            case .success(let receipt):
                success(receipt)
            case .failure(let error):
                failure(error)
            case nil:
                ProgressView()
            }
            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func success(_ receipt: TransferReceipt) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.Colors.positive)
                .accessibilityHidden(true)

            Text("transfer.result.success")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityIdentifier("transferResult.title")

            AmountText(
                amount: receipt.transaction.amount.amount,
                currencyCode: receipt.transaction.currencyCode,
                font: Theme.Typography.balance
            )

            VStack(spacing: Theme.Spacing.xs) {
                Text("transfer.result.newBalance")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
                AmountText(amount: receipt.newBalance.amount, currencyCode: receipt.newBalance.currencyCode)
            }

            Text(noteKey(isExternal: receipt.isExternal))
                .font(.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button("transfer.result.done") { model.startNewPayment() }
                .buttonStyle(.primary)
                .accessibilityIdentifier("transferResult.done")
        }
    }

    private func noteKey(isExternal: Bool) -> LocalizedStringKey {
        isExternal ? "transfer.result.external" : "transfer.result.internal"
    }

    private func failure(_ error: TransferError) -> some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.Colors.negative)
                .accessibilityHidden(true)

            Text("transfer.result.failure")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityIdentifier("transferResult.title")

            Text(error.messageKey)
                .font(.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button("transfer.result.edit") { model.editPayment() }
                .buttonStyle(.primary)
        }
    }
}
