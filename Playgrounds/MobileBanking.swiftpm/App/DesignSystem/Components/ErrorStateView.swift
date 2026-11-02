import SwiftUI

/// Error state with a retry button, shown when loading data fails.
/// Built on Apple's `ContentUnavailableView` (iOS 17), which is also used
/// directly for empty states such as "no transactions yet".
struct ErrorStateView: View {
    var message: LocalizedStringKey = "error.generic.message"
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("error.generic.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("common.retry", action: retry)
                .buttonStyle(.secondary)
                .frame(maxWidth: 220)
        }
    }
}

#Preview {
    ErrorStateView {}
}
