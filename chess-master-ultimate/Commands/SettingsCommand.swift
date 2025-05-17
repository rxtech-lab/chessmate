//
//  SettingsCommand.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import SwiftUI

struct SettingsCommand: Commands {
    @Environment(\.openWindow) var openWindow
    
    @CommandsBuilder var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings") {
                openWindow(id: "settings")
            }
        }
    }
}
