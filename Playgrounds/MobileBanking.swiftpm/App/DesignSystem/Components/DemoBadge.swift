import SwiftUI

/// Marks demo content (accounts, quotes, news) so nobody mistakes it for real data.
struct DemoBadge: View {
    var body: some View {
        Text("demo.badge")
            .font(.caption2.weight(.heavy))
            .tracking(0.6)
            .foregroundStyle(Theme.Colors.onAccent)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(Text("demo.badge.accessibility"))
    }
}

#Preview {
    DemoBadge().padding()
}
