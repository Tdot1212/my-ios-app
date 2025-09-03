// File: AISettingsView.swift
import SwiftUI

struct AISettingsView: View {
    @State private var provider = AIClient.shared.provider
    @State private var model = AIClient.shared.model
    @State private var usePersonal = AIClient.shared.usePersonalKey
    @State private var personalKey = SecretsStore.load(account: AIClient.shared.providerAccount()) ?? ""
    @State private var testResult = ""
    @State private var testing = false

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: $provider) {
                    ForEach(AIProvider.allCases) { p in
                        Text(p.rawValue.capitalized).tag(p)
                    }
                }
                .onChange(of: provider) { new in
                    AIClient.shared.provider = new
                    model = new.defaultModel
                    AIClient.shared.model = model
                    personalKey = SecretsStore.load(account: AIClient.shared.providerAccount()) ?? ""
                }

                TextField("Model", text: $model)
                    .onChange(of: model) { AIClient.shared.model = $0 }
            }

            Section("Personal Key (optional)") {
                Toggle("Use my own key for this provider", isOn: $usePersonal)
                    .onChange(of: usePersonal) { AIClient.shared.usePersonalKey = $0 }

                SecureField("Paste key", text: $personalKey)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)

                HStack {
                    Button("Save Key") { try? SecretsStore.save(personalKey, for: AIClient.shared.providerAccount()) }
                    Button("Delete Key") { SecretsStore.delete(account: AIClient.shared.providerAccount()); personalKey = "" }
                }

                Text(noteFor(provider))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Connection Test") {
                Button(action: test) { testing ? AnyView(ProgressView()) : AnyView(Text("Run Test")) }
                if !testResult.isEmpty { Text(testResult).font(.footnote) }
            }
        }
        .navigationTitle("AI Settings")
    }

    private func noteFor(_ p: AIProvider) -> String {
        switch p {
        case .openai:    return "OpenAI Chat Completions. Do not share company keys."
        case .anthropic: return "Claude Messages API (anthropic-version 2023-06-01)."
        case .gemini:    return "Gemini generateContent (Google). Key tied to your project."
        case .deepseek:  return "DeepSeek Chat Completions compatible."
        }
    }

    private func test() {
        testing = true
        Task {
            let out = try? await AIClient.shared.chat("Reply with: OK")
            await MainActor.run { testResult = out ?? "Test failed"; testing = false }
        }
    }
}
