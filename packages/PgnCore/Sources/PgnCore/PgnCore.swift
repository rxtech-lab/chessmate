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
    /// This is a Double to allow half-moves:
    /// - Integer values (0.0, 1.0, 2.0, etc.) represent positions after black's move
    /// - Half values (0.5, 1.5, 2.5, etc.) represent positions after white's move
    public internal(set) var currentMoveIndex: Double = 0

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

    /// The source square of the last move (for highlighting)
    public internal(set) var highlightedFromSquare: String? = nil

    /// The destination square of the last move (for highlighting)
    public internal(set) var highlightedToSquare: String? = nil

    public var hasPreviousMove: Bool {
        return currentMoveIndex > 0
    }

    public var hasNextMove: Bool {
        if currentMoveIndex.truncatingRemainder(dividingBy: 1) == 0 {
            // After black's move, check if there's another full move
            return Int(currentMoveIndex) < historyData.count - 1
        } else {
            // After white's move, check if black has a move in this same move number
            let moveIdx = Int(currentMoveIndex - 0.5)
            return moveIdx < historyData.count && historyData[moveIdx].blackMove != nil
        }
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
        metadata: GameMetadata? = nil, historyData: [MoveData], currentMoveIndex: Double,
        whitePlayer: Player? = nil, blackPlayer: Player? = nil, pgnContent: String, isLoaded: Bool,
        highlightedFromSquare: String? = nil, highlightedToSquare: String? = nil
    ) {
        self.metadata = metadata
        self.historyData = historyData
        self.currentMoveIndex = currentMoveIndex
        self.whitePlayer = whitePlayer
        self.blackPlayer = blackPlayer
        self.pgnContent = pgnContent
        self.isLoaded = isLoaded
        self.highlightedFromSquare = highlightedFromSquare
        self.highlightedToSquare = highlightedToSquare
    }

    public init() {
        self.metadata = nil
        self.historyData = []
        self.currentMoveIndex = 0
        self.whitePlayer = nil
        self.blackPlayer = nil
        self.pgnContent = ""
        self.isLoaded = false
        self.highlightedFromSquare = nil
        self.highlightedToSquare = nil
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

        // Clear highlights
        gameState.highlightedFromSquare = nil
        gameState.highlightedToSquare = nil

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
            currentMoveIndex: 0.0,
            whitePlayer: game.metadata.white != nil
                ? Player(id: UUID().uuidString, name: game.metadata.white!, color: .white) : nil,
            blackPlayer: game.metadata.black != nil
                ? Player(id: UUID().uuidString, name: game.metadata.black!, color: .black) : nil,
            pgnContent: game.rawContent,
            isLoaded: true,
            highlightedFromSquare: nil,
            highlightedToSquare: nil
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
        // Check if we can go to next half-move
        if !gameState.hasNextMove { return }

        // Determine the current state and what to do next
        let isWholeNumber = gameState.currentMoveIndex.truncatingRemainder(dividingBy: 1) == 0

        if isWholeNumber {
            // We're after black's move, so move to white's move in the next turn
            gameState.currentMoveIndex += 0.5
            let moveIndex = Int(gameState.currentMoveIndex - 0.5)
            let move = gameState.historyData[moveIndex]
            applyWhiteMove(move)
            // The movePiece call in applyWhiteMove will set the highlights
        } else {
            // We're after white's move, so move to black's move in the same turn
            gameState.currentMoveIndex += 0.5
            let moveIndex = Int(gameState.currentMoveIndex - 1)
            let move = gameState.historyData[moveIndex]
            applyBlackMove(move)
            // The movePiece call in applyBlackMove will set the highlights
        }
    }

    /// Moves to the first position in the game
    public func first() {
        if gameState.currentMoveIndex <= 0 {
            gameState.currentMoveIndex = 0
            // Clear highlights
            gameState.highlightedFromSquare = nil
            gameState.highlightedToSquare = nil
            return
        }

        setupInitialBoard()
        gameState.currentMoveIndex = 0
    }

    /// Moves to the last position in the game
    public func last() {
        if gameState.historyData.isEmpty { return }

        // Reset and replay all moves
        setupInitialBoard()

        // Check if the last move has both white and black moves
        let lastMoveIdx = gameState.historyData.count - 1
        let lastMove = gameState.historyData[lastMoveIdx]

        // Play all full moves
        for i in 0..<lastMoveIdx {
            applyMove(gameState.historyData[i])
        }

        // Apply the last move
        if lastMove.blackMove != nil {
            // Last move is complete with both white and black moves
            applyMove(lastMove)
            gameState.currentMoveIndex = Double(lastMoveIdx + 1)
        } else {
            // Last move only has white's move
            applyWhiteMove(lastMove)
            gameState.currentMoveIndex = Double(lastMoveIdx) + 0.5
        }

        // The movePiece call in applyMove will set the highlights
    }

    /// Moves to the previous position in the game
    public func previous() {
        // If at initial position, do nothing
        if gameState.currentMoveIndex <= 0 { return }

        // Reset the board and replay moves up to the previous position
        setupInitialBoard()

        // Determine if we're going from white's move to start, or black's move to white's move
        let isWholeNumber = gameState.currentMoveIndex.truncatingRemainder(dividingBy: 1) == 0

        if isWholeNumber {
            // Going from after black's move to after white's move
            gameState.currentMoveIndex -= 0.5

            // Replay all moves up to the new position
            let fullMoves = Int(gameState.currentMoveIndex - 0.5)
            for i in 0..<fullMoves {
                applyMove(gameState.historyData[i])
            }

            // Add the white move for the current position
            if gameState.currentMoveIndex > 0 {
                let moveIdx = Int(gameState.currentMoveIndex - 0.5)
                applyWhiteMove(gameState.historyData[moveIdx])
            }
        } else {
            // Going from after white's move to after black's move of previous turn
            gameState.currentMoveIndex -= 0.5

            // Replay all full moves up to the previous position
            let fullMoves = Int(gameState.currentMoveIndex)
            for i in 0..<fullMoves {
                applyMove(gameState.historyData[i])
            }
        }

        // The highlights will be set by the last movePiece call in the replay
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

        let currentIndex = Int(gameState.currentMoveIndex)
        let startIndex = max(0, currentIndex - moves + 1)
        let endIndex = currentIndex + 1

        // If we have a fractional moveIndex (white's move), we need to include the partial move
        if gameState.currentMoveIndex.truncatingRemainder(dividingBy: 1) != 0 {
            return Array(
                gameState.historyData[startIndex..<min(endIndex, gameState.historyData.count)])
        } else {
            return Array(gameState.historyData[startIndex..<endIndex])
        }
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
