import SwiftUI

/// Tab "Přehled". The header is final; accounts and transactions arrive in stage 4.
struct DashboardView: View {
    let user: User

    var body: some View {
        BrandScaffold {
            HStack(spacing: Theme.Spacing.m) {
                AvatarView(initials: user.initials)

                VStack(alignment: .leading) {
                    Text("dashboard.welcome")
                        .font(.footnote)
                        .foregroundStyle(Theme.Colors.onBrandSecondary)
                    Text(verbatim: user.fullName)
                        .font(Theme.Typography.sectionTitle)
                        .foregroundStyle(Theme.Colors.onBrand)
                        .lineLimit(2)
                        .accessibilityIdentifier("dashboard.userName")
                }

                Spacer()
                DemoBadge()
            }
        } content: {
            ComingSoonView(titleKey: "placeholder.dashboard.title", systemImage: "banknote")
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        DashboardView(user: User(fullName: "Jana Nováková", email: "jana@example.cz"))
    }
}
