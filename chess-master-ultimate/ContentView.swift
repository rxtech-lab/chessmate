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
    @State private var selectedIndex: Int = 0

    var body: some View {
        NavigationSplitView(sidebar: {
            GamesList()

        }, detail: {
            ChessBoardView(
                config: config,
                gameState: pgnCore.gameState,
                onSquareTap: { square in
                    print("Tapped square: \(square)")
                }
            )
        })
        .navigationTitle(pgnCore.gameState.metadata?.event ?? "Chess Game")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Previous") {
                    pgnCore.previous()
                }
                .disabled(!pgnCore.gameState.hasPreviousMove)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Next") {
                    pgnCore.next()
                }
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
