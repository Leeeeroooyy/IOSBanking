import CommonCrypto
import Foundation
import Security

/// What the Keychain holds for a user instead of the password.
struct PasswordCredential: Codable, Equatable {
    let salt: Data
    let hash: Data
    let iterations: Int
}

enum PasswordHasherError: Error {
    case randomGeneratorFailed
    case derivationFailed
}

/// Salted PBKDF2-HMAC-SHA256 from Apple's CommonCrypto.
///
/// Hashing is slow on purpose, so call it away from the main actor.
enum PasswordHasher {
    /// OWASP recommendation for PBKDF2-HMAC-SHA256.
    static let defaultIterations = 600_000

    private static let saltLength = 16
    private static let hashLength = 32

    static func makeCredential(password: String, iterations: Int = defaultIterations) throws -> PasswordCredential {
        let salt = try randomSalt()
        let hash = try derive(password: password, salt: salt, iterations: iterations)
        return PasswordCredential(salt: salt, hash: hash, iterations: iterations)
    }

    static func verify(password: String, credential: PasswordCredential) throws -> Bool {
        let hash = try derive(password: password, salt: credential.salt, iterations: credential.iterations)
        return constantTimeEquals(hash, credential.hash)
    }

    static func derive(password: String, salt: Data, iterations: Int) throws -> Data {
        // The same text typed with composed or decomposed letters must give the same hash.
        let normalized = password.precomposedStringWithCanonicalMapping
        let passwordLength = normalized.utf8.count
        var derived = [UInt8](repeating: 0, count: hashLength)

        let status = normalized.withCString { passwordPointer in
            salt.withUnsafeBytes { saltBuffer in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordPointer,
                    passwordLength,
                    saltBuffer.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    &derived,
                    hashLength
                )
            }
        }
        guard status == Int32(kCCSuccess) else { throw PasswordHasherError.derivationFailed }
        return Data(derived)
    }

    private static func randomSalt() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: saltLength)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw PasswordHasherError.randomGeneratorFailed
        }
        return Data(bytes)
    }

    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}
