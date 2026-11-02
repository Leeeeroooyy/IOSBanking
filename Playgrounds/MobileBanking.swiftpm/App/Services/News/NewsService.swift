import Foundation

/// Sections of the news tab. Every section is one or more public RSS feeds (free, no API key).
enum NewsCategory: String, CaseIterable, Identifiable {
    case all
    /// ČSÚ "Rychlé informace": fresh statistics (GDP, inflation, unemployment…).
    case statistics
    /// ČSÚ press releases.
    case pressReleases
    /// Press releases of the European Central Bank (English only).
    case ecb

    var id: String { rawValue }
}

/// One article of a feed.
struct NewsArticle: Identifiable, Hashable {
    let title: String
    let summary: String
    let link: URL
    let source: String
    let date: Date?
    let category: NewsCategory

    var id: URL { link }
}

@MainActor
protocol NewsService {
    /// `languageCode` is "cs" or "en"; feeds that exist in both languages follow it.
    func articles(in category: NewsCategory, languageCode: String) async throws -> [NewsArticle]
}

/// Reads RSS feeds of the Czech Statistical Office (ČSÚ) and the European Central Bank.
/// https://csu.gov.cz/rss · https://www.ecb.europa.eu/home/html/rss.en.html
@MainActor
final class RSSNewsService: NewsService {
    struct Feed {
        let category: NewsCategory
        let source: String
        let url: URL
    }

    private let client: APIClient

    /// Terms of use. ČSÚ data are licensed under CC BY 4.0: sharing them requires naming the source
    /// and a link to these terms. The ECB allows free use when the ECB is cited as the source.
    static let csuTermsURL = URL(string: "https://csu.gov.cz/podminky_pro_vyuzivani_a_dalsi_zverejnovani_statistickych_udaju_csu")!
    static let ecbTermsURL = URL(string: "https://www.ecb.europa.eu/home/disclaimer/html/index.en.html")!

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    static func feeds(for category: NewsCategory, languageCode: String) -> [Feed] {
        let language = languageCode == "en" ? "EN" : "CS"
        let statistics = Feed(
            category: .statistics,
            source: language == "EN" ? "CZSO" : "ČSÚ",
            url: URL(string: "https://csu.gov.cz/rss/produkty?kodVlastnostiVystupu=RI&jazyk=\(language)")!
        )
        let press = Feed(
            category: .pressReleases,
            source: language == "EN" ? "CZSO" : "ČSÚ",
            url: URL(string: "https://csu.gov.cz/rss/produkty?kodVlastnostiVystupu=TZ&jazyk=\(language)")!
        )
        let ecb = Feed(category: .ecb, source: "ECB", url: URL(string: "https://www.ecb.europa.eu/rss/press.html")!)

        switch category {
        case .all: return [statistics, press, ecb]
        case .statistics: return [statistics]
        case .pressReleases: return [press]
        case .ecb: return [ecb]
        }
    }

    func articles(in category: NewsCategory, languageCode: String) async throws -> [NewsArticle] {
        let feeds = Self.feeds(for: category, languageCode: languageCode)

        // All feeds at once; one failing feed does not hide the others.
        var collected: [NewsArticle] = []
        var firstError: Error?
        await withTaskGroup(of: Result<[NewsArticle], Error>.self) { group in
            for feed in feeds {
                group.addTask { @MainActor in
                    do {
                        let data = try await self.client.data(from: feed.url)
                        return .success(RSSParser.parse(data).map { item in
                            NewsArticle(
                                title: item.title,
                                summary: item.summary,
                                link: item.link,
                                source: feed.source,
                                date: item.date,
                                category: feed.category
                            )
                        })
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await result in group {
                switch result {
                case .success(let articles): collected += articles
                case .failure(let error): firstError = firstError ?? error
                }
            }
        }

        if collected.isEmpty, let firstError { throw firstError }

        // Newest first; articles without a date at the end. Duplicates (same link) only once.
        var seen = Set<URL>()
        return collected
            .filter { seen.insert($0.link).inserted }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
}

/// A small RSS 2.0 parser built on Foundation's `XMLParser`.
final class RSSParser: NSObject, XMLParserDelegate {
    struct Item: Equatable {
        let title: String
        let summary: String
        let link: URL
        let date: Date?
    }

    private var items: [Item] = []
    private var current: [String: String]?
    private var text = ""

    static func parse(_ data: Data) -> [Item] {
        let delegate = RSSParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String: String] = [:]) {
        if elementName == "item" || elementName == "entry" {
            current = [:]
        } else if elementName == "link", current != nil, let href = attributes["href"] {
            // Atom feeds keep the link in an attribute.
            current?["link"] = href
        }
        text = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        text += String(data: CDATABlock, encoding: .utf8) ?? ""
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard current != nil else { return }
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "title", "description", "summary", "pubDate", "dc:date", "updated":
            if !value.isEmpty { current?[elementName] = value }
        case "link":
            if !value.isEmpty { current?["link"] = value }
        case "item", "entry":
            if let item = makeItem(current ?? [:]) { items.append(item) }
            current = nil
        default:
            break
        }
        text = ""
    }

    private func makeItem(_ fields: [String: String]) -> Item? {
        guard
            var title = fields["title"],
            let linkText = fields["link"],
            let link = URL(string: linkText),
            link.scheme == "https" || link.scheme == "http"
        else { return nil }

        var date = Self.date(fields["pubDate"] ?? fields["dc:date"] ?? fields["updated"])
        // ČSÚ puts the date in front of the title: "30. 10. 2026 Předběžný odhad HDP".
        if let (prefixDate, rest) = Self.splitDatePrefix(title) {
            date = date ?? prefixDate
            title = rest
        }

        let summary = Self.plainText(fields["description"] ?? fields["summary"] ?? "")
        return Item(title: Self.plainText(title), summary: summary, link: link, date: date)
    }

    // MARK: - Helpers

    static func date(_ text: String?) -> Date? {
        guard let text else { return nil }
        if let date = try? Date(text, strategy: .iso8601) { return date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["EEE, dd MMM yyyy HH:mm:ss Z", "EEE, dd MMM yyyy HH:mm:ss zzz", "dd MMM yyyy HH:mm:ss Z"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }

    static func splitDatePrefix(_ title: String) -> (Date, String)? {
        guard let match = title.firstMatch(of: #/^(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})\s+/#) else { return nil }
        var components = DateComponents()
        components.day = Int(match.1)
        components.month = Int(match.2)
        components.year = Int(match.3)
        components.hour = 12
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Prague") ?? .current
        guard let date = calendar.date(from: components) else { return nil }
        return (date, String(title[match.range.upperBound...]))
    }

    /// Feeds may contain HTML tags and entities; the app shows plain text only.
    static func plainText(_ html: String) -> String {
        var text = html.replacing(#/<[^>]+>/#, with: " ")
        let entities = ["&nbsp;": " ", "&amp;": "&", "&quot;": "\"", "&#39;": "'", "&apos;": "'", "&lt;": "<", "&gt;": ">", "&ndash;": "–", "&mdash;": "—"]
        for (entity, character) in entities {
            text = text.replacingOccurrences(of: entity, with: character)
        }
        return text.replacing(#/\s+/#, with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
