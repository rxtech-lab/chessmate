import XCTest

@testable import PgnCore

final class PgnCoreParsingTests: XCTestCase {
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

    func testLoadPgnFile() throws {
        // Create an instance of PgnCore
        let pgnCore = PgnCore()

        // Get the URL for the test PGN file
        let fileURL = URL(filePath: "./Tests/PgnCoreTests/test.pgn")

        // Load the PGN file
        _ = pgnCore.load(from: fileURL)

        // verify two games are loaded
        XCTAssertEqual(pgnCore.games.count, 2, "Should have two games")
    }

    func testFirstMovesInPgn() throws {
        // Create an instance of PgnCore
        let pgnCore = PgnCore()

        // Load the PGN file and the first game
        _ = pgnCore.load(from: testFileURL)
        pgnCore.loadGame(game: pgnCore.games[0])

        // Check the first move - 1.e2 -> e4 (White)
        pgnCore.next()
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 1, "Should be at first move")
        XCTAssertNil(pgnCore.gameState.piece(at: "e2"), "White pawn should have moved from e2")
        XCTAssertNotNil(pgnCore.gameState.piece(at: "e4"), "White pawn should be at e4")

        // 1. c7 -> c5 (Black)
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 1, "Should be at first move")
        XCTAssertNil(pgnCore.gameState.piece(at: "c7"), "Black pawn should have moved from c7")
        XCTAssertNotNil(pgnCore.gameState.piece(at: "c5"), "Black pawn should be at c5")

        // Move to the next position - 2.Ng1 -> Nf3 (White)
        pgnCore.next()
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 2, "Should be at second move")
        XCTAssertNil(pgnCore.gameState.piece(at: "g1"), "White knight should have moved from g1")
        XCTAssertNotNil(pgnCore.gameState.piece(at: "f3"), "White knight should be at f3")

        // 2. a7 -> a6 (Black)
        XCTAssertNil(pgnCore.gameState.piece(at: "a7"), "Black pawn should have moved from a7")
        XCTAssertNotNil(pgnCore.gameState.piece(at: "a6"), "Black pawn should be at a6")

        // move back
        pgnCore.previous()
        XCTAssertEqual(pgnCore.gameState.currentMoveIndex, 1, "Should be at first move")
        XCTAssertNotNil(pgnCore.gameState.piece(at: "a7"), "Black pawn should be at a7")
        XCTAssertNil(pgnCore.gameState.piece(at: "a6"), "Black pawn should have moved from a6")

        XCTAssertNotNil(pgnCore.gameState.piece(at: "g1"), "White knight should not be at g1")
        XCTAssertNil(pgnCore.gameState.piece(at: "f3"), "White knight should not be at f3")
    }
}
