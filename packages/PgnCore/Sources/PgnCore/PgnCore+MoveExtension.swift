extension PgnCore {
    /// Applies a specific move to the board
    internal func applyMove(_ move: MoveData) {
        // Apply white's move if it exists
        if let whiteMove = move.whiteMove {
            // use regex to remove first two characters from the move
            let moveWithoutNumber = String(whiteMove.dropFirst(2))

            processMove(moveWithoutNumber, for: .white)
        }

        // Apply black's move if it exists
        if let blackMove = move.blackMove {
            processMove(blackMove, for: .black)
        }
    }

    /// Applies only the white move from a MoveData
    internal func applyWhiteMove(_ move: MoveData) {
        guard let whiteMove = move.whiteMove else { return }
        // Remove the move number prefix (e.g., "1. e4" -> "e4")
        let moveWithoutNumber = String(whiteMove.dropFirst(2))
        processMove(moveWithoutNumber, for: .white)
    }

    /// Applies only the black move from a MoveData
    internal func applyBlackMove(_ move: MoveData) {
        guard let blackMove = move.blackMove else { return }
        processMove(blackMove, for: .black)
    }

    /// Applies the appropriate half-move based on the current move index
    internal func applyHalfMove(_ move: MoveData, isWhiteToMove: Bool) {
        if isWhiteToMove {
            applyWhiteMove(move)
        } else {
            applyBlackMove(move)
        }
    }

    /// Processes a single move notation and updates the board
    /// - Parameters:
    ///   - moveNotation: The algebraic notation of the move
    ///   - side: The side making the move
    private func processMove(_ moveNotation: String, for side: Side) {
        // Clean the move notation (remove check/mate symbols and capture symbol)
        var cleanMove = moveNotation.replacingOccurrences(of: "+", with: "")
        cleanMove = cleanMove.replacingOccurrences(of: "#", with: "")

        // Check if this is a castling move
        if cleanMove == "O-O" || cleanMove == "0-0" {
            // Kingside castling
            if side == .white {
                movePiece(from: "e1", to: "g1")  // King
                movePiece(from: "h1", to: "f1")  // Rook
            } else {
                movePiece(from: "e8", to: "g8")  // King
                movePiece(from: "h8", to: "f8")  // Rook
            }
            return
        } else if cleanMove == "O-O-O" || cleanMove == "0-0-0" {
            // Queenside castling
            if side == .white {
                movePiece(from: "e1", to: "c1")  // King
                movePiece(from: "a1", to: "d1")  // Rook
            } else {
                movePiece(from: "e8", to: "c8")  // King
                movePiece(from: "a8", to: "d8")  // Rook
            }
            return
        }

        let isCapture = cleanMove.contains("x")
        cleanMove = cleanMove.replacingOccurrences(of: "x", with: "")

        // Determine the destination square (always the last two characters)
        guard cleanMove.count >= 2 else { return }
        let to = String(cleanMove.suffix(2))

        // Determine the piece type
        let pieceType: PieceType

        if cleanMove.first?.isUppercase == true {
            // Piece is specified by uppercase letter
            switch cleanMove.first {
            case "K": pieceType = .king
            case "Q": pieceType = .queen
            case "R": pieceType = .rook
            case "B": pieceType = .bishop
            case "N": pieceType = .knight
            default: pieceType = .pawn
            }

        } else {
            // Pawn move
            pieceType = .pawn
        }

        // Handle captures first (remove the captured piece)
        if isCapture {
            gameState.setPiece(nil, at: to)
        }

        // Find the piece that's moving
        if let fromSquare = findSourceSquare(
            pieceType: pieceType, side: side, to: to)
        {
            movePiece(from: fromSquare, to: to)
        }
    }

    /// Moves a piece from one square to another
    /// - Parameters:
    ///   - from: The source square
    ///   - to: The destination square
    private func movePiece(from: String, to: String) {
        if let piece = gameState.piece(at: from) {
            gameState.setPiece(piece, at: to)
            gameState.setPiece(nil, at: from)

            // Set highlighted squares for move visualization
            gameState.highlightedFromSquare = from
            gameState.highlightedToSquare = to
        }
    }

    /// Finds the source square for a piece that's moving to the destination
    /// - Parameters:
    ///   - pieceType: The type of the piece
    ///   - side: The side making the move
    ///   - to: The destination square
    /// - Returns: The source square of the moving piece, if found
    private func findSourceSquare(
        pieceType: PieceType, side: Side, to: String
    ) -> String? {
        var candidates = [String]()
        // Iterate through all squares on the board
        for file in ["a", "b", "c", "d", "e", "f", "g", "h"] {
            for rank in 1...8 {
                let square = "\(file)\(rank)"

                // Skip the destination square
                if square == to { continue }

                // Check if there's a piece of the correct type and side on this square
                if let piece = gameState.piece(at: square),
                    piece.type == pieceType,
                    piece.color == side,
                    canMove(pieceType: pieceType, from: square, to: to)
                {
                    candidates.append(square)
                }
            }
        }

        // If we found exactly one candidate, that's our source square
        if candidates.count == 1 {
            return candidates[0]
        }

        // If we found multiple candidates, find the closest one
        if candidates.count > 1 {
            return findClosestPiece(candidates, to: to)
        }

        return nil
    }

    /// Determines if a piece can move from one square to another
    /// - Parameters:
    ///   - pieceType: The type of the piece
    ///   - from: The source square
    ///   - to: The destination square
    /// - Returns: True if the move is valid for this piece type
    private func canMove(pieceType: PieceType, from: String, to: String) -> Bool {
        // Simple implementation that checks if the move is geometrically possible
        guard from.count == 2, to.count == 2 else { return false }

        let fromFile = from.prefix(1)
        let fromRank = Int(String(from.suffix(1))) ?? 0
        let toFile = to.prefix(1)
        let toRank = Int(String(to.suffix(1))) ?? 0

        let fileDistance = abs(
            Int(toFile.first?.asciiValue ?? 0) - Int(fromFile.first?.asciiValue ?? 0))
        let rankDistance = abs(toRank - fromRank)

        switch pieceType {
        case .king:
            return fileDistance <= 1 && rankDistance <= 1

        case .queen:
            // Queen moves like rook or bishop
            return fileDistance == 0 || rankDistance == 0 || fileDistance == rankDistance

        case .rook:
            return fileDistance == 0 || rankDistance == 0

        case .bishop:
            return fileDistance == rankDistance

        case .knight:
            return (fileDistance == 1 && rankDistance == 2)
                || (fileDistance == 2 && rankDistance == 1)

        case .pawn:
            // Basic pawn movement checks
            return true
        }
    }

    /// Finds the closest piece from a list of candidates to the destination square
    /// - Parameters:
    ///   - candidates: List of candidate source squares
    ///   - to: The destination square
    /// - Returns: The closest candidate square
    private func findClosestPiece(_ candidates: [String], to: String) -> String? {
        guard !candidates.isEmpty else { return nil }
        if candidates.count == 1 { return candidates[0] }

        let toFile = to.prefix(1)
        let toRank = Int(String(to.suffix(1))) ?? 0

        var closestDistance = Int.max
        var closestPiece = candidates[0]

        for candidate in candidates {
            let fromFile = candidate.prefix(1)
            let fromRank = Int(String(candidate.suffix(1))) ?? 0

            let fileDistance = abs(
                Int(toFile.first?.asciiValue ?? 0) - Int(fromFile.first?.asciiValue ?? 0))
            let rankDistance = abs(toRank - fromRank)
            let totalDistance = fileDistance + rankDistance

            if totalDistance < closestDistance {
                closestDistance = totalDistance
                closestPiece = candidate
            }
        }

        return closestPiece
    }

}
