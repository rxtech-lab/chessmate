//
//  MessageView.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import SwiftUI

struct MessageView: View {
    var message: Message

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer()
                UserMessageBubble(content: message.content)
            } else {
                AssistantMessageView(content: message.content)
                Spacer()
            }
        }
    }
}

struct UserMessageBubble: View {
    let content: String

    var body: some View {
        Text(content)
            .padding(12)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: 280, alignment: .trailing)
    }
}

struct AssistantMessageView: View {
    let content: String

    var body: some View {
        Text(content)
            .padding(12)
            .foregroundColor(.primary)
            .frame(maxWidth: 280, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageView(message: Message(role: .user, content: "Hello, how are you?"))
        MessageView(
            message: Message(
                role: .assistant,
                content: "I'm doing well, thank you! How can I help you with your chess game today?"
            ))
    }
    .padding()
}
