// File: AIClient.swift
import Foundation

// MARK: - Shared Types

struct ChatMessage: Codable { let role: String; let content: String }

struct ProxyRequest: Codable { let provider: String; let model: String; let messages: [ChatMessage]; let temperature: Double? }
struct ProxyResponse: Codable { let ok: Bool; let text: String }

// MARK: - Client

final class AIClient {
    static let shared = AIClient()
    // If your Vercel domain is different, change it here (keep /api/ai)
    private let proxyURL = URL(string: "https://my-ios-app.vercel.app/api/ai")!

    // Persisted user preferences
    var provider: AIProvider {
        get { AIProvider(rawValue: UserDefaults.standard.string(forKey: "ai.provider") ?? "deepseek") ?? .deepseek }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "ai.provider") }
    }
    var model: String {
        get { UserDefaults.standard.string(forKey: "ai.model") ?? provider.defaultModel }
        set { UserDefaults.standard.set(newValue, forKey: "ai.model") }
    }
    var usePersonalKey: Bool {
        get { UserDefaults.standard.bool(forKey: "ai.usePersonalKey") }
        set { UserDefaults.standard.set(newValue, forKey: "ai.usePersonalKey") }
    }

    // Keychain accounts per provider (internal so other files can call)
    func account(for p: AIProvider) -> String {
        switch p {
        case .deepseek: return "personal.deepseek"
        case .openai:   return "personal.openai"
        case .gemini:   return "personal.gemini"
        case .anthropic:return "personal.anthropic"
        }
    }
    func providerAccount() -> String { account(for: provider) }

    // Public chat API
    func chat(_ prompt: String) async throws -> String {
        let messages = [ChatMessage(role: "user", content: prompt)]
        if usePersonalKey, let key = SecretsStore.load(account: providerAccount()), !key.isEmpty {
            return try await direct(messages: messages, key: key)
        } else {
            return try await viaProxy(messages: messages)
        }
    }

    // MARK: - Proxy path (company server keys)

    private func viaProxy(messages: [ChatMessage]) async throws -> String {
        var req = URLRequest(url: proxyURL)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ProxyRequest(provider: provider.rawValue, model: model, messages: messages, temperature: 0.2)
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 400 else { throw NSError(domain: "AI", code: 1) }
        let decoded = try JSONDecoder().decode(ProxyResponse.self, from: data)
        return decoded.text
    }

    // MARK: - Direct provider calls (user's personal key)

    private func direct(messages: [ChatMessage], key: String) async throws -> String {
        switch provider {
        case .deepseek:
            return try await call(
                url: URL(string: "https://api.deepseek.com/v1/chat/completions")!,
                headers: ["Authorization": "Bearer \(key)", "Content-Type": "application/json"],
                body: DeepSeekChatBody(model: model, messages: messages, temperature: 0.2)
            ) { data in
                try JSONDecoder().decode(OpenAIChatResp.self, from: data).choices.first?.message.content ?? ""
            }

        case .openai:
            return try await call(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                headers: ["Authorization": "Bearer \(key)", "Content-Type": "application/json"],
                body: OpenAIChatBody(model: model, messages: messages, temperature: 0.2)
            ) { data in
                try JSONDecoder().decode(OpenAIChatResp.self, from: data).choices.first?.message.content ?? ""
            }

        case .anthropic:
            return try await call(
                url: URL(string: "https://api.anthropic.com/v1/messages")!,
                headers: ["x-api-key": key, "anthropic-version": "2023-06-01", "Content-Type": "application/json"],
                body: AnthropicBody(model: model, max_tokens: 1024, messages: messages)
            ) { data in
                try JSONDecoder().decode(AnthropicResp.self, from: data).content.first?.text ?? ""
            }

        case .gemini:
            let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(key)")!
            return try await call(
                url: url,
                headers: ["Content-Type": "application/json"],
                body: GeminiBody(contents: messages.asGeminiContents(),
                                 generationConfig: .init(temperature: 0.2))
            ) { data in
                try JSONDecoder().decode(GeminiResp.self, from: data)
                    .candidates.first?.content.parts.compactMap { $0.text }.joined() ?? ""
            }
        }
    }

    // MARK: - Generic caller

    private func call<T: Encodable>(url: URL,
                                    headers: [String:String],
                                    body: T,
                                    decode: (Data) throws -> String) async throws -> String {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        headers.forEach { req.addValue($0.value, forHTTPHeaderField: $0.key) }
        req.httpBody = try JSONEncoder().encode(body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 400 else { throw NSError(domain: "AI", code: 2) }
        return try decode(data)
    }
}

// MARK: - Typed request bodies

private struct OpenAIChatBody: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
}

private struct DeepSeekChatBody: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
}

private struct AnthropicBody: Encodable {
    let model: String
    let max_tokens: Int
    let messages: [ChatMessage]
}

private struct GeminiBody: Encodable {
    struct GenerationConfig: Encodable { let temperature: Double? }
    let contents: [GeminiContent]
    let generationConfig: GenerationConfig
}

private struct GeminiContent: Encodable {
    let role: String
    let parts: [GeminiPart]
}

private struct GeminiPart: Encodable { let text: String }

private extension Array where Element == ChatMessage {
    func asGeminiContents() -> [GeminiContent] {
        map { msg in
            GeminiContent(role: msg.role == "assistant" ? "model" : "user",
                          parts: [GeminiPart(text: msg.content)])
        }
    }
}

// MARK: - Minimal response decoders

struct OpenAIChatResp: Decodable {
    struct Choice: Decodable {
        struct Msg: Decodable { let role: String; let content: String }
        let index: Int
        let message: Msg
    }
    let choices: [Choice]
}

struct AnthropicResp: Decodable {
    struct Piece: Decodable { let text: String? }
    let content: [Piece]
}

struct GeminiResp: Decodable {
    struct Content: Decodable { struct Part: Decodable { let text: String? }; let parts: [Part] }
    struct Candidate: Decodable { let content: Content }
    let candidates: [Candidate]
}
