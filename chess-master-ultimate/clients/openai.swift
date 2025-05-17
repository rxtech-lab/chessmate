import Combine
import Foundation

enum OpenAIError: LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse(url: URL, textResponse: String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse(let url, let textResponse):
            return "Invalid response from server.\n URL: \(url)\n Response: \(textResponse)"
        case .decodingError:
            return "Failed to decode response."
        }
    }
}

enum OpenAICompatibleModel: Hashable {
    case gpt4_1
    case gemini25Flash
    case gemini25Pro
    case claude37
    case custom(model: String)

    init(rawValue: String) {
        switch rawValue {
        case "gpt-4.1":
            self = .gpt4_1
        case "google/gemini-2.5-flash-preview":
            self = .gemini25Flash
        case "google/gemini-2.5-pro-preview":
            self = .gemini25Pro
        case "anthropic/claude-3.7-sonnet":
            self = .claude37
        default:
            self = .custom(model: rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .custom(let model):
            return model
        case .gpt4_1:
            return "gpt-4.1"
        case .gemini25Flash:
            return "google/gemini-2.5-flash-preview"
        case .gemini25Pro:
            return "google/gemini-2.5-pro-preview"
        case .claude37:
            return "anthropic/claude-3.7-sonnet"
        }
    }

    var displayName: String {
        switch self {
        case .custom(let model):
            return model
        case .gpt4_1:
            return "GPT-4.1"
        case .gemini25Flash:
            return "Gemini 2.5 Flash"
        case .gemini25Pro:
            return "Gemini 2.5 Pro"
        case .claude37:
            return "Claude 3.7"
        }
    }

    static var allCases: [OpenAICompatibleModel] {
        return [.gpt4_1, .gemini25Flash, .gemini25Pro, .claude37]
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .custom(let model):
            hasher.combine("custom:" + model)
        default:
            return hasher.combine(rawValue)
        }
    }
}

class OpenAIClient {
    private let apiKey: String
    private let baseURL: URL
    var history: [Message] = []

    init(baseURL: URL, apiKey: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    func generateStreamResponse(systemText: String, prompt: String, model: OpenAICompatibleModel) -> AsyncThrowingStream<Message, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let endpoint = "\(baseURL)/chat/completions"
                    guard let url = URL(string: endpoint) else {
                        throw OpenAIError.invalidURL
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                    var messages: [[String: Any]] = []
                    messages.append(["role": "system", "content": systemText])
                    messages.append(contentsOf: history.map { ["role": $0.role.rawValue, "content": $0.content] })
                    messages.append(["role": "user", "content": prompt])

                    let requestBody: [String: Any] = [
                        "model": model.rawValue,
                        "messages": messages,
                        "stream": true,
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    let (responseStream, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200 ... 299).contains(httpResponse.statusCode)
                    else {
                        let textResponse = response.description
                        throw OpenAIError.invalidResponse(url: url, textResponse: textResponse)
                    }

                    var total = ""
                    for try await line in responseStream.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let delta = choices.first?["delta"] as? [String: Any],
                           let content = delta["content"] as? String
                        {
                            total += content
                            continuation.yield(Message(role: .assistant, content: total))
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
