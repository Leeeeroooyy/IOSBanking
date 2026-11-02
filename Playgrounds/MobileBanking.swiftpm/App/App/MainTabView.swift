import SwiftUI

/// The tabs of the signed-in part. Other screens can switch tabs (dashboard quick actions).
enum MainTab {
    case dashboard
    case payments
    case markets
    case news
    case profile
}

/// The signed-in part of the app. Each tab has its own `NavigationStack`,
/// so switching tabs keeps the place inside each of them.
struct MainTabView: View {
    let user: User

    @Environment(AppDependencies.self) private var dependencies
    @State private var selection: MainTab = .dashboard

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                DashboardView(user: user, banking: dependencies.banking) { selection = $0 }
            }
            .tabItem { Label("tab.dashboard", systemImage: "house") }
            .tag(MainTab.dashboard)

            NavigationStack {
                TransferFormView(user: user, banking: dependencies.banking)
            }
            .tabItem { Label("tab.payments", systemImage: "arrow.left.arrow.right") }
            .tag(MainTab.payments)

            NavigationStack {
                MarketsView(
                    user: user,
                    stocks: dependencies.stocks,
                    watchlist: dependencies.watchlist
                )
            }
            .tabItem { Label("tab.markets", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(MainTab.markets)

            NavigationStack {
                NewsListView(service: dependencies.news)
            }
            .tabItem { Label("tab.news", systemImage: "newspaper") }
            .tag(MainTab.news)

            NavigationStack {
                ProfileView(user: user)
            }
            .tabItem { Label("tab.profile", systemImage: "person") }
            .tag(MainTab.profile)
        }
    }
}

#Preview {
    MainTabView(user: User(fullName: "Jana Nováková", email: "jana@example.cz"))
        .environment(AppDependencies.inMemory())
}
