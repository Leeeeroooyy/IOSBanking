import Foundation

/// Two ready-made profiles for trying payments between users:
/// send money from one, sign out, sign in as the other and see it arrive.
/// They are demo data of the study app, like everything else in it.
enum TestAccounts {
    struct Profile {
        let fullName: String
        let email: String
    }

    /// The same password for both, shown on the sign-in screen.
    static let password = "test1234"

    static let profiles = [
        Profile(fullName: "Tomáš Král", email: "test1@mobilebanking.cz"),
        Profile(fullName: "Lucie Malá", email: "test2@mobilebanking.cz"),
    ]

    static var emails: Set<String> { Set(profiles.map(\.email)) }

    /// Creates the missing profiles and opens their demo accounts. Safe to call on every launch.
    @MainActor
    static func prepare(auth: LocalAuthService, banking: LocalBankingService) async {
        for profile in profiles {
            guard let user = try? await auth.createUserIfMissing(
                fullName: profile.fullName, email: profile.email, password: password
            ) else { continue }
            try? banking.prepareDemoAccounts(for: user)
        }
    }
}
