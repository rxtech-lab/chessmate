import SwiftUI

public protocol PgnCoreProtocol {
    // Game management
    /// Load a pgn file
    func load(from file: URL) -> String

    /// Get all games from the loaded PGN file
    var games: [Game] { get }

    /// Currently selected game index
    var currentGameIndex: Int { get set }

    /// Load a specific game from the parsed games
    func loadGame(game: Game)

    // Move management
    /// Make a move
    /// TODO: from and to should be a custom type that represents a move
    /// including the position of the piece and side of the player.
    func makeMove(as player: Player, from: String, to: String) throws

    /// Play to the next move
    func next()

    /// Play to the previous move
    func previous()

    /// Play to the first move
    func first()

    /// Play to the last move
    func last()

    /// Save the current game to a file using pgn format
    func save(to file: URL)
}
