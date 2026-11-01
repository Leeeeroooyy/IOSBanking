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
    return LoginView(auth: dependencies.auth, session: dependencies.session) {}
}
