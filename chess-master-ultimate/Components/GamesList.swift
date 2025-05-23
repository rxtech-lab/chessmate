import PgnCore
import SwiftUI

/// A SwiftUI component that displays a list of games from a PGN file
public struct GamesList: View {
    @Environment(PgnCore.self) var pgnCore
    @Binding private var selectedGame: Game?
    
    public init(selectedGame: Binding<Game?>) {
        self._selectedGame = selectedGame
    }

    public var body: some View {
        if pgnCore.games.isEmpty {
            ContentUnavailableView("No Games", systemImage: "gamecontroller")
        } else {
            List(pgnCore.games, selection: $selectedGame) { game in
                NavigationLink(value: game) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(game.summary)
                                .font(.headline)

                            Spacer()
                        }

                        if let event = game.metadata.event {
                            Text(event)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        if let date = game.metadata.date {
                            Text(date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.sidebar)
            .onChange(of: selectedGame) { _, newGame in
                if let newGame = newGame {
                    pgnCore.loadGame(game: newGame)
                }
            }
        }
    }
}
