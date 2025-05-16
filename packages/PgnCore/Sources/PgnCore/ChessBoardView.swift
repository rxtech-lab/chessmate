import SwiftUI

/// A view that represents a chess board with pieces
@MainActor
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
                            }
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

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isLight ? config.lightSquareColor : config.darkSquareColor)
                .overlay(
                    Rectangle()
                        .stroke(Color.blue, lineWidth: isSelected ? 2 : 0)
                )

            // TODO: Add piece image here based on the current game state
            // This will be implemented when we add piece position tracking

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

#Preview {
    // Example configuration with placeholder URLs
    let config = ChessBoardConfig(
        whitePieces: .init(
            king: URL(string: "https://example.com/wk.png")!,
            queen: URL(string: "https://example.com/wq.png")!,
            rook: URL(string: "https://example.com/wr.png")!,
            bishop: URL(string: "https://example.com/wb.png")!,
            knight: URL(string: "https://example.com/wn.png")!,
            pawn: URL(string: "https://example.com/wp.png")!
        ),
        blackPieces: .init(
            king: URL(string: "https://example.com/bk.png")!,
            queen: URL(string: "https://example.com/bq.png")!,
            rook: URL(string: "https://example.com/br.png")!,
            bishop: URL(string: "https://example.com/bb.png")!,
            knight: URL(string: "https://example.com/bn.png")!,
            pawn: URL(string: "https://example.com/bp.png")!
        )
    )

    return ChessBoardView(
        config: config,
        gameState: GameState(),
        onSquareTap: { square in
            print("Tapped square: \(square)")
        }
    )
}
