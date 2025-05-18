//
//  chess_master_ultimateApp.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/16/25.
//

import PgnCore
import Sparkle
import SwiftData
import SwiftUI

var updaterController: SPUStandardUpdaterController?
let updaterDelegate = UpdaterDelegate()

@main
struct chess_master_ultimateApp: App {
    @State private var pgnCore = PgnCore()
    @State private var chatModel = ChatModel()

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: updaterDelegate, userDriverDelegate: nil)
        updaterController?.updater.updateCheckInterval = 80
        updaterController?.updater.automaticallyChecksForUpdates = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView(file: nil)
                .environment(pgnCore)
                .environment(chatModel)
                .modelContainer(for: [
                    Chat.self
                ])
        }
        .commands {
            #if os(macOS)
            OpenFileCommand(pgnCore: pgnCore)
            #endif
        }

        DocumentGroup(viewing: PgnFile.self) { file in
            ContentView(file: file.document)
                .environment(pgnCore)
                .environment(chatModel)
                .modelContainer(for: [
                    Chat.self
                ])
        }
        .commandsRemoved()
        #if os(macOS)
        Settings {
            SettingsViews()
        }
        #endif
    }
}
