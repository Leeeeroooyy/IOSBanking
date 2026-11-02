import SwiftUI

/// Screen 1: sign-in of an existing demo user.
struct LoginView: View {
    private enum Field {
        case email
        case password
    }

    @State private var viewModel: LoginViewModel
    @FocusState private var focus: Field?
    /// Message under the test profiles (Face ID failed or not available).
    @State private var profileMessage: LocalizedStringKey?
    @Environment(\.locale) private var locale
    private let biometrics: any BiometricService
    private let onRegister: () -> Void

    @MainActor
    init(auth: any AuthService, session: SessionStore, biometrics: any BiometricService, onRegister: @escaping () -> Void) {
        _viewModel = State(initialValue: LoginViewModel(auth: auth, session: session))
        self.biometrics = biometrics
        self.onRegister = onRegister
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        BrandScaffold {
            AuthHeader()
        } content: {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("login.title")
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("login.title")

                AppTextField(titleKey: "auth.field.email", text: $viewModel.email, kind: .email, identifier: "login.email")
                    .focused($focus, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focus = .password }

                AppTextField(titleKey: "auth.field.password", text: $viewModel.password, kind: .password, identifier: "login.password")
                    .focused($focus, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { submit() }

                if let error = viewModel.error {
                    Text(error.messageKey)
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.negative)
                        .accessibilityIdentifier("login.error")
                }

                Button("login.submit") {
                    submit()
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canSubmit)
                .accessibilityIdentifier("login.submit")

                Text("login.noAccount")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)

                Button("register.submit", action: onRegister)
                    .buttonStyle(.secondary)
                    .disabled(viewModel.isSubmitting)
                    .accessibilityIdentifier("login.register")

                testProfiles
            }
        }
    }

    /// One-tap sign-in to the built-in test profiles, for trying payments between two users.
    private var testProfiles: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("login.testProfiles")
                .font(Theme.Typography.label)
                .foregroundStyle(Theme.Colors.textSecondary)
            ForEach(TestAccounts.profiles, id: \.email) { profile in
                Button {
                    Task { await signIn(as: profile) }
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: biometrics.isAvailable ? "faceid" : "person.crop.circle")
                            .font(.title3)
                            .foregroundStyle(Theme.Colors.primary)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: profile.fullName)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text(verbatim: profile.email)
                                .font(.footnote)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(Theme.Colors.primary)
                            .accessibilityHidden(true)
                    }
                    .padding(Theme.Spacing.m)
                    .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous).stroke(Theme.Colors.border))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSubmitting)
                .accessibilityHint(Text(biometrics.isAvailable ? "login.testProfiles.hint.faceID" : "login.testProfiles.hint.fill"))
            }
            if let profileMessage {
                Text(profileMessage)
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.negative)
                    .accessibilityIdentifier("login.testProfiles.message")
            }
            Text("login.testProfiles.password \(TestAccounts.password)")
                .font(.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.top, Theme.Spacing.m)
    }

    private func submit() {
        focus = nil
        Task { await viewModel.submit() }
    }

    /// A test profile signs in only after Face ID (or Touch ID) confirms the device owner.
    /// Without biometrics the sign-in details are only filled in, and the user confirms with "Přihlásit".
    private func signIn(as profile: TestAccounts.Profile) async {
        focus = nil
        profileMessage = nil
        viewModel.email = profile.email
        viewModel.password = TestAccounts.password

        guard biometrics.isAvailable else {
            profileMessage = "login.testProfiles.noBiometrics"
            return
        }
        do {
            try await biometrics.authenticate(
                reason: .localized("login.testProfiles.faceIDReason \(profile.fullName)", locale: locale)
            )
            await viewModel.submit()
        } catch let error as BiometricError {
            // Cancelled: the details stay filled in, nothing else happens.
            profileMessage = error.messageKey
        } catch {
            profileMessage = BiometricError.failed.messageKey
        }
    }
}

#Preview {
    let dependencies = AppDependencies.inMemory()
    return LoginView(auth: dependencies.auth, session: dependencies.session, biometrics: dependencies.biometrics) {}
}
