import SwiftUI

/// The rounded sheet that overlaps the brand header (layout of design variant C).
/// Only the top corners are rounded; the surface continues under the home indicator.
struct SheetSurface: ViewModifier {
    func body(content: Content) -> some View {
        content.background {
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.Radius.sheet,
                topTrailingRadius: Theme.Radius.sheet,
                style: .continuous
            )
            .fill(Theme.Colors.surface)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

extension View {
    func sheetSurface() -> some View {
        modifier(SheetSurface())
    }
}
