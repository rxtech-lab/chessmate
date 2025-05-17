//
//  ChatListView.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import PgnCore
import SwiftUI

struct ChatListView: View {
    @State var chat: Chat
    let gameState: GameState
    @State private var newMessage: String = ""
    @State private var error: Error? = nil
    @State private var showAlert: Bool = false

    @Environment(ChatModel.self) private var chatModel

    init(chat: Chat, gameState: GameState) {
        self._chat = .init(initialValue: chat)
        self.gameState = gameState
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0 ..< chat.messages.count, id: \.self) { index in
                            ChatMessageRow(message: chat.messages[index])
                                .id(index)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                .onChange(of: chat.messages.count) { _, _ in
                    if chat.messages.count > 0 {
                        withAnimation {
                            proxy.scrollTo(chat.messages.count - 1, anchor: .bottom)
                        }
                    }
                }
            }

            MessageInputView(
                text: $newMessage,
                onSend: {
                    Task {
                        do {
                            try await sendMessage(message: newMessage)
                        } catch {
                            print("Error sending message: \(error)")
                            self.error = error
                        }
                        newMessage = ""
                    }
                }
            )
        }
        .alert("Error to chat", isPresented: $showAlert, actions: {
            Button("OK", role: .cancel) {
                showAlert = false
            }
        }, message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        })
        .frame(maxWidth: .infinity)
    }

    @MainActor
    func sendMessage(message: String) async throws {
        let stream = try await chatModel.chat(history: chat.messages, text: message, gameState: gameState)
        chat.messages.append(.init(role: .user, content: message))
        var finalMessage = Message(role: .assistant, content: "...")
        chat.messages.append(finalMessage)
        for try await message in stream {
            finalMessage = message
            // find the pending message by id
            if let index = chat.messages.firstIndex(where: { $0.id == finalMessage.id }) {
                chat.messages[index].content = finalMessage.content
            }
        }
    }
}

struct ChatMessageRow: View {
    var message: Message

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Color.gray.opacity(0.18))
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 280, alignment: .trailing)
            } else {
                Text(message.content)
                    .padding(12)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
    }
}
