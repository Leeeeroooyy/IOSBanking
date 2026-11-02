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

                Text(verbatim: article.link.host() ?? "")
                    .font(.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.Colors.surface.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
