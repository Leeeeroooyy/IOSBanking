import SwiftUI

/// Screen 15: the signed-in user, settings and sign-out.
struct ProfileView: View {
    let user: User

    @Environment(AppDependencies.self) private var dependencies

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: Theme.Spacing.m) {
                    AvatarView(initials: user.initials)
                    VStack(alignment: .leading) {
                        Text(verbatim: user.fullName)
                            .font(Theme.Typography.label)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(verbatim: user.email)
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }

            Section {
                NavigationLink {
                    AccountDataView(user: user, banking: dependencies.banking)
                } label: {
                    Label("profile.data", systemImage: "person.text.rectangle")
                }
                .accessibilityIdentifier("profile.data")

                NavigationLink {
                    SettingsView(biometrics: dependencies.biometrics, settings: dependencies.biometricSettings)
                } label: {
                    Label("settings.title", systemImage: "gearshape")
                }
                .accessibilityIdentifier("profile.settings")
            }

            Section("profile.about") {
                LabeledContent("profile.version", value: appVersion)
                Text("profile.about.note")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Section {
                Button("profile.signOut", role: .destructive) {
                    dependencies.session.signOut()
                }
                .accessibilityIdentifier("profile.signOut")
            }
        }
        .navigationTitle("tab.profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DemoBadge()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(user: User(fullName: "Jana Nováková", email: "jana@example.cz"))
    }
    .environment(AppDependencies.inMemory())
}
