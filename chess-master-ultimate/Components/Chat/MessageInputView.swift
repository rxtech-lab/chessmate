//
//  MessageInputView.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    var onSend: () -> Void
    var ask: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type a message...", text: $text, axis: .vertical)
                    .lineLimit(1 ... 5)
                    .frame(minHeight: 80)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend()
                        }
                    }
            }
            HStack {
                Button(action: {
                    ask()
                }) {
                    Text("Ask about current move")
                }
                Spacer()
                Button(action: {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.white)
                        .font(.system(size: 14))
                        .fontWeight(.black)
                        .padding(10)
                }
                .buttonStyle(.plain)
                .fontWeight(.bold)
                .tint(.black)
                .buttonBorderShape(.circle)
                .background(.black)
                .cornerRadius(999)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(.gray.opacity(0.1))
            .stroke(.gray, lineWidth: 0.2))
        .padding()
    }
}

#Preview {
    MessageInputView(
        text: .constant("Hello"), onSend: {}, ask: {}
    )
}
