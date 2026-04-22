import Foundation

enum AppConfiguration {
    static let chatCompletionsURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    static let requestTimeout: TimeInterval = 30
    static let supportedModels = [
        "gpt-5.4-nano",
        "gpt-5.4-mini",
        "gpt-5.4"
    ]
    static let defaultModel = supportedModels[0]
    static let defaultSystemPrompt = "Eres un asistente útil y conciso. No uses Markdown."
}
