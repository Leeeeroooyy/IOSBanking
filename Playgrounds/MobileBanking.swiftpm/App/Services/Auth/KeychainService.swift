import Foundation
import Security

/// Small secret values stored under an account name.
protocol KeychainService {
    func save(_ data: Data, account: String) throws
    func read(account: String) throws -> Data?
    func delete(account: String) throws
}

enum KeychainError: Error, Equatable {
    case unexpectedStatus(OSStatus)
}

/// Wrapper around the system Keychain.
struct SystemKeychainService: KeychainService {
    var service = "cz.mobiletech.MobileBanking"

    func save(_ data: Data, account: String) throws {
        try delete(account: account)

        var attributes = baseQuery(account: account)
        attributes[kSecValueData as String] = data
        // Readable only on this device, and only while it is unlocked.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    func read(account: String) throws -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw KeychainError.unexpectedStatus(status)
        }
    }

    func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

/// Keeps values in memory only. Used by previews, unit tests and UI tests,
/// so they start clean and never touch the real Keychain.
final class InMemoryKeychainService: KeychainService {
    private var items: [String: Data] = [:]

    func save(_ data: Data, account: String) throws {
        items[account] = data
    }

    func read(account: String) throws -> Data? {
        items[account]
    }

    func delete(account: String) throws {
        items[account] = nil
    }
}
