import Foundation
import SwiftUI

/// Represents a single move in the game history
public struct MoveData {
    /// The move number in the game
    var moveNumber: Int

    /// The white player's move
    var whiteMove: String?

    /// The black player's move
    var blackMove: String?

    /// The full move text (e.g., "1. e4 e5")
    var moveText: String

    /// Any comments or annotations for this move
    var comment: String?
}

/// Represents the metadata of a chess game
public struct GameMetadata {
    /// Event name (e.g., "FIDE World Championship")
    public var event: String?

    /// Site where the game was played
    public var site: String?

    /// Date when the game was played
    public var date: String?

    /// Round number in the tournament
    public var round: String?

    /// White player's name
    public var white: String?

    /// Black player's name
    public var black: String?

    /// Result of the game (1-0, 0-1, 1/2-1/2, or *)
    public var result: String?
}

/// Represents a chess piece
public struct Piece {
    public let color: Side
    public let type: PieceType

    public init(color: Side, type: PieceType) {
        self.color = color
        self.type = type
    }
}

/// Represents the type of a chess piece
public enum PieceType {
    case king
    case queen
    case rook
    case bishop
    case knight
    case pawn
}

// GameState stores the current game state including moves, players, and current position
public struct GameState {
    /// The metadata of the game
    public internal(set) var metadata: GameMetadata?

    /// The list of moves in the game
    var historyData: [MoveData] = []

    /// Current position in the move list (0-based index)
    var currentMoveIndex: Int = 0

    /// The white player
    var whitePlayer: Player?

    /// The black player
    var blackPlayer: Player?

    /// The raw PGN content
    var pgnContent: String = ""

    /// Whether the game is loaded
    var isLoaded: Bool = false

    /// The current board position
    var board: [String: Piece] = [:]

    public var hasPreviousMove: Bool {
        return currentMoveIndex > 0
    }

    public var hasNextMove: Bool {
        return currentMoveIndex < historyData.count - 1
    }

    /// Gets the piece at a given square
    public func piece(at square: String) -> Piece? {
        return board[square]
    }

    /// Sets a piece at a given square
    public mutating func setPiece(_ piece: Piece?, at square: String) {
        if let piece = piece {
            board[square] = piece
        } else {
            board.removeValue(forKey: square)
        }
    }

    public init(
        metadata: GameMetadata? = nil, historyData: [MoveData], currentMoveIndex: Int,
        whitePlayer: Player? = nil, blackPlayer: Player? = nil, pgnContent: String, isLoaded: Bool
    ) {
        self.metadata = metadata
        self.historyData = historyData
        self.currentMoveIndex = currentMoveIndex
        self.whitePlayer = whitePlayer
        self.blackPlayer = blackPlayer
        self.pgnContent = pgnContent
        self.isLoaded = isLoaded
    }

    public init() {
        self.metadata = GameMetadata()
        self.historyData = []
        self.currentMoveIndex = -1
        self.whitePlayer = nil
        self.blackPlayer = nil
        self.pgnContent = ""
        self.isLoaded = false
    }
}

@Observable
public class PgnCore: PgnCoreProtocol {
    /// The current state of the game
    public var gameState: GameState

    /// List of all games parsed from the PGN file
    public var games: [Game] = []

    /// Currently selected game index
    public var currentGameIndex: Int = 0

    /// The configuration for the chess board
    public var boardConfig: ChessBoardConfig?

    public init() {
        self.gameState = GameState()
        setupInitialBoard()
    }

    /// Sets up the initial board position with all pieces in their starting positions
    private func setupInitialBoard() {
        // Clear the board
        gameState.board = [:]

        // Set up pawns
        for file in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            gameState.setPiece(Piece(color: .white, type: .pawn), at: "\(file)2")
            gameState.setPiece(Piece(color: .black, type: .pawn), at: "\(file)7")
        }

        // Set up other pieces
        let backRankPieces: [(String, PieceType)] = [
            ("a", .rook), ("b", .knight), ("c", .bishop), ("d", .queen),
            ("e", .king), ("f", .bishop), ("g", .knight), ("h", .rook),
        ]

        for (file, pieceType) in backRankPieces {
            gameState.setPiece(Piece(color: .white, type: pieceType), at: "\(file)1")
            gameState.setPiece(Piece(color: .black, type: pieceType), at: "\(file)8")
        }
    }

    /// Sets the configuration for the chess board
    /// - Parameter config: The configuration to use for the chess board
    public func setBoardConfig(_ config: ChessBoardConfig) {
        boardConfig = config
    }

    /// Loads a PGN file from the given URL and parses its content
    /// - Parameter file: The URL of the PGN file to load
    /// - Returns: The raw content of the PGN file
    public func load(from file: URL) -> String {
        do {
            let content = try String(contentsOf: file, encoding: .utf8)
            games = parseMultipleGamesFromPgn(content)

            return content
        } catch {
            print("Error loading PGN file: \(error)")
            return ""
        }
    }

    /// Loads a specific game from the parsed games list
    /// - Parameter index: The index of the game to load
    public func loadGame(game: Game) {
        // Update game state
        gameState = GameState(
            metadata: game.metadata,
            historyData: game.moves,
            currentMoveIndex: 0,
            whitePlayer: game.metadata.white != nil
                ? Player(id: UUID().uuidString, name: game.metadata.white!, color: .white) : nil,
            blackPlayer: game.metadata.black != nil
                ? Player(id: UUID().uuidString, name: game.metadata.black!, color: .black) : nil,
            pgnContent: game.rawContent,
            isLoaded: true
        )

        // Reset the board to initial position
        setupInitialBoard()
    }

    /// Makes a move in the game
    /// - Parameters:
    ///   - player: The player making the move
    ///   - from: The starting position of the piece
    ///   - to: The destination position of the piece
    /// - Throws: An error if the move is invalid
    public func makeMove(as player: Player, from: String, to: String) throws {
        throw PgnError.notImplemented
    }

    /// Moves to the next position in the game
    public func next() {
        guard gameState.currentMoveIndex < gameState.historyData.count - 1 else { return }

        // Get the next move
        gameState.currentMoveIndex += 1
        let move = gameState.historyData[gameState.currentMoveIndex - 1]

        // Apply the move
        applyMove(move)
    }

    /// Moves to the previous position in the game
    public func previous() {
        // reset the board
        setupInitialBoard()
        guard gameState.currentMoveIndex > 0 else { return }
        gameState.currentMoveIndex -= 1
        // apply the previous move
        for i in 0..<gameState.currentMoveIndex {
            applyMove(gameState.historyData[i])
        }
    }

    /// Moves to the first position in the game
    public func first() {
        // If already at first move or before, do nothing
        if gameState.currentMoveIndex <= 0 {
            gameState.currentMoveIndex = 0
            return
        }

        // Reset board to initial position
        setupInitialBoard()
        gameState.currentMoveIndex = 0

        // Apply the first move if it exists
        if !gameState.historyData.isEmpty {
            let move = gameState.historyData[0]
            applyMove(move)
        }
    }

    /// Moves to the last position in the game
    public func last() {
        // If already at last move, do nothing
        if gameState.currentMoveIndex == gameState.historyData.count - 1 {
            return
        }

        // If we're near the end, just use next() to get there efficiently
        if gameState.historyData.count - gameState.currentMoveIndex < 5 {
            while gameState.currentMoveIndex < gameState.historyData.count - 1 {
                next()
            }
            return
        }

        // Otherwise, reset and replay all moves (for distant jumps)
        setupInitialBoard()

        // Apply all moves
        for i in 0..<gameState.historyData.count {
            let move = gameState.historyData[i]
            applyMove(move)
        }

        gameState.currentMoveIndex = gameState.historyData.count - 1
    }

    /// Saves the current game state to a PGN file
    /// - Parameter file: The URL where the PGN file should be saved
    public func save(to file: URL) {
        var pgnContent = ""

        // Write metadata
        if let metadata = gameState.metadata {
            if let event = metadata.event { pgnContent += "[Event \"\(event)\"]\n" }
            if let site = metadata.site { pgnContent += "[Site \"\(site)\"]\n" }
            if let date = metadata.date { pgnContent += "[Date \"\(date)\"]\n" }
            if let round = metadata.round { pgnContent += "[Round \"\(round)\"]\n" }
            if let white = metadata.white { pgnContent += "[White \"\(white)\"]\n" }
            if let black = metadata.black { pgnContent += "[Black \"\(black)\"]\n" }
            if let result = metadata.result { pgnContent += "[Result \"\(result)\"]\n" }
            pgnContent += "\n"
        }

        // Write moves
        for move in gameState.historyData {
            pgnContent += move.moveText + " "
        }

        // Write result if available
        if let result = gameState.metadata?.result {
            pgnContent += result
        }

        do {
            try pgnContent.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving PGN file: \(error)")
        }
    }

    /// Gets the previous n moves from the current position
    /// - Parameter moves: The number of previous moves to retrieve
    /// - Returns: An array of MoveData containing the previous moves, or an empty array if no moves are available
    public func getPreviousMoves(num moves: Int) -> [MoveData] {
        guard gameState.isLoaded, gameState.currentMoveIndex >= 0 else {
            return []
        }

        let startIndex = max(0, gameState.currentMoveIndex - moves + 1)
        let endIndex = gameState.currentMoveIndex + 1

        return Array(gameState.historyData[startIndex..<endIndex])
    }

    // MARK: - Private Methods

    /// Parses a PGN file that may contain multiple games
    /// - Parameter content: The PGN content to parse
    /// - Returns: An array of Game objects
    private func parseMultipleGamesFromPgn(_ content: String) -> [Game] {
        var games: [Game] = []

        // Split the content by game separators
        // Games in PGN format are typically separated by a blank line after the result
        // followed by the metadata tag of the next game

        // First, normalize line endings to ensure consistent handling
        let normalizedContent = content.replacingOccurrences(of: "\r\n", with: "\n")

        // Split games using a regex pattern to find game boundaries
        // This captures sequences that look like a game result followed by a blank line and a new tag
        let gameRegex = try? NSRegularExpression(
            pattern: "(\\s+)(1-0|0-1|1/2-1/2|\\*)\\s*?(\\n\\s*\\n\\s*\\[|$)")

        if let gameRegex = gameRegex {
            // Find all matches of the game separator pattern
            let nsContent = normalizedContent as NSString
            let matches = gameRegex.matches(
                in: normalizedContent, range: NSRange(location: 0, length: nsContent.length)
            )

            // If we have matches, use them to split the content
            if !matches.isEmpty {
                var lastEndIndex = 0

                for match in matches {
                    // Get the range from the beginning to just after the result
                    let gameEndRange = match.range
                    let gameEndIndex = gameEndRange.location + gameEndRange.length

                    // Extract the complete game content
                    let gameRange = NSRange(
                        location: lastEndIndex,
                        length: gameEndRange.location + gameEndRange.length - lastEndIndex
                    )
                    let gameContent = nsContent.substring(with: gameRange)

                    // Parse the game and add it to the collection if it's not empty
                    if !gameContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let (metadata, moves) = parsePgnContent(gameContent)
                        let game = Game(
                            metadata: metadata,
                            moves: moves,
                            rawContent: gameContent
                        )
                        games.append(game)
                    }

                    // Update the starting index for the next game
                    // If this was a match that ended with a new tag, we need to find the actual start of the next game
                    if gameEndIndex < nsContent.length
                        && nsContent.substring(with: NSRange(location: gameEndIndex - 1, length: 1))
                            == "["
                    {
                        lastEndIndex = gameEndRange.location + gameEndRange.length - 1
                    } else {
                        lastEndIndex = gameEndRange.location + gameEndRange.length
                    }
                }

                // Check if there's more content after the last match (shouldn't happen with proper PGN files)
                if lastEndIndex < nsContent.length {
                    let remainingContent = nsContent.substring(from: lastEndIndex)
                    if !remainingContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let (metadata, moves) = parsePgnContent(String(remainingContent))
                        let game = Game(
                            metadata: metadata,
                            moves: moves,
                            rawContent: String(remainingContent)
                        )
                        games.append(game)
                    }
                }
            } else {
                // No matches found, try to parse the entire content as a single game
                let (metadata, moves) = parsePgnContent(normalizedContent)
                let game = Game(
                    metadata: metadata,
                    moves: moves,
                    rawContent: normalizedContent
                )
                games.append(game)
            }
        } else {
            // Fallback to a simpler approach if regex creation fails
            let parts = normalizedContent.components(separatedBy: "\n\n[")
            if let firstPart = parts.first, firstPart.hasPrefix("[") {
                let (metadata, moves) = parsePgnContent(firstPart)
                games.append(
                    Game(
                        metadata: metadata,
                        moves: moves,
                        rawContent: firstPart
                    ))

                for i in 1..<parts.count {
                    let gamePart = "[" + parts[i]
                    let (metadata, moves) = parsePgnContent(gamePart)
                    games.append(
                        Game(
                            metadata: metadata,
                            moves: moves,
                            rawContent: gamePart
                        ))
                }
            }
        }

        return games
    }

    /// Parses the PGN content and returns metadata and moves
    /// - Parameter content: The PGN content to parse
    /// - Returns: A tuple containing the game metadata and list of moves
    private func parsePgnContent(_ content: String) -> (GameMetadata, [MoveData]) {
        var metadata = GameMetadata(
            event: nil,
            site: nil,
            date: nil,
            round: nil,
            white: nil,
            black: nil,
            result: nil
        )
        var moves: [MoveData] = []

        // Split content into lines
        let lines = content.components(separatedBy: .newlines)

        // We'll collect move text sections
        var moveTextSection = ""
        var parsingMoves = false

        // Parse metadata (lines starting with [)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty {
                // Empty line might indicate transition from metadata to move section
                if !parsingMoves && !moveTextSection.isEmpty {
                    parsingMoves = true
                }
                continue
            }

            if trimmedLine.hasPrefix("[") && trimmedLine.hasSuffix("]") {
                // Parse metadata tag
                let tagContent = trimmedLine.dropFirst().dropLast()
                let components = tagContent.split(separator: " ", maxSplits: 1)
                if components.count == 2 {
                    let tag = String(components[0])
                    let value = String(components[1]).trimmingCharacters(
                        in: CharacterSet(charactersIn: "\""))

                    switch tag {
                    case "Event": metadata.event = value
                    case "Site": metadata.site = value
                    case "Date": metadata.date = value
                    case "Round": metadata.round = value
                    case "White": metadata.white = value
                    case "Black": metadata.black = value
                    case "Result": metadata.result = value
                    default: break
                    }
                }
            } else {
                // This is part of the moves section
                moveTextSection += trimmedLine + " "
                parsingMoves = true
            }
        }

        // Now parse the collected moves section
        if !moveTextSection.isEmpty {
            // Clean up the move text (remove result if present)
            let resultPatterns = ["1-0", "0-1", "1/2-1/2", "*"]
            var cleanMoveText = moveTextSection
            for result in resultPatterns {
                cleanMoveText = cleanMoveText.replacingOccurrences(of: result, with: "")
            }

            // Split the move text by move numbers (like "1.", "2.", etc.)
            let moveComponents = cleanMoveText.components(separatedBy: .whitespaces)

            var currentMoveNumber = 1
            var currentWhiteMove: String?
            var currentBlackMove: String?

            for component in moveComponents {
                let trimmedComponent = component.trimmingCharacters(in: .whitespaces)
                if trimmedComponent.isEmpty { continue }

                // Check if this is a move number indicator
                if trimmedComponent.range(of: #"^\d+\.$"#, options: .regularExpression) != nil {
                    // Save previous move if we have one
                    if let whiteMove = currentWhiteMove {
                        let moveText =
                            "\(currentMoveNumber). \(whiteMove)"
                            + (currentBlackMove != nil ? " \(currentBlackMove!)" : "")

                        let move = MoveData(
                            moveNumber: currentMoveNumber,
                            whiteMove: whiteMove,
                            blackMove: currentBlackMove,
                            moveText: moveText,
                            comment: nil
                        )
                        moves.append(move)

                        // Reset for new move
                        currentWhiteMove = nil
                        currentBlackMove = nil

                        // Extract the move number from the component
                        if let moveNumber = Int(trimmedComponent.dropLast()) {
                            currentMoveNumber = moveNumber
                        }
                    }
                } else if currentWhiteMove == nil {
                    // This is white's move
                    currentWhiteMove = trimmedComponent
                } else {
                    // This is black's move
                    currentBlackMove = trimmedComponent

                    // Create and add the move
                    let moveText = "\(currentMoveNumber). \(currentWhiteMove!) \(currentBlackMove!)"
                    let move = MoveData(
                        moveNumber: currentMoveNumber,
                        whiteMove: currentWhiteMove,
                        blackMove: currentBlackMove,
                        moveText: moveText,
                        comment: nil
                    )
                    moves.append(move)

                    // Reset for next move
                    currentMoveNumber += 1
                    currentWhiteMove = nil
                    currentBlackMove = nil
                }
            }

            // Handle last white move if there's no black move
            if let whiteMove = currentWhiteMove {
                let move = MoveData(
                    moveNumber: currentMoveNumber,
                    whiteMove: whiteMove,
                    blackMove: nil,
                    moveText: "\(currentMoveNumber). \(whiteMove)",
                    comment: nil
                )
                moves.append(move)
            }
        }

        return (metadata, moves)
    }
}

/// Custom errors that can occur during PGN operations
public enum PgnError: Error {
    case gameNotLoaded
    case invalidMove
    case invalidPgnFormat
    case notImplemented
}
