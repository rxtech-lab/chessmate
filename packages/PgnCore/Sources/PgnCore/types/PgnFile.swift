//
//  PgnFile.swift
//  PgnCore
//
//  Created by Qiwei Li on 5/17/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Represents a PGN file that can be loaded and parsed
public final class PgnFile: FileDocument, @unchecked Sendable {
    public static var readableContentTypes: [UTType] { [.pgn] }
    public static var writableContentTypes: [UTType] { [.pgn] }

    /// The raw content of the PGN file
    private(set) var content: String = ""

    /// The games parsed from the PGN file
    private(set) var games: [Game] = []

    /// Initializes a new, empty PGN file
    public init() {}

    /// Initializes a PGN file with the given content
    /// - Parameter content: The PGN content to parse
    public init(content: String) {
        self.content = content
        self.games = parseMultipleGamesFromPgn(content)
    }

    /// Required initializer for FileDocument
    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        self.content = content
        self.games = parseMultipleGamesFromPgn(content)
    }

    /// Writes the document content to a file
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }

    /// Loads a PGN file from the given URL
    /// - Parameter file: The URL of the PGN file to load
    /// - Returns: Whether the file was loaded successfully
    @discardableResult
    public func load(from file: URL) -> Bool {
        do {
            content = try String(contentsOf: file, encoding: .utf8)
            games = parseMultipleGamesFromPgn(content)
            return true
        } catch {
            print("Error loading PGN file: \(error)")
            return false
        }
    }

    /// Saves the content to a PGN file
    /// - Parameter file: The URL where the PGN file should be saved
    /// - Returns: Whether the file was saved successfully
    @discardableResult
    public func save(to file: URL) -> Bool {
        do {
            try content.write(to: file, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error saving PGN file: \(error)")
            return false
        }
    }

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
                    if gameEndIndex < nsContent.length,
                       nsContent.substring(with: NSRange(location: gameEndIndex - 1, length: 1))
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

                for i in 1 ..< parts.count {
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
                if !parsingMoves, !moveTextSection.isEmpty {
                    parsingMoves = true
                }
                continue
            }

            if trimmedLine.hasPrefix("["), trimmedLine.hasSuffix("]") {
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
