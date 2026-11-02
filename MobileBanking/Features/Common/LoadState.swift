import SwiftUI

/// States of a screen that loads data (from the internet or a data source).
enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed(NetworkError)
}

extension NetworkError {
    /// What the error screen says.
    var messageKey: LocalizedStringKey {
        switch self {
        case .offline: return "error.offline.message"
        case .timeout: return "error.timeout.message"
        case .server(let status) where status == 401 || status == 403: return "error.unauthorized.message"
        case .server(let status) where status == 429: return "error.rateLimit.message"
        case .server, .invalidResponse: return "error.server.message"
        }
    }
}
