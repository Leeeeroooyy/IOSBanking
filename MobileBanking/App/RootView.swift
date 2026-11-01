import SwiftUI

/// Decides which part of the app is visible: sign-in, the Face ID lock screen or the main tab bar.
struct RootView: View {
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        switch dependencies.session.state {
        case .signedOut:
            AuthFlowView()
        case .locked:
            LockView(biometrics: dependencies.biometrics, session: dependencies.session)
        case .signedIn(let user):
            MainTabView(user: user)
        }
    }
}

#Preview {
    RootView()
        .environment(AppDependencies.inMemory())
}
