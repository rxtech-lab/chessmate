//
//  ChatListView.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import PgnCore
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
                    LazyVStack(spacing: 5) {
                        ForEach(chat.messages) { message in
                            ChatMessageRow(message: message,
                                           onDelete: {
                                               withAnimation(.easeInOut(duration: 0.3)) {
                                                   chat.messages.removeAll(where: { $0.id == message.id })
                                               }
                                           },
                                           onEdit: { newContent, editedMessage in
                                               handleMessageEdit(newContent: newContent, editedMessage: editedMessage)
                                           })
                                           .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                }
                .onChange(of: chat.messages.count) { _, _ in
                    if let lastMessage = chat.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            MessageInputView(
                text: $newMessage,
                onSend: {
                    Task {
                        do {
                            let message = newMessage
                            newMessage = ""
                            try await sendMessage(message: message)
                        } catch {
                            print("Error sending message: \(error)")
                            self.error = error
                            self.showAlert = true
                        }
                    }
                }
            ) {
                Task {
                    do {
                        try await askAboutCurrentMove()
                    } catch {
                        print("Error asking about current move: \(error)")
                        self.error = error
                        self.showAlert = true
                    }
                }
            }
        }
        .alert(
            "Error to chat", isPresented: $showAlert,
            actions: {
                Button("OK", role: .cancel) {
                    showAlert = false
                }
            },
            message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
        )
        .frame(maxWidth: .infinity)
    }

    @MainActor
    func handleMessageEdit(newContent: String, editedMessage: Message) {
        guard let index = chat.messages.firstIndex(where: { $0.id == editedMessage.id }) else {
            return
        }

        // Create a new message with updated content but keep the same ID
        let updatedMessage = Message(id: editedMessage.id, role: editedMessage.role, content: newContent, createdAt: .now)

        // Remove all messages after this one
        let messagesToKeep = Array(chat.messages.prefix(through: index))

        // Replace the edited message with the updated content
        chat.messages = messagesToKeep
        chat.messages[index] = updatedMessage

        // Regenerate the AI response
        Task {
            do {
                try await sendMessage(message: newContent, isEdit: true)
            } catch {
                print("Error regenerating message: \(error)")
                self.error = error
                self.showAlert = true
            }
        }
    }

    @MainActor
    func sendMessage(message: String, isEdit: Bool = false) async throws {
        if !isEdit {
            chat.messages.append(.init(role: .user, content: message))
        }

        let stream = try await chatModel.chat(
            history: chat.messages, text: isEdit ? "" : message, gameState: gameState
        )

        let finalMessage = Message(role: .assistant, content: "...")
        chat.messages.append(finalMessage)
        for try await message in stream {
            if let index = chat.messages.firstIndex(where: { $0.id == finalMessage.id }) {
                chat.messages[index].content = message.content
            }
        }
    }

    @MainActor
    func askAboutCurrentMove() async throws {
        let stream = try await chatModel.chat(
            history: chat.messages, text: "Explain the current move using natual language", gameState: gameState
        )

        let finalMessage = Message(role: .assistant, content: "...")
        chat.messages.append(finalMessage)
        for try await message in stream {
            if let index = chat.messages.firstIndex(where: { $0.id == finalMessage.id }) {
                chat.messages[index].content = message.content
            }
        }
    }
}

struct ChatMessageRow: View {
    var message: Message
    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editedContent: String = ""
    var onDelete: (() -> Void)? = nil
    var onEdit: ((String, Message) -> Void)? = nil

    var body: some View {
        let markdown = LocalizedStringKey(message.content)
        VStack(alignment: message.role == .user ? .trailing : .leading) {
            HStack(alignment: .top) {
                if message.role == .user {
                    Spacer()
                    if isEditing {
                        TextEditor(text: $editedContent)
                            .padding(8)
                            .background(Color.gray.opacity(0.18))
                            .cornerRadius(16)
                            .textEditorStyle(.plain)
                            .frame(maxWidth: 280, minHeight: 80, alignment: .trailing)
                    } else {
                        Text(markdown)
                            .padding(12)
                            .background(Color.gray.opacity(0.18))
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .frame(maxWidth: 280, alignment: .trailing)
                    }
                } else {
                    Text(markdown)
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }

            // action buttons
            HStack {
                if message.role == .user {
                    Spacer()

                    if isEditing {
                        Button(action: {
                            isEditing = false
                        }) {
                            Text("Cancel")
                                .foregroundStyle(Color.gray)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)

                        Button(action: {
                            onEdit?(editedContent, message)
                            isEditing = false
                        }) {
                            Text("Submit")
                                .foregroundStyle(Color.blue)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    } else {
                        Button(action: {
                            editedContent = message.content
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.gray.opacity(1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !isEditing {
                    Button(action: {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = message.content
                        #elseif canImport(AppKit)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.content, forType: .string)
                        #endif
                    }) {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(Color.gray.opacity(1))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation {
                            onDelete?()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.gray.opacity(1))
                    }
                    .buttonStyle(.plain)
                }

                if message.role != .user {
                    Spacer()
                }
            }
            .opacity(isEditing || message.role == .assistant ? 1 : isHovering ? 1 : 0)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

#Preview {
    ChatMessageRow(message: .init(role: .assistant, content: "Hello world"))
    ChatMessageRow(message: .init(role: .user, content: "Hello world"))
}
