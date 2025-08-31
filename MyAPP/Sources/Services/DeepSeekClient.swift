import Foundation

@MainActor
class DeepSeekClient: ObservableObject {
    static let shared = DeepSeekClient()
    
    private let baseURL = "https://api.deepseek.com/v1"
    private var apiKey: String?
    
    private init() {}
    
    func setAPIKey(_ key: String) {
        self.apiKey = key
    }
    
    func translateToChinese(_ text: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw DeepSeekError.noAPIKey
        }
        
        let prompt = "Translate the following English text to Chinese (Simplified):\n\n\(text)\n\nTranslation:"
        
        return try await makeRequest(prompt: prompt, systemMessage: "You are a helpful translator. Provide only the Chinese translation without any additional text or explanations.")
    }
    
    func summarize(_ text: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw DeepSeekError.noAPIKey
        }
        
        let prompt = "Summarize the following text in 2-3 bullet points:\n\n\(text)"
        
        return try await makeRequest(prompt: prompt, systemMessage: "You are a helpful summarizer. Provide a concise summary in 2-3 bullet points.")
    }
    
    private func makeRequest(prompt: String, systemMessage: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw DeepSeekError.noAPIKey
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemMessage],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 500,
            "temperature": 0.3
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DeepSeekError.requestFailed
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DeepSeekError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum DeepSeekError: Error {
    case noAPIKey
    case requestFailed
    case invalidResponse
}

