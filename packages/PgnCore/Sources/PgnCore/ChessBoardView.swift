import SwiftUI

/// A view that represents a chess board with pieces
public struct ChessBoardView: View {
    /// The configuration for the chess board
    private let config: ChessBoardConfig

    /// The current state of the game
    private let gameState: GameState

    /// Callback when a square is tapped
    private let onSquareTap: (String) -> Void

    /// The currently selected square
    @State private var selectedSquare: String?

    public init(
        config: ChessBoardConfig,
        gameState: GameState,
        onSquareTap: @escaping (String) -> Void
    ) {
        self.config = config
        self.gameState = gameState
        self.onSquareTap = onSquareTap
    }

    /// Gets the appropriate piece image for a given square
    private func pieceImage(for square: String) -> Image? {
        guard let piece = gameState.piece(at: square) else { return nil }

        switch (piece.color, piece.type) {
        case (.white, .king): return config.whitePieces.king
        case (.white, .queen): return config.whitePieces.queen
        case (.white, .rook): return config.whitePieces.rook
        case (.white, .bishop): return config.whitePieces.bishop
        case (.white, .knight): return config.whitePieces.knight
        case (.white, .pawn): return config.whitePieces.pawn
        case (.black, .king): return config.blackPieces.king
        case (.black, .queen): return config.blackPieces.queen
        case (.black, .rook): return config.blackPieces.rook
        case (.black, .bishop): return config.blackPieces.bishop
        case (.black, .knight): return config.blackPieces.knight
        case (.black, .pawn): return config.blackPieces.pawn
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach((0...7).reversed(), id: \.self) { rank in
                HStack(spacing: 0) {
                    ForEach(0...7, id: \.self) { file in
                        let square = "\(["a", "b", "c", "d", "e", "f", "g", "h"][file])\(rank + 1)"
                        SquareView(
                            square: square,
                            isLight: (file + rank) % 2 == 0,
                            config: config,
                            isSelected: selectedSquare == square,
                            onTap: {
                                selectedSquare = square
                                onSquareTap(square)
                            },
                            pieceImage: pieceImage(for: square)
                        )
                    }
                }
            }
        }
        .frame(
            width: config.squareSize * 8,
            height: config.squareSize * 8
        )
    }
}

/// A view that represents a single square on the chess board
private struct SquareView: View {
    let square: String
    let isLight: Bool
    let config: ChessBoardConfig
    let isSelected: Bool
    let onTap: () -> Void
    let pieceImage: Image?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isLight ? config.lightSquareColor : config.darkSquareColor)
                .overlay(
                    Rectangle()
                        .stroke(Color.blue, lineWidth: isSelected ? 2 : 0)
                )

            if let pieceImage = pieceImage {
                pieceImage
                    .resizable()
                    .scaledToFit()
                    .padding(config.squareSize * 0.1)
            }

            Text(square)
                .font(.system(size: 10))
                .foregroundColor(isLight ? config.darkSquareColor : config.lightSquareColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(2)
        }
        .frame(width: config.squareSize, height: config.squareSize)
        .onTapGesture(perform: onTap)
    }
}
