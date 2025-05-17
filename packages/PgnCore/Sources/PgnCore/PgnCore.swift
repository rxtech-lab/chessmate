import Foundation
import SwiftUI

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
    public internal(set) var highlightedFromSquare: String?

    /// The destination square of the last move (for highlighting)
    public internal(set) var highlightedToSquare: String?

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

    // Get all the moves until the current move index.
    // Output the pgn file format include the metadata and the moves.
    public func getPreviousMoves() -> String {
        var pgnContent = ""

        // Write metadata
        if let metadata = metadata {
            if let event = metadata.event { pgnContent += "[Event \"\(event)\"]\n" }
            if let site = metadata.site { pgnContent += "[Site \"\(site)\"]\n" }
            if let date = metadata.date { pgnContent += "[Date \"\(date)\"]\n" }
            if let round = metadata.round { pgnContent += "[Round \"\(round)\"]\n" }
            if let white = metadata.white { pgnContent += "[White \"\(white)\"]\n" }
            if let black = metadata.black { pgnContent += "[Black \"\(black)\"]\n" }
            if let result = metadata.result { pgnContent += "[Result \"\(result)\"]\n" }
            pgnContent += "\n"
        }

        // Write moves up to current index
        let currentMoveNumber = Int(ceil(currentMoveIndex))
        for i in 0..<currentMoveNumber {
            if i < historyData.count {
                let move = historyData[i]

                // For the last move, check if we need to include black's move
                if i == currentMoveNumber - 1
                    && currentMoveIndex.truncatingRemainder(dividingBy: 1) == 0
                {
                    // Full move - include both white and black moves
                    pgnContent += move.moveText + " "
                } else if i == currentMoveNumber - 1
                    && currentMoveIndex.truncatingRemainder(dividingBy: 1) == 0.5
                {
                    // Half move - include only white's move
                    if let whiteMove = move.whiteMove {
                        pgnContent += "\(move.moveNumber). \(whiteMove) "
                    }
                } else {
                    // Full move before current position
                    pgnContent += move.moveText + " "
                }
            }
        }

        return pgnContent.trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// The PGN file being used
    private var pgnFile: PgnFile?

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
        // Create a new PgnFile and load the contents
        let pgnFile = PgnFile()
        if pgnFile.load(from: file) {
            self.pgnFile = pgnFile
            self.games = pgnFile.games
            return pgnFile.content
        }
        return ""
    }

    public func load(from pgnFile: PgnFile) {
        self.pgnFile = pgnFile
        self.games = pgnFile.games
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

        // Create a new PgnFile with the content and save it
        let pgnFile = PgnFile(content: pgnContent)
        pgnFile.save(to: file)
    }

    // MARK: - Private Methods
}

/// Custom errors that can occur during PGN operations
public enum PgnError: Error {
    case gameNotLoaded
    case invalidMove
    case invalidPgnFormat
    case notImplemented
}
