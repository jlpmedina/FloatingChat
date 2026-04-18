import XCTest
@testable import FloatingChatCore

@MainActor
final class ChatViewModelTests: XCTestCase {
    func testInitLoadsSettingsAndKey() {
        let settingsStore = MockSettingsStore(settings: ChatSettings(model: "gpt-5.4-mini", systemPrompt: "Sistema"))
        let keyStore = MockAPIKeyStore(apiKey: "sk-test")

        let viewModel = ChatViewModel(settingsStore: settingsStore, apiKeyStore: keyStore) { _, _, _ in
            XCTFail("No debería enviar nada durante init")
            return ""
        }

        XCTAssertEqual(viewModel.makeSettingsForm(), ChatSettingsForm(apiKey: "sk-test", model: "gpt-5.4-mini", systemPrompt: "Sistema"))
    }

    func testApplySettingsPersistsNormalizedValues() {
        let settingsStore = MockSettingsStore(settings: .default)
        let keyStore = MockAPIKeyStore(apiKey: "")
        let viewModel = ChatViewModel(settingsStore: settingsStore, apiKeyStore: keyStore) { _, _, _ in "" }

        let didSave = viewModel.applySettings(
            ChatSettingsForm(apiKey: "  sk-new  ", model: "modelo-invalido", systemPrompt: "   ")
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(keyStore.apiKey, "sk-new")
        XCTAssertEqual(settingsStore.savedSettings, ChatSettings.default)
    }

    func testSendAppendsAssistantReply() async {
        let recorder = RequestRecorder()
        let viewModel = ChatViewModel(
            settingsStore: MockSettingsStore(settings: ChatSettings(model: "gpt-5.4-mini", systemPrompt: "Sistema")),
            apiKeyStore: MockAPIKeyStore(apiKey: "sk-test")
        ) { messages, apiKey, model in
            await recorder.record(messages: messages, apiKey: apiKey, model: model)
            return "Respuesta"
        }

        viewModel.inputText = "Hola"
        let task = viewModel.send()
        await task?.value

        XCTAssertEqual(viewModel.messages.map(\.role), ["user", "assistant"])
        XCTAssertEqual(viewModel.messages.last?.text, "Respuesta")
        XCTAssertFalse(viewModel.isLoading)

        let request = await recorder.snapshot()
        XCTAssertEqual(request.apiKey, "sk-test")
        XCTAssertEqual(request.model, "gpt-5.4-mini")
        XCTAssertEqual(request.messages, [
            ChatMessage(role: "system", content: "Sistema"),
            ChatMessage(role: "user", content: "Hola")
        ])
    }

    func testSendAppendsErrorMessageWhenRequestFails() async {
        let viewModel = ChatViewModel(
            settingsStore: MockSettingsStore(settings: .default),
            apiKeyStore: MockAPIKeyStore(apiKey: "sk-test")
        ) { _, _, _ in
            throw OpenAIError.apiError("falló")
        }

        viewModel.inputText = "Hola"
        let task = viewModel.send()
        await task?.value

        XCTAssertEqual(viewModel.messages.map(\.role), ["user", "error"])
        XCTAssertEqual(viewModel.messages.last?.text, "falló")
        XCTAssertFalse(viewModel.isLoading)
    }
}

private final class MockSettingsStore: ChatSettingsStoring {
    private let initialSettings: ChatSettings
    private(set) var savedSettings: ChatSettings?

    init(settings: ChatSettings) {
        initialSettings = settings
    }

    func loadSettings() -> ChatSettings {
        initialSettings
    }

    func saveSettings(_ settings: ChatSettings) {
        savedSettings = settings
    }
}

private final class MockAPIKeyStore: APIKeyStoring {
    private(set) var apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func loadAPIKey() -> String {
        apiKey
    }

    func saveAPIKey(_ apiKey: String) throws {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private actor RequestRecorder {
    private var messages: [ChatMessage] = []
    private var apiKey: String = ""
    private var model: String = ""

    func record(messages: [ChatMessage], apiKey: String, model: String) {
        self.messages = messages
        self.apiKey = apiKey
        self.model = model
    }

    func snapshot() -> (messages: [ChatMessage], apiKey: String, model: String) {
        (messages, apiKey, model)
    }
}