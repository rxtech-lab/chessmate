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
    var event: String?

    /// Site where the game was played
    var site: String?

    /// Date when the game was played
    var date: String?

    /// Round number in the tournament
    var round: String?

    /// White player's name
    var white: String?

    /// Black player's name
    var black: String?

    /// Result of the game (1-0, 0-1, 1/2-1/2, or *)
    var result: String?
}

// GameState stores the current game state including moves, players, and current position
public struct GameState {
    /// The metadata of the game
    var metadata: GameMetadata?

    /// The list of moves in the game
    var historyData: [MoveData] = []

    /// Current position in the move list (0-based index)
    var currentMoveIndex: Int = -1

    /// The white player
    var whitePlayer: Player?

    /// The black player
    var blackPlayer: Player?

    /// The raw PGN content
    var pgnContent: String = ""

    /// Whether the game is loaded
    var isLoaded: Bool = false
}

public class PgnCore: PgnCoreProtocol {
    /// The current state of the game
    public var gameState: GameState

    /// The configuration for the chess board
    public var boardConfig: ChessBoardConfig?

    public init() {
        self.gameState = GameState()
    }

    /// Sets the configuration for the chess board
    /// - Parameter config: The configuration to use for the chess board
    public func setBoardConfig(_ config: ChessBoardConfig) {
        self.boardConfig = config
    }

    /// Loads a PGN file from the given URL and parses its content
    /// - Parameter file: The URL of the PGN file to load
    /// - Returns: The raw content of the PGN file
    public func load(from file: URL) -> String {
        do {
            let content = try String(contentsOf: file, encoding: .utf8)
            gameState.pgnContent = content
            gameState.isLoaded = true

            // Parse the PGN content
            let (metadata, moves) = parsePgnContent(content)
            gameState.metadata = metadata
            gameState.historyData = moves

            // Create player objects from metadata
            if let whiteName = metadata.white {
                gameState.whitePlayer = Player(
                    id: UUID().uuidString, name: whiteName, color: .white)
            }
            if let blackName = metadata.black {
                gameState.blackPlayer = Player(
                    id: UUID().uuidString, name: blackName, color: .black)
            }

            return content
        } catch {
            print("Error loading PGN file: \(error)")
            return ""
        }
    }

    /// Makes a move in the game
    /// - Parameters:
    ///   - player: The player making the move
    ///   - from: The starting position of the piece
    ///   - to: The destination position of the piece
    /// - Throws: An error if the move is invalid
    public func makeMove(as player: Player, from: String, to: String) throws {
        guard gameState.isLoaded else {
            throw PgnError.gameNotLoaded
        }

        // Create a new move
        let moveNumber = (gameState.historyData.count + 1) / 2 + 1
        let moveText = "\(from)\(to)"

        // Create a new move entry
        let newMove = MoveData(
            moveNumber: moveNumber,
            whiteMove: player.color == .white ? moveText : nil,
            blackMove: player.color == .black ? moveText : nil,
            moveText:
                "\(moveNumber). \(player.color == .white ? moveText : "")\(player.color == .black ? " \(moveText)" : "")",
            comment: nil
        )

        // If we're at the end of the history, append the move
        if gameState.currentMoveIndex == gameState.historyData.count - 1 {
            gameState.historyData.append(newMove)
        } else {
            // We're in the middle of the history, create a new branch
            // Remove all moves after the current position
            gameState.historyData = Array(gameState.historyData[0...gameState.currentMoveIndex])
            // Add the new move
            gameState.historyData.append(newMove)
        }

        gameState.currentMoveIndex = gameState.historyData.count - 1
    }

    /// Moves to the next position in the game
    public func next() {
        guard gameState.currentMoveIndex < gameState.historyData.count - 1 else { return }
        gameState.currentMoveIndex += 1
    }

    /// Moves to the previous position in the game
    public func previous() {
        guard gameState.currentMoveIndex > 0 else { return }
        gameState.currentMoveIndex -= 1
    }

    /// Moves to the first position in the game
    public func first() {
        gameState.currentMoveIndex = 0
    }

    /// Moves to the last position in the game
    public func last() {
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

        // Parse metadata (lines starting with [)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.isEmpty { continue }

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
            } else if !trimmedLine.hasPrefix("[") {
                // Parse moves
                let moveTexts = trimmedLine.components(separatedBy: .whitespaces)
                var currentMoveNumber = 1
                var currentWhiteMove: String?

                for moveText in moveTexts {
                    if moveText.isEmpty { continue }

                    // Skip move numbers and dots
                    if moveText.range(of: #"^\d+\.$"#, options: .regularExpression) != nil {
                        continue
                    }

                    // Skip result
                    if moveText == "1-0" || moveText == "0-1" || moveText == "1/2-1/2"
                        || moveText == "*"
                    {
                        continue
                    }

                    // Parse move
                    if currentWhiteMove == nil {
                        currentWhiteMove = moveText
                    } else {
                        let move = MoveData(
                            moveNumber: currentMoveNumber,
                            whiteMove: currentWhiteMove,
                            blackMove: moveText,
                            moveText: "\(currentMoveNumber). \(currentWhiteMove!) \(moveText)",
                            comment: nil
                        )
                        moves.append(move)
                        currentMoveNumber += 1
                        currentWhiteMove = nil
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
        }

        return (metadata, moves)
    }
}

/// Custom errors that can occur during PGN operations
public enum PgnError: Error {
    case gameNotLoaded
    case invalidMove
    case invalidPgnFormat
}
