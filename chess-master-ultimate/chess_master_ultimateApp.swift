//
//  chess_master_ultimateApp.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/16/25.
//

import PgnCore
import SwiftData
import SwiftUI

@main
struct chess_master_ultimateApp: App {
    @State private var pgnCore = PgnCore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(pgnCore)
                .modelContainer(for: [
                    Chat.self
                ])
        }
    }
}
