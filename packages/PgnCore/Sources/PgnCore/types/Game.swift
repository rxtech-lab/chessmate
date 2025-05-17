import Foundation

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
public struct GameMetadata: Equatable {
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

    public var id: String {
        return event! + date! + white! + black!
    }
}

/// Represents a single game from a PGN file
public struct Game: Identifiable, Hashable, Equatable {
    /// Unique identifier for the game
    public var id: String {
        return metadata.id
    }

    /// Game metadata
    public let metadata: GameMetadata

    /// Moves in the game
    public let moves: [MoveData]

    /// Raw PGN content for this game
    public let rawContent: String

    public init(metadata: GameMetadata, moves: [MoveData], rawContent: String) {
        self.metadata = metadata
        self.moves = moves
        self.rawContent = rawContent
    }

    /// Creates a descriptive title for the game based on its metadata
    public var title: String {
        let whiteName = metadata.white ?? "Unknown"
        let blackName = metadata.black ?? "Unknown"
        let eventName = metadata.event ?? "Chess Game"
        let dateName = metadata.date ?? ""

        return "\(whiteName) vs \(blackName) - \(eventName) \(dateName)"
    }

    /// Returns a short summary of the game
    public var summary: String {
        let result = metadata.result ?? "*"
        let whiteName = metadata.white?.components(separatedBy: ",").first ?? "White"
        let blackName = metadata.black?.components(separatedBy: ",").first ?? "Black"

        return "\(whiteName) vs \(blackName) (\(result))"
    }

    // hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Equatable
    public static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.id == rhs.id
    }
}
