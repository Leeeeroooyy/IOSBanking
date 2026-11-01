import SwiftUI

/// Design tokens of the app.
///
/// Every color is a Color Set in `Assets.xcassets` with a light value
/// (design variant C) and a dark value (design variant D). Screens only use
/// these names, so they never need to know which theme is active.
enum Theme {

    enum Colors {
        static let background = Color("AppBackground")
        static let surface = Color("AppSurface")
        static let surfaceRaised = Color("AppSurfaceRaised")
        static let border = Color("AppBorder")

        /// Header ("brand") area. In the light theme both colors are the same (flat plum),
        /// in the dark theme they form a violet gradient.
        static let brand = Color("AppBrand")
        static let brandEnd = Color("AppBrandEnd")
        static let onBrand = Color("AppOnBrand")
        static let onBrandSecondary = Color("AppOnBrandSecondary")

        /// Links, selected tab, focused controls.
        static let primary = Color("AppPrimary")
        /// The main call to action ("Poslat peníze") and the DEMO badge.
        static let accent = Color("AppAccent")
        static let onAccent = Color("AppOnAccent")

        static let textPrimary = Color("AppTextPrimary")
        static let textSecondary = Color("AppTextSecondary")

        /// Incoming money. Outgoing amounts use `textPrimary`, not red,
        /// so the screen does not look alarming.
        static let positive = Color("AppPositive")
        /// Errors and validation messages.
        static let negative = Color("AppNegative")
    }

    /// Spacing scale in points (multiples of 4).
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        /// Top corners of the sheet that overlaps the brand header.
        static let sheet: CGFloat = 28
    }

    /// Text styles. They are based on system text styles, so they scale with Dynamic Type.
    /// The rounded design is SF Pro Rounded.
    enum Typography {
        static let balance = Font.system(.largeTitle, design: .rounded, weight: .heavy)
        static let title = Font.system(.title2, design: .rounded, weight: .heavy)
        static let sectionTitle = Font.system(.title3, design: .rounded, weight: .heavy)
        static let amount = Font.system(.body, design: .rounded, weight: .bold)
        static let label = Font.system(.subheadline, design: .rounded, weight: .semibold)
    }
}
