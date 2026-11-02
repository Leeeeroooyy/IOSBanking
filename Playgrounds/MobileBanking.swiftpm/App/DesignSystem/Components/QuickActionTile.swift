import SwiftUI

/// A quick action on the brand header (the 2×2 grid of design variant C).
/// The primary tile uses the accent color, the others are translucent.
struct QuickActionTile: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: systemImage)
                    .font(.body.weight(.bold))
                    .foregroundStyle(isPrimary ? Theme.Colors.onAccent : Theme.Colors.onBrandSecondary)
                    .accessibilityHidden(true)
                Text(titleKey)
                    .font(.subheadline.weight(.heavy))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isPrimary ? Theme.Colors.onAccent : Theme.Colors.onBrand)
            .padding(.horizontal, Theme.Spacing.m)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                isPrimary ? Theme.Colors.accent : Theme.Colors.onBrand.opacity(0.14),
                in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    Grid(horizontalSpacing: 12, verticalSpacing: 12) {
        GridRow {
            QuickActionTile(titleKey: "dashboard.action.send", systemImage: "arrow.up.right", isPrimary: true) {}
            QuickActionTile(titleKey: "dashboard.action.transactions", systemImage: "list.bullet") {}
        }
    }
    .padding()
    .background(BrandGradient())
}
