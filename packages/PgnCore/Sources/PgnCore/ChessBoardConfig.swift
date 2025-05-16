import Foundation
import SwiftUI

/// Configuration for chess piece images and board appearance
public struct ChessBoardConfig {
    /// Images for white chess pieces
    public struct WhitePieces {
        public let king: Image
        public let queen: Image
        public let rook: Image
        public let bishop: Image
        public let knight: Image
        public let pawn: Image

        public init(
            king: Image, queen: Image, rook: Image, bishop: Image, knight: Image, pawn: Image
        ) {
            self.king = king
            self.queen = queen
            self.rook = rook
            self.bishop = bishop
            self.knight = knight
            self.pawn = pawn
        }
    }

    /// Images for black chess pieces
    public struct BlackPieces {
        public let king: Image
        public let queen: Image
        public let rook: Image
        public let bishop: Image
        public let knight: Image
        public let pawn: Image

        public init(
            king: Image, queen: Image, rook: Image, bishop: Image, knight: Image, pawn: Image
        ) {
            self.king = king
            self.queen = queen
            self.rook = rook
            self.bishop = bishop
            self.knight = knight
            self.pawn = pawn
        }
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

    /// The color for highlighting the source square of a move
    public let sourceHighlightColor: Color

    /// The color for highlighting the destination square of a move
    public let destinationHighlightColor: Color

    public init(
        whitePieces: WhitePieces,
        blackPieces: BlackPieces,
        lightSquareColor: Color = Color(red: 0.9, green: 0.9, blue: 0.8),
        darkSquareColor: Color = Color(red: 0.6, green: 0.6, blue: 0.5),
        squareSize: CGFloat = 60,
        sourceHighlightColor: Color = Color.yellow.opacity(0.5),
        destinationHighlightColor: Color = Color.green.opacity(0.5)
    ) {
        self.whitePieces = whitePieces
        self.blackPieces = blackPieces
        self.lightSquareColor = lightSquareColor
        self.darkSquareColor = darkSquareColor
        self.squareSize = squareSize
        self.sourceHighlightColor = sourceHighlightColor
        self.destinationHighlightColor = destinationHighlightColor
    }
}
