import XCTest

@testable import PgnCore

final class PgnCoreTests: XCTestCase {
    var pgnCore: PgnCore!
    var testFileURL: URL!

    override func setUp() {
        super.setUp()
        pgnCore = PgnCore()
        testFileURL = URL(filePath: "./Tests/PgnCoreTests/test.pgn")
    }

    override func tearDown() {
        pgnCore = nil
        testFileURL = nil
        super.tearDown()
    }

    func testInitialBoardSetup() throws {
        // Create a new game
        let pgnCore = PgnCore()

        // Verify that the board is set up correctly
        // Check pawns
        for file in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)2")?.type, .pawn,
                "White pawn should be at \(file)2")
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)2")?.color, .white,
                "Piece at \(file)2 should be white")
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)7")?.type, .pawn,
                "Black pawn should be at \(file)7")
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)7")?.color, .black,
                "Piece at \(file)7 should be black")
        }

        // Check back rank pieces
        let backRankPieces: [(String, PieceType)] = [
            ("a", .rook), ("b", .knight), ("c", .bishop), ("d", .queen),
            ("e", .king), ("f", .bishop), ("g", .knight), ("h", .rook),
        ]

        for (file, pieceType) in backRankPieces {
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)1")?.type, pieceType,
                "White \(pieceType) should be at \(file)1")
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)1")?.color, .white,
                "Piece at \(file)1 should be white")
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)8")?.type, pieceType,
                "Black \(pieceType) should be at \(file)8")
            XCTAssertEqual(
                pgnCore.gameState.piece(at: "\(file)8")?.color, .black,
                "Piece at \(file)8 should be black")
        }

        // Verify that other squares are empty
        for rank in 3...6 {
            for file in ["a", "b", "c", "d", "e", "f", "g", "h"] {
                XCTAssertNil(
                    pgnCore.gameState.piece(at: "\(file)\(rank)"),
                    "Square \(file)\(rank) should be empty")
            }
        }
    }
}
