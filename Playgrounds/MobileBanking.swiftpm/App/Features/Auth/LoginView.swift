import SwiftUI

/// Screen 1: sign-in of an existing demo user.
struct LoginView: View {
    private enum Field {
        case email
        case password
    }

    @State private var viewModel: LoginViewModel
    @FocusState private var focus: Field?
    private let onRegister: () -> Void

    @MainActor
    init(auth: any AuthService, session: SessionStore, onRegister: @escaping () -> Void) {
        _viewModel = State(initialValue: LoginViewModel(auth: auth, session: session))
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
                    viewModel.email = profile.email
                    viewModel.password = TestAccounts.password
                    submit()
                } label: {
                    HStack(spacing: Theme.Spacing.m) {
                        Image(systemName: "person.crop.circle")
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
}

#Preview {
    let dependencies = AppDependencies.inMemory()
    return LoginView(auth: dependencies.auth, session: dependencies.session) {}
}
