import SwiftUI

/// Tab "Zprávy": economic news from ČSÚ and the ECB (live RSS feeds).
struct NewsListView: View {
    @State private var model: NewsViewModel
    @Environment(\.locale) private var locale

    init(service: any NewsService) {
        _model = State(initialValue: NewsViewModel(service: service))
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier == "en" ? "en" : "cs"
    }

    var body: some View {
        BrandScaffold {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("news.title")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.Colors.onBrand)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("news.title")
                Text("news.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.onBrandSecondary)
            }
        } content: {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                categoryPicker
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await model.load(languageCode: languageCode) }
        .task(id: languageCode) { await model.loadIfNeeded(languageCode: languageCode) }
        .navigationDestination(for: NewsArticle.self) { article in
            NewsDetailView(article: article)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                ForEach(NewsCategory.allCases) { category in
                    let isSelected = model.category == category
                    Button {
                        Task { await model.select(category, languageCode: languageCode) }
                    } label: {
                        Text(category.titleKey)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? Theme.Colors.onBrand : Theme.Colors.textPrimary)
                            .padding(.horizontal, Theme.Spacing.m)
                            .frame(minHeight: 40)
                            .background(isSelected ? Theme.Colors.primary : Theme.Colors.surfaceRaised, in: Capsule())
                            .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.Colors.border))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? AccessibilityTraits.isSelected : AccessibilityTraits())
                    .accessibilityIdentifier("news.category.\(category.rawValue)")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView("common.loading")
                .frame(maxWidth: .infinity, minHeight: 200)
        case .failed(let error):
            ErrorStateView(message: error.messageKey) {
                Task { await model.load(languageCode: languageCode) }
            }
        case .loaded(let articles) where articles.isEmpty:
            ContentUnavailableView("news.empty", systemImage: "newspaper")
        case .loaded(let articles):
            LazyVStack(spacing: Theme.Spacing.m) {
                ForEach(articles) { article in
                    NavigationLink(value: article) {
                        NewsRow(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("news.disclaimer")
                .font(.footnote)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

/// One article in the list: source and date, title and the start of the summary.
struct NewsRow: View {
    let article: NewsArticle

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            NewsMetaLine(article: article)
            Text(verbatim: article.title)
                .font(.body.weight(.bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            if !article.summary.isEmpty {
                Text(verbatim: article.summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(Theme.Colors.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.m, style: .continuous).stroke(Theme.Colors.border))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// "ČSÚ · 30. října 2026"
struct NewsMetaLine: View {
    let article: NewsArticle

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(verbatim: article.source)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.Colors.primary)
            if let date = article.date {
                Text(verbatim: "·").foregroundStyle(Theme.Colors.textSecondary)
                Text(date, format: .dateTime.day().month(.wide).year())
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }
}
