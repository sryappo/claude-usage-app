import Foundation
import Security

enum KeychainHelper {
    enum KeychainError: Error, LocalizedError {
        case notFound
        case invalidData
        case noAccessToken
        case unexpectedStatus(OSStatus)

        var errorDescription: String? {
            switch self {
            case .notFound:
                return "Claude Code credentials not found in Keychain. Run 'claude login' first."
            case .invalidData:
                return "Could not decode Keychain data."
            case .noAccessToken:
                return "No OAuth access token found in credentials."
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            }
        }
    }

    /// Reads the Claude Code OAuth access token from macOS Keychain.
    /// Claude Code stores credentials under service "Claude Code-credentials".
    static func getAccessToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw KeychainError.notFound
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = item as? Data,
              let jsonString = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        // The Keychain entry is a JSON blob. Extract accessToken from claudeAiOauth.
        guard let json = try JSONSerialization.jsonObject(with: Data(jsonString.utf8)) as? [String: Any] else {
            throw KeychainError.invalidData
        }

        // Try claudeAiOauth.accessToken first
        if let oauth = json["claudeAiOauth"] as? [String: Any],
           let token = oauth["accessToken"] as? String {
            return token
        }

        // Fallback: try top-level accessToken
        if let token = json["accessToken"] as? String {
            return token
        }

        throw KeychainError.noAccessToken
    }
}
