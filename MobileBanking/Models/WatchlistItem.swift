import Foundation
import SwiftData

/// A stock the user follows. Saved on the device, separately for every user.
@Model
final class WatchlistItem {
    var ownerID: UUID
    var symbol: String
    var addedAt: Date

    init(ownerID: UUID, symbol: String, addedAt: Date = .now) {
        self.ownerID = ownerID
        self.symbol = symbol
        self.addedAt = addedAt
    }
}
