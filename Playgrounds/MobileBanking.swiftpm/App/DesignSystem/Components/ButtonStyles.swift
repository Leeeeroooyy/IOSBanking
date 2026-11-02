import SwiftUI

/// Main call to action, e.g. "Pokračovat" or "Potvrdit platbu".
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(Theme.Colors.onAccent)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Theme.Spacing.l)
            .background(Theme.Colors.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary action, e.g. "Upravit" or "Zkusit znovu".
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, Theme.Spacing.l)
            .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous)
                    .stroke(Theme.Colors.border)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// Usage: `Button("…") { … }.buttonStyle(.primary)`
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

#Preview {
    VStack(spacing: Theme.Spacing.m) {
        Button("common.retry") {}.buttonStyle(.primary)
        Button("common.retry") {}.buttonStyle(.secondary)
        Button("common.retry") {}.buttonStyle(.primary).disabled(true)
    }
    .padding()
    .background(Theme.Colors.surface)
}
