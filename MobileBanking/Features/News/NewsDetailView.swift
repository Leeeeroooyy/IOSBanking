import SwiftUI

/// One article: the summary from the feed, a link to the full text and sharing.
/// Feeds carry only a short summary, so the full article opens on the publisher's website.
struct NewsDetailView: View {
    let article: NewsArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                NewsMetaLine(article: article)

                Text(verbatim: article.title)
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("news.detail.title")

                if !article.summary.isEmpty {
                    Text(verbatim: article.summary)
                        .font(.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .textSelection(.enabled)
                }

                Link(destination: article.link) {
                    Label("news.openArticle", systemImage: "safari")
                }
                .buttonStyle(.primary)
                .accessibilityIdentifier("news.openArticle")

                ShareLink(item: article.link, subject: Text(verbatim: article.title)) {
                    Label("news.share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.secondary)

                // Attribution required by the source's terms of use.
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    if article.category == .ecb {
                        Text("news.attribution.ecb")
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Link("news.terms.ecb", destination: RSSNewsService.ecbTermsURL)
                    } else {
                        Text("news.attribution.csu")
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Link("news.terms.csu", destination: RSSNewsService.csuTermsURL)
                    }
                }
                .font(.footnote)
                .tint(Theme.Colors.primary)
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
