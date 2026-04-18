import Foundation

protocol ChatSettingsStoring {
    func loadSettings() -> ChatSettings
    func saveSettings(_ settings: ChatSettings)
}

struct UserDefaultsChatSettingsStore: ChatSettingsStoring {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadSettings() -> ChatSettings {
        let storedModel = userDefaults.string(forKey: "model") ?? AppConfiguration.defaultModel
        let storedPrompt = userDefaults.string(forKey: "systemPrompt") ?? AppConfiguration.defaultSystemPrompt

        return ChatSettings(
            model: AppConfiguration.supportedModels.contains(storedModel) ? storedModel : AppConfiguration.defaultModel,
            systemPrompt: storedPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? AppConfiguration.defaultSystemPrompt
                : storedPrompt
        )
    }

    func saveSettings(_ settings: ChatSettings) {
        userDefaults.set(settings.model, forKey: "model")
        userDefaults.set(settings.systemPrompt, forKey: "systemPrompt")
    }
}