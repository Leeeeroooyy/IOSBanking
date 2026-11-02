import SwiftUI

/// Empty state of a feature that arrives in a later stage. It has no buttons on purpose:
/// nothing in the app may pretend to work.
struct ComingSoonView: View {
    let titleKey: LocalizedStringKey
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(titleKey, systemImage: systemImage)
        } description: {
            Text("placeholder.message")
        }
    }
}

#Preview {
    ComingSoonView(titleKey: "placeholder.payments.title", systemImage: "arrow.left.arrow.right")
}
