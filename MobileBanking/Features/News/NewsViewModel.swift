import Foundation
import Observation
import SwiftUI

/// Tab "Zprávy": articles from public RSS feeds, filtered by category.
@MainActor
@Observable
final class NewsViewModel {
    private(set) var state: LoadState<[NewsArticle]> = .loading
    private(set) var category: NewsCategory = .all
    /// Language of the last load; the feeds are reloaded when the app language changes.
    private var loadedLanguage: String?

    @ObservationIgnored private let service: any NewsService

    init(service: any NewsService) {
        self.service = service
    }

    func load(languageCode: String) async {
        loadedLanguage = languageCode
        let requested = category
        do {
            let articles = try await service.articles(in: requested, languageCode: languageCode)
            // The user may have switched the category while this one was loading.
            guard requested == category else { return }
            state = .loaded(articles)
        } catch {
            guard requested == category else { return }
            state = .failed(error as? NetworkError ?? .invalidResponse)
        }
    }

    func loadIfNeeded(languageCode: String) async {
        if case .loaded = state, loadedLanguage == languageCode { return }
        state = .loading
        await load(languageCode: languageCode)
    }

    func select(_ newCategory: NewsCategory, languageCode: String) async {
        guard newCategory != category else { return }
        category = newCategory
        state = .loading
        await load(languageCode: languageCode)
    }
}

extension NewsCategory {
    var systemImage: String {
        switch self {
        case .all: return "newspaper.fill"
        case .statistics: return "chart.bar.fill"
        case .pressReleases: return "megaphone.fill"
        case .ecb: return "eurosign.circle.fill"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: return "news.category.all"
        case .statistics: return "news.category.statistics"
        case .pressReleases: return "news.category.press"
        case .ecb: return "news.category.ecb"
        }
    }
}
