import Foundation
import SwiftUI

/// Configuration for chess piece images and board appearance
public struct ChessBoardConfig {
    /// URLs for white chess pieces
    public struct WhitePieces {
        public let king: URL
        public let queen: URL
        public let rook: URL
        public let bishop: URL
        public let knight: URL
        public let pawn: URL
    }

    /// URLs for black chess pieces
    public struct BlackPieces {
        public let king: URL
        public let queen: URL
        public let rook: URL
        public let bishop: URL
        public let knight: URL
        public let pawn: URL
    }

    /// The URLs for white pieces
    public let whitePieces: WhitePieces

    /// The URLs for black pieces
    public let blackPieces: BlackPieces

    /// The color for light squares
    public let lightSquareColor: Color

    /// The color for dark squares
    public let darkSquareColor: Color

    /// The size of each square in points
    public let squareSize: CGFloat

    public init(
        whitePieces: WhitePieces,
        blackPieces: BlackPieces,
        lightSquareColor: Color = Color(red: 0.9, green: 0.9, blue: 0.8),
        darkSquareColor: Color = Color(red: 0.6, green: 0.6, blue: 0.5),
        squareSize: CGFloat = 60
    ) {
        self.whitePieces = whitePieces
        self.blackPieces = blackPieces
        self.lightSquareColor = lightSquareColor
        self.darkSquareColor = darkSquareColor
        self.squareSize = squareSize
    }
}
