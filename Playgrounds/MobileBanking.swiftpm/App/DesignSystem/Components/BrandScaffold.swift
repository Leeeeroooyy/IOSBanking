import SwiftUI

/// Layout of design variant C: a brand header and a rounded sheet that overlaps it.
/// It scrolls, so long content, large Dynamic Type and the keyboard all fit.
struct BrandScaffold<Header: View, Content: View>: View {
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
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.xxl)
                    // Extra space at the bottom: the sheet overlaps the header by its corner radius.
                    .padding(.bottom, Theme.Spacing.xxl + Theme.Radius.sheet)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BrandGradient().ignoresSafeArea(edges: .top))

                content
                    .padding(Theme.Spacing.xl)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
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
