//
//  ContentView.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/16/25.
//

import PgnCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

let config = ChessBoardConfig(
    whitePieces: .init(
        king: Image("white-king"),
        queen: Image("white-queen"),
        rook: Image("white-rook"),
        bishop: Image("white-bishop"),
        knight: Image("white-knight"),
        pawn: Image("white-pawn")
    ),
    blackPieces: .init(
        king: Image("black-king"),
        queen: Image("black-queen"),
        rook: Image("black-rook"),
        bishop: Image("black-bishop"),
        knight: Image("black-knight"),
        pawn: Image("black-pawn")
    ),
    lightSquareColor: .brown.opacity(0.9),
    darkSquareColor: .yellow.opacity(0.2)
)

struct ContentView: View {
    @Environment(PgnCore.self) var pgnCore
    @Environment(\.modelContext) private var modelContext
    @Environment(ChatModel.self) var chatModel
    @AppStorage("openAIUrl") var openAIUrl: String = ""
    @AppStorage("openAIKey") var openAIKey: String = ""
    @AppStorage("openAIModel") var openAIModel: String = ""

    @State private var chat: Chat? = nil

    var body: some View {
        NavigationSplitView(
            sidebar: {
                GamesList()
            },
            content: {
                if self.pgnCore.gameState.metadata == nil {
                    Text("No game loaded")
                        .foregroundStyle(.secondary)
                } else {
                    VStack {
                        ChessBoardView(
                            config: config,
                            gameState: self.pgnCore.gameState,
                            onSquareTap: { square in
                                print("Tapped square: \(square)")
                            }
                        )
                        HStack {
                            Text("Move: \(self.pgnCore.gameState.currentMoveIndex)")
                        }
                    }
                    .frame(minWidth: 450)
                }
            },
            detail: {
                if let chat = chat {
                    ChatListView(chat: chat, gameState: pgnCore.gameState)
                        .frame(minWidth: 200)
                }
            }
        )
        .onChange(of: pgnCore.gameState.metadata) { _, _ in
            loadChat()
        }
        .task {
            loadChat()
            loadAI()
        }
        .onChange(of: openAIKey) { _, _ in
            loadAI()
        }
        .onChange(of: openAIUrl) { _, _ in
            loadAI()
        }
        .onChange(of: openAIModel) { _, _ in
            loadAI()
        }
        .navigationTitle(pgnCore.gameState.metadata?.event ?? "Chess Game")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {
                        self.pgnCore.first()
                    },
                    label: {
                        Label("First", systemImage: "chevron.left.2")
                    }
                )
                .disabled(!self.pgnCore.gameState.hasPreviousMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {
                        self.pgnCore.previous()
                    },
                    label: {
                        Label("Previous", systemImage: "chevron.left")
                    }
                )
                .disabled(!self.pgnCore.gameState.hasPreviousMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {
                        self.pgnCore.next()
                    },
                    label: {
                        Label("Next", systemImage: "chevron.right")
                    }
                )
                .disabled(!self.pgnCore.gameState.hasNextMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {
                        self.pgnCore.last()
                    },
                    label: {
                        Label("Last", systemImage: "chevron.right.2")
                    }
                )
                .disabled(!self.pgnCore.gameState.hasNextMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    loadPGNFile()
                } label: {
                    // load
                    Label("Load", systemImage: "folder")
                }
            }
        }
    }

    func loadAI() {
        if let url = URL(string: openAIUrl) {
            chatModel.load(url: url, apiKey: openAIKey, model: .custom(model: openAIModel))
        }
    }
}

extension ContentView {
    func loadPGNFile() {
        // open ns Open panel
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.pgn]

        panel.begin { result in
            if result == .OK {
                guard let url = panel.url else { return }
                _ = self.pgnCore.load(from: url)
            }
        }
    }

    func loadChat() {
        guard let metadata = pgnCore.gameState.metadata else { return }
        // fetch chat
        let id = metadata.id
        var query = FetchDescriptor<Chat>(predicate: #Predicate { $0.gameId == id })
        query.fetchLimit = 1
        if let result = try? modelContext.fetch(query), let chatData = result.first {
            chat = chatData
        } else {
            // create a new chat
            let newChat = Chat(id: .init(), gameId: metadata.id, messages: [])
            chat = newChat
        }
    }
}

#Preview {
    ContentView()
}
