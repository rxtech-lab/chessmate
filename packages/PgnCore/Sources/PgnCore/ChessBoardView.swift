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

    /// Whether the board should auto-size to available space
    private let autoSize: Bool

    public init(
        config: ChessBoardConfig,
        gameState: GameState,
        onSquareTap: @escaping (String) -> Void,
        autoSize: Bool = false
    ) {
        self.config = config
        self.gameState = gameState
        self.onSquareTap = onSquareTap
        self.autoSize = autoSize
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
        if autoSize {
            GeometryReader { geometry in
                let minDimension = min(geometry.size.width, geometry.size.height)
                let squareSize = minDimension / 8

                boardContent(squareSize: squareSize)
                    .frame(width: squareSize * 8, height: squareSize * 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            boardContent(squareSize: config.squareSize)
                .frame(
                    width: config.squareSize * 8,
                    height: config.squareSize * 8
                )
        }
    }

    private func boardContent(squareSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach((0...7).reversed(), id: \.self) { rank in
                HStack(spacing: 0) {
                    ForEach(0...7, id: \.self) { file in
                        let square = "\(["a", "b", "c", "d", "e", "f", "g", "h"][file])\(rank + 1)"
                        SquareView(
                            square: square,
                            isLight: (file + rank) % 2 == 0,
                            config: config,
                            squareSize: squareSize,
                            isSelected: selectedSquare == square,
                            isSourceHighlighted: gameState.highlightedFromSquare == square,
                            isDestinationHighlighted: gameState.highlightedToSquare == square,
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
    }
}

/// A view that represents a single square on the chess board
private struct SquareView: View {
    let square: String
    let isLight: Bool
    let config: ChessBoardConfig
    let squareSize: CGFloat
    let isSelected: Bool
    let isSourceHighlighted: Bool
    let isDestinationHighlighted: Bool
    let onTap: () -> Void
    let pieceImage: Image?

    var body: some View {
        ZStack {
            // Base square color
            Rectangle()
                .fill(isLight ? config.lightSquareColor : config.darkSquareColor)

            // Move highlight for source square
            if isSourceHighlighted {
                Rectangle()
                    .fill(config.sourceHighlightColor)
            }

            // Move highlight for destination square
            if isDestinationHighlighted {
                Rectangle()
                    .fill(config.destinationHighlightColor)
            }

            // Selection highlight
            if isSelected {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
            }

            // Piece image
            if let pieceImage = pieceImage {
                pieceImage
                    .resizable()
                    .scaledToFit()
                    .padding(squareSize * 0.1)
            }

            // Square label (for debugging)
            Text(square)
                .font(.system(size: 10))
                .foregroundColor(isLight ? config.darkSquareColor : config.lightSquareColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(2)
        }
        .frame(width: squareSize, height: squareSize)
        .onTapGesture(perform: onTap)
    }
}
