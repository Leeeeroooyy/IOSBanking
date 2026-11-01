import SwiftUI

/// Screen 3: unlocks a saved session with Face ID when the user turned it on in Settings.
struct LockView: View {
    @State private var viewModel: LockViewModel
    @Environment(\.locale) private var locale

    @MainActor
    init(biometrics: any BiometricService, session: SessionStore) {
        _viewModel = State(initialValue: LockViewModel(biometrics: biometrics, session: session))
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            HStack {
                Text("app.name")
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.onBrand)
                Spacer()
                DemoBadge()
            }

            Spacer()

            Image(systemName: "faceid")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Colors.onBrand)
                .accessibilityHidden(true)

            Text("lock.title")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.onBrand)
                .multilineTextAlignment(.center)

            if let message = viewModel.error?.messageKey {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.onBrandSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("lock.unlock") {
                Task { await unlock() }
            }
            .buttonStyle(.primary)
            .disabled(viewModel.isAuthenticating)

            Button("lock.usePassword") {
                viewModel.usePassword()
            }
            .buttonStyle(.secondary)
        }
        .padding(Theme.Spacing.xl)
        .background(BrandGradient().ignoresSafeArea())
        .task { await unlock() }
    }

    private func unlock() async {
        await viewModel.unlock(reason: .localized("lock.reason", locale: locale))
    }
}

#Preview {
    let dependencies = AppDependencies.inMemory()
    return LockView(biometrics: dependencies.biometrics, session: dependencies.session)
}
