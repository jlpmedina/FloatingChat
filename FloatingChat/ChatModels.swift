import Foundation

struct Message: Identifiable, Equatable {
    let id: UUID
    let role: String
    let text: String

    init(id: UUID = UUID(), role: String, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }

    var isUser: Bool { role == "user" }
}

struct ChatSettings: Equatable {
    var model: String
    var systemPrompt: String

    static let `default` = ChatSettings(
        model: AppConfiguration.defaultModel,
        systemPrompt: AppConfiguration.defaultSystemPrompt
    )
}

struct ChatSettingsForm: Equatable {
    var apiKey: String
    var model: String
    var systemPrompt: String
}