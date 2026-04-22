import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    typealias SendMessageHandler = @Sendable ([ChatMessage], String, String) async throws -> String

    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var showSettings: Bool = false
    @Published private(set) var settingsErrorMessage: String?

    private let settingsStore: ChatSettingsStoring
    private let apiKeyStore: APIKeyStoring
    private let sendMessage: SendMessageHandler

    private(set) var apiKey: String
    private(set) var model: String
    private(set) var systemPrompt: String

    init(
        settingsStore: ChatSettingsStoring? = nil,
        apiKeyStore: APIKeyStoring? = nil,
        sendMessage: @escaping SendMessageHandler = { messages, apiKey, model in
            try await OpenAIService.send(messages: messages, apiKey: apiKey, model: model)
        }
    ) {
        let settingsStore = settingsStore ?? UserDefaultsChatSettingsStore()
        let apiKeyStore = apiKeyStore ?? KeychainAPIKeyStore()
        let settings = settingsStore.loadSettings()

        self.settingsStore = settingsStore
        self.apiKeyStore = apiKeyStore
        self.sendMessage = sendMessage
        self.apiKey = apiKeyStore.loadAPIKey()
        self.model = settings.model
        self.systemPrompt = settings.systemPrompt
    }

    func makeSettingsForm() -> ChatSettingsForm {
        ChatSettingsForm(apiKey: apiKey, model: model, systemPrompt: systemPrompt)
    }

    @discardableResult
    func applySettings(_ form: ChatSettingsForm) -> Bool {
        let normalizedModel = Self.normalizeModel(form.model)
        let trimmedPrompt = form.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPrompt = trimmedPrompt.isEmpty ? AppConfiguration.defaultSystemPrompt : trimmedPrompt

        do {
            try apiKeyStore.saveAPIKey(form.apiKey)
            apiKey = form.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            model = normalizedModel
            systemPrompt = normalizedPrompt
            settingsStore.saveSettings(ChatSettings(model: normalizedModel, systemPrompt: normalizedPrompt))
            settingsErrorMessage = nil
            return true
        } catch {
            settingsErrorMessage = error.localizedDescription
            return false
        }
    }

    func clear() {
        messages = []
    }

    @discardableResult
    func send() -> Task<Void, Never>? {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return nil }

        let userMessage = Message(role: "user", text: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        let requestMessages = [ChatMessage(role: "system", content: systemPrompt)]
            + messages
                .filter { $0.role != "error" }
                .map { ChatMessage(role: $0.role, content: $0.text) }
        let apiKey = apiKey
        let model = model

        return Task {
            do {
                let reply = try await sendMessage(requestMessages, apiKey, model)
                messages.append(Message(role: "assistant", text: reply))
            } catch {
                messages.append(Message(role: "error", text: error.localizedDescription))
            }

            isLoading = false
        }
    }

    private static func normalizeModel(_ model: String) -> String {
        AppConfiguration.supportedModels.contains(model) ? model : AppConfiguration.defaultModel
    }
}
