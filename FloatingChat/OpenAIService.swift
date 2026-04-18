import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    // let max_tokens: Int
}

private struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Msg: Codable { let content: String }
        let message: Msg
    }
    let choices: [Choice]
}

enum OpenAIError: LocalizedError {
    case missingKey
    case badResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:        return "Falta la API Key. Agrégala en ⚙ Ajustes."
        case .badResponse:       return "Respuesta inválida del servidor."
        case .apiError(let msg): return msg
        }
    }
}

struct OpenAIService {
    static func send(messages: [ChatMessage], apiKey: String, model: String) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else { throw OpenAIError.missingKey }

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)",  forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(
            OpenAIRequest(model: model, messages: messages, temperature: 0.7)
        )

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else { throw OpenAIError.badResponse }
        guard http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode([String: [String: String]].self, from: data))?["error"]?["message"]
            throw OpenAIError.apiError("Error \(http.statusCode): \(msg ?? "desconocido")")
        }

        guard let text = try JSONDecoder().decode(OpenAIResponse.self, from: data).choices.first?.message.content
        else { throw OpenAIError.badResponse }

        return text
    }
}
