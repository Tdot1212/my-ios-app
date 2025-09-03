// File: AIProvider.swift
import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case deepseek, openai, gemini, anthropic
    var id: String { rawValue }

    var defaultModel: String {
        switch self {
        case .deepseek: return "deepseek-chat"
        case .openai:   return "gpt-4o-mini"
        case .gemini:   return "gemini-1.5-pro"
        case .anthropic:return "claude-3-5-sonnet-20240620"
        }
    }
}
