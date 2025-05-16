import Foundation

/// Represents a single game from a PGN file
public struct Game: Identifiable, Hashable, Equatable {
    /// Unique identifier for the game
    public let id: UUID

    /// Game metadata
    public let metadata: GameMetadata

    /// Moves in the game
    public let moves: [MoveData]

    /// Raw PGN content for this game
    public let rawContent: String

    public init(id: UUID = UUID(), metadata: GameMetadata, moves: [MoveData], rawContent: String) {
        self.id = id
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
