import Foundation
import Security

protocol APIKeyStoring {
    func loadAPIKey() -> String
    func saveAPIKey(_ apiKey: String) throws
}

enum APIKeyStoreError: LocalizedError {
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            return "No se pudo guardar la API key en el llavero. Código: \(status)."
        }
    }
}

struct KeychainAPIKeyStore: APIKeyStoring {
    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "FloatingChat",
        account: String = "openai-api-key"
    ) {
        self.service = service
        self.account = account
    }

    func loadAPIKey() -> String {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let apiKey = String(data: data, encoding: .utf8)
        else {
            return ""
        }

        return apiKey
    }

    func saveAPIKey(_ apiKey: String) throws {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = baseQuery()

        guard !trimmedKey.isEmpty else {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw APIKeyStoreError.unexpectedStatus(status)
            }
            return
        }

        let data = Data(trimmedKey.utf8)
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            let addStatus = SecItemAdd(item as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw APIKeyStoreError.unexpectedStatus(addStatus)
            }
            return
        }

        throw APIKeyStoreError.unexpectedStatus(updateStatus)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
    }
}