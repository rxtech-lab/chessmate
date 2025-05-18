//
//  MessageInputView.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import SwiftUI

// Define placeholder enum if OpenAICompatibleModel is not available at compile time
#if !PREVIEW
    import Foundation
#endif

struct MessageInputView: View {
    @Binding var text: String
    let currentModel: OpenAICompatibleModel
    let customModel: OpenAICompatibleModel?
    let disableDefaultModel: Bool
    var onSend: () -> Void
    var ask: () -> Void
    var onModelChange: (OpenAICompatibleModel) -> Void
    @State private var showModelPicker = false
    @State private var hoveredModel: OpenAICompatibleModel?

    var body: some View {
        var modelCases = disableDefaultModel ? [] : OpenAICompatibleModel.allCases
        if let customModel = customModel {
            modelCases.append(customModel)
        }
        return VStack(spacing: 0) {
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
                    Image(systemName: "mail.and.text.magnifyingglass")
                }
                .help("Explain this move")
                #if os(macOS)
                    .buttonStyle(.accessoryBar)
                #endif

                Button {
                    showModelPicker.toggle()
                } label: {
                    Text(currentModel.displayName)
                }
                #if os(macOS)
                .buttonStyle(.accessoryBar)
                #endif
                .popover(isPresented: $showModelPicker) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(modelCases, id: \.self.rawValue) { model in
                            HStack {
                                Text(model.displayName)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                // if model is custom model, show custom icon
                                if case .custom(model: _) = model {
                                    Image(systemName: "gear")
                                        .padding(.trailing, 12)
                                }

                                if model.rawValue == currentModel.rawValue {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .padding(.trailing, 12)
                                }
                            }
                            .onHover { hovering in
                                if hovering {
                                    hoveredModel = model
                                } else {
                                    hoveredModel = nil
                                }
                            }
                            .foregroundColor(
                                hoveredModel == model ? .primary :
                                    model.rawValue == currentModel.rawValue ? .primary : .secondary
                            )
                            .background(
                                hoveredModel == model ? Color.gray.opacity(0.12) :
                                    Color.clear)
                            .cornerRadius(10)
                            .frame(width: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                onModelChange(model)
                                showModelPicker = false
                            }
                        }
                    }
                    .padding()
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
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.gray.opacity(0.1))
                .stroke(.gray, lineWidth: 0.2)
        )
        .padding()
    }
}

#Preview {
    MessageInputView(
        text: .constant("Hello"), currentModel: .claude37, customModel: .custom(model: "some"), disableDefaultModel: false, onSend: {}, ask: {},
        onModelChange: { _ in }
    )
}
