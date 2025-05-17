import Combine
import Foundation

enum OpenAIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError
}

enum OpenAICompatibleModel {
    case gpt4_1
    case gemini25Flash
    case gemini25Pro
    case claude37
    case custom(model: String)

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
}

class OpenAIClient {
    private let apiKey: String
    private let baseURL: URL
    var history: [Message] = []

    init(baseURL: URL, apiKey: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    func generateStreamResponse(prompt: String, model: OpenAICompatibleModel) -> AsyncThrowingStream<Message, Error> {
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

                    var messages = history.map { ["role": $0.role.rawValue, "content": $0.content] }
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
                        throw OpenAIError.invalidResponse
                    }

                    var total: String = ""
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
