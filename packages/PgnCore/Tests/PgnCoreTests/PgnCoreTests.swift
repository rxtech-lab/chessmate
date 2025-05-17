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

    func testGetPreviousMoves() {
        // Create a sample game state with metadata and some moves
        let metadata = GameMetadata(
            event: "Test Event",
            site: "Test Site",
            date: "2023.01.01",
            round: "1",
            white: "Player White",
            black: "Player Black",
            result: "1-0"
        )

        let moves = [
            MoveData(
                moveNumber: 1,
                whiteMove: "e4",
                blackMove: "e5",
                moveText: "1. e4 e5",
                comment: nil
            ),
            MoveData(
                moveNumber: 2,
                whiteMove: "Nf3",
                blackMove: "Nc6",
                moveText: "2. Nf3 Nc6",
                comment: nil
            ),
            MoveData(
                moveNumber: 3,
                whiteMove: "Bc4",
                blackMove: "Nf6",
                moveText: "3. Bc4 Nf6",
                comment: nil
            ),
        ]

        // Test with full moves (after black's move)
        pgnCore.gameState = GameState(
            metadata: metadata,
            historyData: moves,
            currentMoveIndex: 2.0,  // After black's move in move 2
            pgnContent: "",
            isLoaded: true
        )

        var expected = """
            [Event "Test Event"]
            [Site "Test Site"]
            [Date "2023.01.01"]
            [Round "1"]
            [White "Player White"]
            [Black "Player Black"]
            [Result "1-0"]

            1. e4 e5 2. Nf3 Nc6
            """

        XCTAssertEqual(pgnCore.gameState.getPreviousMoves(), expected)

        // Test with half move (after white's move)
        pgnCore.gameState.currentMoveIndex = 2.5  // After white's move in move 3

        expected = """
            [Event "Test Event"]
            [Site "Test Site"]
            [Date "2023.01.01"]
            [Round "1"]
            [White "Player White"]
            [Black "Player Black"]
            [Result "1-0"]

            1. e4 e5 2. Nf3 Nc6 3. Bc4
            """

        XCTAssertEqual(pgnCore.gameState.getPreviousMoves(), expected)

        // Test with initial position
        pgnCore.gameState.currentMoveIndex = 0.0

        expected = """
            [Event "Test Event"]
            [Site "Test Site"]
            [Date "2023.01.01"]
            [Round "1"]
            [White "Player White"]
            [Black "Player Black"]
            [Result "1-0"]
            """

        XCTAssertEqual(pgnCore.gameState.getPreviousMoves(), expected)
    }
}
