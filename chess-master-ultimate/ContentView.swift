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
    @AppStorage("openAIModel") var currentModel: String = ""

    @State private var chat: Chat? = nil
    @State private var game: Game? = nil

    var body: some View {
        NavigationSplitView(
            sidebar: {
                GamesList(selectedGame: $game)
                    .frame(minWidth: 100)
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
                    .frame(minWidth: 500)
                }
            },
            detail: {
                if let chat = chat {
                    ChatListView(chat: chat, gameState: pgnCore.gameState)
                        .frame(minWidth: 300)
                }
            }
        )
        .onChange(of: game) { _, newGame in
            guard let newGame = newGame else { return }
            loadChat(game: newGame)
        }
        .task {
            loadAI()
        }
        .onChange(of: openAIKey) { _, _ in
            loadAI()
        }
        .onChange(of: openAIUrl) { _, _ in
            loadAI()
        }
        .onChange(of: currentModel) { _, _ in
            loadAI()
        }
        .navigationTitle(game?.summary ?? "Chess Game")
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
            chatModel.load(url: url, apiKey: openAIKey, model: .custom(model: currentModel))
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

    func loadChat(game: Game) {
        // fetch chat
        let id = game.id
        var query = FetchDescriptor<Chat>(predicate: #Predicate { $0.gameId == id })
        query.fetchLimit = 1
        if let result = try? modelContext.fetch(query), let chatData = result.first {
            chat = chatData
        } else {
            // create a new chat
            let newChat = Chat(id: .init(), gameId: game.id, messages: [])
            chat = newChat
        }
    }
}

#Preview {
    ContentView()
}
