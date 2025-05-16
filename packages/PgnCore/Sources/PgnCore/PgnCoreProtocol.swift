import SwiftUI

@MainActor
public protocol PgnCoreProtocol {
    // Load a png file
    func load(from file: URL) -> String

    // make a move
    // TODO: from and to should be a custom type that represents a move
    // including the position of the piece and side of the player.
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

    /// Get previous n moves
    func getPreviousMoves(num moves: Int) -> [MoveData]
}
