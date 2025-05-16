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

    func testNavigationMethods() throws {
        // Load a test game first
        _ = pgnCore.load(from: testFileURL)

        // Test first()
        pgnCore.first()
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 0, "Should be at first move")

        // Test next()
        pgnCore.next()
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 1, "Should move to second move")

        // Test previous()
        pgnCore.previous()
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 0, "Should move back to first move")

        // Test last()
        pgnCore.last()
        XCTAssertEqual(
            pgnCore.gameState.currentMoveIndex, pgnCore.gameState.historyData.count - 1,
            "Should be at last move")

        // Test boundary conditions
        pgnCore.first()
        pgnCore.previous()  // Should not go below 0
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 0, "Should stay at first move")

        pgnCore.last()
        pgnCore.next()  // Should not go beyond last move
        XCTAssertEqual(
            pgnCore.gameState.currentMoveIndex, pgnCore.gameState.historyData.count - 1,
            "Should stay at last move")
    }

    func testMakeMove() throws {
        // Create a new game without loading a file
        let whitePlayer = Player(id: "1", name: "White", color: .white)
        let blackPlayer = Player(id: "2", name: "Black", color: .black)
        pgnCore.gameState.whitePlayer = whitePlayer
        pgnCore.gameState.blackPlayer = blackPlayer
        pgnCore.gameState.isLoaded = false

        // Test making a valid move
        pgnCore.gameState.isLoaded = true
        try pgnCore.makeMove(as: whitePlayer, from: "e2", to: "e4")
        XCTAssertEqual(pgnCore.gameState.historyData.count, 1, "Should have one move")
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 0, "Should be at the first move")
        XCTAssertEqual(
            pgnCore.gameState.historyData[0].whiteMove, "e2e4", "Should record white's move")

        // Test making a move when game is not loaded
        pgnCore.gameState.isLoaded = false
        XCTAssertThrowsError(try pgnCore.makeMove(as: blackPlayer, from: "e7", to: "e5")) { error in
            XCTAssertEqual(error as? PgnError, .gameNotLoaded, "Should throw gameNotLoaded error")
        }
    }

    func testGetPreviousMoves() throws {
        // Create a new game without loading a file
        let whitePlayer = Player(id: "1", name: "White", color: .white)
        let blackPlayer = Player(id: "2", name: "Black", color: .black)
        pgnCore.gameState.whitePlayer = whitePlayer
        pgnCore.gameState.blackPlayer = blackPlayer
        pgnCore.gameState.isLoaded = true
        pgnCore.gameState.metadata = GameMetadata(
            event: "Test Game",
            site: "Test Site",
            date: "2024.05.16",
            round: "1",
            white: "White",
            black: "Black",
            result: "*"
        )

        // Make some moves to create a game history
        try pgnCore.makeMove(as: whitePlayer, from: "e2", to: "e4")
        try pgnCore.makeMove(as: blackPlayer, from: "e7", to: "e5")
        try pgnCore.makeMove(as: whitePlayer, from: "g1", to: "f3")
        try pgnCore.makeMove(as: blackPlayer, from: "b8", to: "c6")
        try pgnCore.makeMove(as: whitePlayer, from: "f1", to: "b5")
        try pgnCore.makeMove(as: blackPlayer, from: "a7", to: "a6")

        // Move to a position in the middle of the game
        pgnCore.gameState.currentMoveIndex = 5

        // Test getting previous moves
        let previousMoves = pgnCore.getPreviousMoves(num: 3)
        XCTAssertEqual(previousMoves.count, 3, "Should return moves from index 3 to 5 inclusive")

        // Test getting more moves than available
        pgnCore.gameState.currentMoveIndex = 2
        let allPreviousMoves = pgnCore.getPreviousMoves(num: 5)
        XCTAssertEqual(allPreviousMoves.count, 3, "Should return moves from index 0 to 2 inclusive")

        // Test getting moves when game is not loaded
        pgnCore.gameState.isLoaded = false
        let noMoves = pgnCore.getPreviousMoves(num: 3)
        XCTAssertTrue(noMoves.isEmpty, "Should return empty array when game is not loaded")
    }

    func testSaveGame() throws {
        // Load a test game
        _ = pgnCore.load(from: testFileURL)

        // Create a temporary file URL for saving
        let tempDir = FileManager.default.temporaryDirectory
        let saveURL = tempDir.appendingPathComponent("saved_game.pgn")

        // Save the game
        pgnCore.save(to: saveURL)

        // Verify the file was created
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: saveURL.path), "Saved file should exist")

        // Load the saved file and verify content
        let savedContent = try String(contentsOf: saveURL, encoding: .utf8)
        XCTAssertFalse(savedContent.isEmpty, "Saved file should not be empty")

        // Verify metadata is present in saved file
        XCTAssertTrue(savedContent.contains("[White"), "Saved file should contain White player")
        XCTAssertTrue(savedContent.contains("[Black"), "Saved file should contain Black player")

        // Clean up
        try? FileManager.default.removeItem(at: saveURL)
    }

    @MainActor
    func testGameStateConsistency() throws {
        // Create a new game without loading a file
        let whitePlayer = Player(id: "1", name: "White", color: .white)
        let blackPlayer = Player(id: "2", name: "Black", color: .black)
        pgnCore.gameState.whitePlayer = whitePlayer
        pgnCore.gameState.blackPlayer = blackPlayer
        pgnCore.gameState.isLoaded = true
        pgnCore.gameState.metadata = GameMetadata(
            event: "Test Game",
            site: "Test Site",
            date: "2024.05.16",
            round: "1",
            white: "White",
            black: "Black",
            result: "*"
        )

        // Make a series of moves
        try pgnCore.makeMove(as: whitePlayer, from: "e2", to: "e4")
        try pgnCore.makeMove(as: blackPlayer, from: "e7", to: "e5")

        // Verify move history
        XCTAssertEqual(pgnCore.gameState.historyData.count, 2, "Should have two moves")
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 1, "Should be at the second move")

        // Verify move data
        let firstMove = pgnCore.gameState.historyData[0]
        XCTAssertEqual(firstMove.whiteMove, "e2e4", "First move should be e2e4")
        XCTAssertNil(firstMove.blackMove, "First move should not have black move")

        let secondMove = pgnCore.gameState.historyData[1]
        XCTAssertEqual(secondMove.blackMove, "e7e5", "Second move should be e7e5")
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
