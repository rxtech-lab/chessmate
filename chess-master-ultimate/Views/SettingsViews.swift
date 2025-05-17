//
//  SettingsViews.swift
//  chess-master-ultimate
//
//  Created by Qiwei Li on 5/17/25.
//

import SwiftUI

struct SettingsViews: View {
    @AppStorage("openAIUrl") var openAIUrl: String = ""
    @AppStorage("openAIKey") var openAIKey: String = ""
    @AppStorage("openAIModel") var openAIModel: String = ""
    @State private var isValidUrl: Bool = true

    var body: some View {
        TabView {
            Form {
                Section(header: Text("API Key")) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("OpenAI URL", text: $openAIUrl)
                                .onChange(of: openAIUrl) { _, newValue in
                                    isValidUrl = validateUrl(newValue)
                                }

                            if !openAIUrl.isEmpty {
                                Image(
                                    systemName: isValidUrl
                                        ? "checkmark.circle.fill" : "xmark.circle.fill"
                                )
                                .foregroundColor(isValidUrl ? .green : .red)
                            }
                        }

                        if !isValidUrl && !openAIUrl.isEmpty {
                            Text("Please enter a valid URL")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    TextField("OpenAI Key", text: $openAIKey)

                    TextField("OpenAI Model", text: $openAIModel)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("AI Settings", systemImage: "gear")
            }
        }
        .onAppear {
            isValidUrl = validateUrl(openAIUrl)
        }
    }

    private func validateUrl(_ string: String) -> Bool {
        if string.isEmpty { return true }
        guard let url = URL(string: string) else { return false }
        return url.scheme != nil && url.host != nil
    }
}
