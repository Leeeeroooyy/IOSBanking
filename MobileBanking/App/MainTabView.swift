import SwiftUI

/// The signed-in part of the app. Each tab has its own `NavigationStack`,
/// so switching tabs keeps the place inside each of them.
struct MainTabView: View {
    private enum Tab {
        case dashboard
        case payments
        case markets
        case news
        case profile
    }

    let user: User

    @State private var selection: Tab = .dashboard

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                DashboardView(user: user)
            }
            .tabItem { Label("tab.dashboard", systemImage: "house") }
            .tag(Tab.dashboard)

            NavigationStack {
                ComingSoonView(titleKey: "placeholder.payments.title", systemImage: "arrow.left.arrow.right")
                    .navigationTitle("tab.payments")
            }
            .tabItem { Label("tab.payments", systemImage: "arrow.left.arrow.right") }
            .tag(Tab.payments)

            NavigationStack {
                ComingSoonView(titleKey: "placeholder.markets.title", systemImage: "chart.line.uptrend.xyaxis")
                    .navigationTitle("tab.markets")
            }
            .tabItem { Label("tab.markets", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(Tab.markets)

            NavigationStack {
                ComingSoonView(titleKey: "placeholder.news.title", systemImage: "newspaper")
                    .navigationTitle("tab.news")
            }
            .tabItem { Label("tab.news", systemImage: "newspaper") }
            .tag(Tab.news)

            NavigationStack {
                ProfileView(user: user)
            }
            .tabItem { Label("tab.profile", systemImage: "person") }
            .tag(Tab.profile)
        }
    }
}

#Preview {
    MainTabView(user: User(fullName: "Jana Nováková", email: "jana@example.cz"))
        .environment(AppDependencies.inMemory())
}
