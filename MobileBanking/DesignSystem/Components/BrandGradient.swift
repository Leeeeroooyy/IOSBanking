import SwiftUI

/// Background of the brand header (balance area on the dashboard, sign-in header).
/// Flat plum in the light theme, violet gradient in the dark theme.
struct BrandGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Theme.Colors.brand, Theme.Colors.brandEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    BrandGradient().frame(height: 200)
}
