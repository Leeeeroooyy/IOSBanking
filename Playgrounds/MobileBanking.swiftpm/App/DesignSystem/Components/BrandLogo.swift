import SwiftUI

/// The app's mark: a bank building in a rounded square, used in the brand headers.
struct BrandLogo: View {
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: "building.columns.fill")
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(Theme.Colors.onAccent)
            .frame(width: size, height: size)
            .background(Theme.Colors.accent, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            .accessibilityHidden(true)
    }
}

/// A symbol in a translucent tile on the brand header (payments, markets, news).
struct HeaderIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(Theme.Colors.onBrand)
            .frame(width: 48, height: 48)
            .background(Theme.Colors.onBrand.opacity(0.14), in: RoundedRectangle(cornerRadius: Theme.Radius.s, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        BrandLogo()
        HeaderIcon(systemImage: "paperplane.fill")
    }
    .padding()
    .background(BrandGradient())
}
