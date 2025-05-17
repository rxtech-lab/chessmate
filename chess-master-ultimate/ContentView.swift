//
//  ContentView.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/16/25.
//

import PgnCore
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

    var body: some View {
        NavigationSplitView(sidebar: {
            GamesList()

        }, content: {
            if pgnCore.gameState.metadata == nil {
                Text("No game loaded")
                    .foregroundStyle(.secondary)
            } else {
                VStack {
                    ChessBoardView(
                        config: config,
                        gameState: pgnCore.gameState,
                        onSquareTap: { square in
                            print("Tapped square: \(square)")
                        }
                    )
                    HStack {
                        Text("Move: \(pgnCore.gameState.currentMoveIndex)")
                    }
                }
                .frame(minWidth: 450)
            }
        }, detail: {
            Text("ChatView")
                .frame(minWidth: 200, maxWidth: 300)
        })
        .navigationTitle(pgnCore.gameState.metadata?.event ?? "Chess Game")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    pgnCore.first()
                }, label: {
                    Label("First", systemImage: "chevron.left.2")
                })
                .disabled(!pgnCore.gameState.hasPreviousMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    pgnCore.previous()
                }, label: {
                    Label("Previous", systemImage: "chevron.left")
                })
                .disabled(!pgnCore.gameState.hasPreviousMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    pgnCore.next()
                }, label: {
                    Label("Next", systemImage: "chevron.right")
                })
                .disabled(!pgnCore.gameState.hasNextMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    pgnCore.last()
                }, label: {
                    Label("Last", systemImage: "chevron.right.2")
                })
                .disabled(!pgnCore.gameState.hasNextMove)
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
                _ = pgnCore.load(from: url)
            }
        }
    }
}

#Preview {
    ContentView()
}
