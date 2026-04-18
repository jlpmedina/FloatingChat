import Foundation

struct ChatMessage: Codable, Equatable {
    let role: String
    let content: String
}

private struct OpenAIRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Msg: Codable { let content: String? }
        let message: Msg
    }
    let choices: [Choice]
}

private struct OpenAIErrorEnvelope: Codable {
    struct Payload: Codable {
        let message: String?
        let type: String?
    }

    let error: Payload
}

enum OpenAIError: LocalizedError {
    case missingKey
    case badResponse
    case transportError(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:        return "Falta la API Key. Agrégala en ⚙ Ajustes."
        case .badResponse:       return "Respuesta inválida del servidor."
        case .transportError(let msg): return msg
        case .apiError(let msg): return msg
        }
    }
}

struct OpenAIService {
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = AppConfiguration.requestTimeout
        configuration.timeoutIntervalForResource = AppConfiguration.requestTimeout
        return URLSession(configuration: configuration)
    }

    static func send(
        messages: [ChatMessage],
        apiKey: String,
        model: String,
        session: URLSession = OpenAIService.makeSession()
    ) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw OpenAIError.missingKey }

        var req = URLRequest(url: AppConfiguration.chatCompletionsURL)
        req.httpMethod = "POST"
        req.timeoutInterval = AppConfiguration.requestTimeout
        req.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(
            OpenAIRequest(model: model, messages: messages, temperature: 0.7)
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw OpenAIError.transportError(Self.describeTransportError(error))
        }

        guard let http = response as? HTTPURLResponse else { throw OpenAIError.badResponse }
        guard http.statusCode == 200 else {
            let msg = decodeAPIError(from: data)
            throw OpenAIError.apiError("Error \(http.statusCode): \(msg)")
        }

        guard let text = try JSONDecoder().decode(OpenAIResponse.self, from: data).choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty
        else { throw OpenAIError.badResponse }

        return text
    }

    private static func decodeAPIError(from data: Data) -> String {
        if let payload = try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data) {
            let type = payload.error.type.map { " [\($0)]" } ?? ""
            return (payload.error.message ?? "desconocido") + type
        }

        if let rawText = String(data: data, encoding: .utf8), !rawText.isEmpty {
            return rawText
        }

        return "desconocido"
    }

    private static func describeTransportError(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return "La solicitud excedió el tiempo de espera."
            case .notConnectedToInternet:
                return "No hay conexión a Internet."
            default:
                return "Error de red: \(urlError.localizedDescription)"
            }
        }

        return "Error de transporte: \(error.localizedDescription)"
    }
}
