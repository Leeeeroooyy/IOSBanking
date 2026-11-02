import SwiftUI

/// Everything before sign-in: the sign-in and sign-up screens.
struct AuthFlowView: View {
    private enum Screen {
        case login
        case register
    }

    @Environment(AppDependencies.self) private var dependencies
    @State private var screen: Screen = .login

    var body: some View {
        switch screen {
        case .login:
            LoginView(auth: dependencies.auth, session: dependencies.session) {
                screen = .register
            }
        case .register:
            RegisterView(auth: dependencies.auth, session: dependencies.session) {
                screen = .login
            }
        }
    }
}

#Preview {
    AuthFlowView()
        .environment(AppDependencies.inMemory())
}
