import SwiftUI

/// Background of the brand header (balance area on the dashboard, sign-in header).
/// Flat plum in the light theme, violet gradient in the dark theme, with soft decorative circles.
struct BrandGradient: View {
    /// Decorative circles; switched off for small surfaces such as icons.
    var decorated = true

    var body: some View {
        LinearGradient(
            colors: [Theme.Colors.brand, Theme.Colors.brandEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            if decorated {
                GeometryReader { proxy in
                    let size = proxy.size
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.onBrand.opacity(0.07))
                            .frame(width: size.width * 0.9)
                            .offset(x: size.width * 0.45, y: -size.height * 0.35)
                        Circle()
                            .stroke(Theme.Colors.onBrand.opacity(0.08), lineWidth: 24)
                            .frame(width: size.width * 0.55)
                            .offset(x: -size.width * 0.4, y: size.height * 0.45)
                        Circle()
                            .fill(Theme.Colors.accent.opacity(0.18))
                            .frame(width: 90)
                            .blur(radius: 30)
                            .offset(x: size.width * 0.25, y: size.height * 0.2)
                    }
                    .frame(width: size.width, height: size.height)
                }
                .clipped()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
    }
}

#Preview {
    BrandGradient().frame(height: 260)
}
