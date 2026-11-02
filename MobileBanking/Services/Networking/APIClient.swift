import Foundation

/// What can go wrong with a network request, in terms the screens can explain.
enum NetworkError: Error, Equatable {
    /// No internet connection (or airplane mode).
    case offline
    case timeout
    /// The server answered with an error status (4xx, 5xx).
    case server(status: Int)
    /// The answer came, but could not be read.
    case invalidResponse
}

/// Thin wrapper around `URLSession` with async/await.
/// Every external service (news feeds, later stock quotes) uses it, so error handling lives in one place.
struct APIClient {
    var session: URLSession = .shared
    var timeout: TimeInterval = 15

    /// Downloads the body of a GET request.
    /// - Parameter headers: e.g. an API key. Keys go in headers, not in the URL, so they do not end up in logs.
    func data(from url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("MobileBanking-StudyApp/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                throw NetworkError.offline
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.invalidResponse
            }
        }

        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.server(status: http.statusCode) }
        return data
    }

    /// Downloads and decodes JSON with `Codable` (ready for future JSON APIs).
    func decode<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        headers: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let body = try await data(from: url, headers: headers)
        do {
            return try decoder.decode(T.self, from: body)
        } catch {
            throw NetworkError.invalidResponse
        }
    }
}
