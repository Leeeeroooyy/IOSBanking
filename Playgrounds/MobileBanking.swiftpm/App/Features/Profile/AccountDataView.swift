import SwiftUI
import UIKit

/// "Moje údaje": personal data of the signed-in user and all their accounts
/// with the full account number, IBAN and balance.
struct AccountDataView: View {
    let user: User
    let banking: any BankingService

    @State private var accounts: [Account] = []
    @State private var loadFailed = false
    @State private var copiedValue: String?

    var body: some View {
        List {
            Section("accountData.personal") {
                LabeledContent("auth.field.fullName") { Text(verbatim: user.fullName) }
                LabeledContent("auth.field.email") { Text(verbatim: user.email) }
                LabeledContent("accountData.memberSince") {
                    Text(user.createdAt, format: .dateTime.day().month(.wide).year())
                }
                LabeledContent("accountData.clientNumber") {
                    // A short, readable form of the internal ID.
                    Text(verbatim: String(user.id.uuidString.prefix(8)))
                        .monospaced()
                }
            }

            if loadFailed {
                Section {
                    ErrorStateView { load() }
                }
            } else {
                ForEach(accounts, id: \.id) { account in
                    Section {
                        LabeledContent("account.balance") {
                            AmountText(amount: account.balance.amount, currencyCode: account.currencyCode)
                        }
                        copyRow(titleKey: "account.number", value: account.number)
                        if let iban = CzechAccountNumber(account.number)?.iban {
                            copyRow(titleKey: "accountData.iban", value: iban)
                        }
                        LabeledContent("accountData.holder") { Text(verbatim: account.holderName) }
                        LabeledContent("accountData.currency") { Text(verbatim: account.currencyCode) }
                        LabeledContent("accountData.opened") {
                            Text(account.createdAt, format: .dateTime.day().month().year())
                        }
                    } header: {
                        Text(account.kind.titleKey)
                    }
                }
            }

            Section {
                Text("accountData.demoNote")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .navigationTitle("profile.data")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    /// A value with a copy button; shows a check mark for a moment after copying.
    private func copyRow(titleKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(verbatim: value)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .textSelection(.enabled)
            }
            Spacer()
            Button {
                UIPasteboard.general.string = value.replacingOccurrences(of: " ", with: "")
                copiedValue = value
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    if copiedValue == value { copiedValue = nil }
                }
            } label: {
                Image(systemName: copiedValue == value ? "checkmark" : "doc.on.doc")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("account.copy"))
        }
    }

    private func load() {
        do {
            accounts = try banking.accounts(ownerID: user.id)
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}
