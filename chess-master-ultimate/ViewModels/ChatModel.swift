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
        let langStr = Locale.current.language.languageCode?.identifier
        api.history = history
        let systemPrompt = """
        You are a chess master and the world's best chess teacher.
        You are given a chess position until the current move in PGN format,
        and you need to analyze the given position and tell user the motive behind the move.
        Also don't forget to answer any follow-up questions for the chess if needed.
        Don't answer any other questions.

        Current language: \(langStr ?? "en")
        IsFirstMove: \(gameState.hasPreviousMove ? "false" : "true")
        IsLastMove: \(gameState.hasNextMove ? "false" : "true")
        CurrentMove: \(gameState.currentMoveIndex)

        Answer the user's question in the same language the current language or user's questions's language.
        If it is the first move, tell user make the first move then analyze the game.
        If it is the last move, analyze the overall game and tell user the result.
        The current position is:
        \(gameState.getPreviousMoves())
        """

        return api.generateStreamResponse(systemText: systemPrompt, prompt: text, model: model)
    }
}
