//
//  SettingsCommand.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import PgnCore
import SwiftUI

struct OpenFileCommand: Commands {
    @Bindable var pgnCore: PgnCore

    @CommandsBuilder var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open PGN File") {
                #if os(macOS)
                let openPanel = NSOpenPanel()
                openPanel.allowedContentTypes = [.pgn]
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseFiles = true
                openPanel.canChooseDirectories = false

                openPanel.begin { result in
                    if result == .OK {
                        if let url = openPanel.url {
                            DispatchQueue.main.async {
                                _ = pgnCore.load(from: url)
                            }
                        }
                    }
                }
                #endif
            }
        }
    }
}
