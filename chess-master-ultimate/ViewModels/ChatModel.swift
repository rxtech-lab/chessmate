//
//  ChatModel.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import PgnCore
import SwiftUI

@Observable
class ChatModel {
    var url: URL?
    var apiKey: String?
    var model: OpenAICompatibleModel?

    func load(url: URL, apiKey: String, model: OpenAICompatibleModel) {
        self.url = url
        self.apiKey = apiKey
        self.model = model
    }

    @MainActor
    func chat(history: [Message], text: String, gameState: GameState) async throws -> AsyncThrowingStream<Message, Error> {
        guard let url = url else {
            throw NSError(domain: "URL is nil", code: 0, userInfo: nil)
        }

        guard let apiKey = apiKey else {
            throw NSError(domain: "API Key is nil", code: 0, userInfo: nil)
        }

        guard let model = model else {
            throw NSError(domain: "Model is nil", code: 0, userInfo: nil)
        }
        let api = OpenAIClient(baseURL: url, apiKey: apiKey)
        api.history = history
        return api.generateStreamResponse(prompt: text, model: model)
    }
}
