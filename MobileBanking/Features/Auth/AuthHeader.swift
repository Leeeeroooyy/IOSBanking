import SwiftUI

/// Brand header of the sign-in and sign-up screens.
struct AuthHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .center, spacing: Theme.Spacing.m) {
                BrandLogo(size: 44)
                Text("app.name")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.onBrand)
                Spacer()
            }
            Text("auth.tagline")
                .font(.subheadline)
                .foregroundStyle(Theme.Colors.onBrandSecondary)
        }
    }
}
