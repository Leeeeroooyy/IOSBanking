import SwiftUI

/// Settings section for the Finnhub API key. The key is typed by the user and stored in the Keychain,
/// so it never appears in the source code, in git or in logs.
struct StockAPIKeySection: View {
    let keyStore: StockAPIKeyStore

    @State private var keyText = ""
    @State private var saveFailed = false

    var body: some View {
        Section {
            if keyStore.hasKey {
                Label("settings.stocks.saved", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.Colors.positive)
                Button("settings.stocks.remove", role: .destructive) {
                    do {
                        try keyStore.remove()
                    } catch {
                        saveFailed = true
                    }
                }
                .accessibilityIdentifier("settings.stocks.remove")
            } else {
                SecureField("settings.stocks.key", text: $keyText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.password)
                    .accessibilityIdentifier("settings.stocks.key")
                Button("settings.stocks.save") {
                    do {
                        try keyStore.save(keyText)
                        keyText = ""
                    } catch {
                        saveFailed = true
                    }
                }
                .disabled(keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("settings.stocks.save")
            }
        } header: {
            Text("settings.stocks")
        } footer: {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(saveFailed ? LocalizedStringKey("settings.stocks.error") : LocalizedStringKey("settings.stocks.hint"))
                Link("settings.stocks.register", destination: URL(string: "https://finnhub.io/register")!)
            }
        }
    }
}
