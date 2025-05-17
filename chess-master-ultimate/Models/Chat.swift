//
//  Chat.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import Foundation
import PgnCore
import SwiftData

@Model
class Chat {
    #Unique<Chat>([\.gameId])
    var id: UUID
    var gameId: String
    var messages: [Message]

    init(id: UUID, gameId: String, messages: [Message]) {
        self.id = id
        self.gameId = gameId
        self.messages = messages
    }
}

@Model
class Message {
    var id: UUID
    var role: Role
    var content: String
    var createdAt: Date

    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = Date()
    }

    init(id: UUID, role: Role, content: String, createdAt: Date) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

enum Role: String, Codable {
    case user
    case assistant
}
