import SwiftUI

/// Layout of design variant C: a brand header and a rounded sheet that overlaps it.
/// It scrolls, so long content, large Dynamic Type and the keyboard all fit.
struct BrandScaffold<Header: View, Content: View>: View {
    /// Maximum width of the content on wide screens (iPad).
    static var readableWidth: CGFloat { 720 }

    private let header: Header
    private let content: Content

    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    // On iPad the content keeps a readable width instead of stretching edge to edge.
                    .frame(maxWidth: Self.readableWidth, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.xxl)
                    // Extra space at the bottom: the sheet overlaps the header by its corner radius.
                    .padding(.bottom, Theme.Spacing.xxl + Theme.Radius.sheet)
                    .frame(maxWidth: .infinity)
                    .background(BrandGradient().ignoresSafeArea(edges: .top))

                content
                    .frame(maxWidth: Self.readableWidth, alignment: .topLeading)
                    .padding(Theme.Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .sheetSurface()
                    .padding(.top, -Theme.Radius.sheet)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.Colors.surface.ignoresSafeArea())
    }
}

#Preview {
    BrandScaffold {
        Text("app.name").foregroundStyle(Theme.Colors.onBrand)
    } content: {
        Text("login.title").foregroundStyle(Theme.Colors.textPrimary)
    }
}
