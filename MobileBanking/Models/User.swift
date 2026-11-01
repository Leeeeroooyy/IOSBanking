import Foundation
import SwiftData

/// A registered demo user. The password is never stored here:
/// only its salted hash exists, and that lives in the Keychain.
@Model
final class User {
    @Attribute(.unique) var id: UUID
    /// Always normalized (see `AuthValidator.normalizedEmail`).
    @Attribute(.unique) var email: String
    var fullName: String
    var createdAt: Date

    init(id: UUID = UUID(), fullName: String, email: String, createdAt: Date = .now) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.createdAt = createdAt
    }

    /// "Jana Nováková" → "JN".
    var initials: String {
        let letters = fullName.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
