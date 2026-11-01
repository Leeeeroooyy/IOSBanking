import SwiftUI

/// Screen 2: sign-up of a new demo user.
struct RegisterView: View {
    private enum Field {
        case fullName
        case email
        case password
        case confirmation
    }

    @State private var viewModel: RegisterViewModel
    @FocusState private var focus: Field?
    private let onSignIn: () -> Void

    @MainActor
    init(auth: any AuthService, session: SessionStore, onSignIn: @escaping () -> Void) {
        _viewModel = State(initialValue: RegisterViewModel(auth: auth, session: session))
        self.onSignIn = onSignIn
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        BrandScaffold {
            AuthHeader()
        } content: {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text("register.title")
                    .font(Theme.Typography.sectionTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("register.title")

                Text("register.demoNote")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)

                AppTextField(
                    titleKey: "auth.field.fullName",
                    text: $viewModel.fullName,
                    kind: .name,
                    error: viewModel.fullNameError?.messageKey,
                    identifier: "register.fullName"
                )
                .focused($focus, equals: .fullName)
                .submitLabel(.next)
                .onSubmit { focus = .email }

                AppTextField(
                    titleKey: "auth.field.email",
                    text: $viewModel.email,
                    kind: .email,
                    error: viewModel.emailError?.messageKey,
                    identifier: "register.email"
                )
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { focus = .password }

                AppTextField(
                    titleKey: "auth.field.password",
                    text: $viewModel.password,
                    kind: .newPassword,
                    error: viewModel.passwordError?.messageKey,
                    identifier: "register.password"
                )
                .focused($focus, equals: .password)
                .submitLabel(.next)
                .onSubmit { focus = .confirmation }

                AppTextField(
                    titleKey: "auth.field.passwordConfirmation",
                    text: $viewModel.passwordConfirmation,
                    kind: .newPassword,
                    error: viewModel.confirmationError?.messageKey,
                    identifier: "register.passwordConfirmation"
                )
                .focused($focus, equals: .confirmation)
                .submitLabel(.go)
                .onSubmit { submit() }

                if let error = viewModel.error {
                    Text(error.messageKey)
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.negative)
                        .accessibilityIdentifier("register.error")
                }

                Button("register.submit") {
                    submit()
                }
                .buttonStyle(.primary)
                .disabled(viewModel.isSubmitting)
                .accessibilityIdentifier("register.submit")

                Text("register.hasAccount")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)

                Button("login.submit", action: onSignIn)
                    .buttonStyle(.secondary)
                    .disabled(viewModel.isSubmitting)
                    .accessibilityIdentifier("register.signIn")
            }
        }
    }

    private func submit() {
        focus = nil
        Task { await viewModel.submit() }
    }
}

#Preview {
    let dependencies = AppDependencies.inMemory()
    return RegisterView(auth: dependencies.auth, session: dependencies.session) {}
}
