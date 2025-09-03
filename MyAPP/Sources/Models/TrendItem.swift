import Foundation

struct TrendItem: Identifiable, Codable, Equatable {
    let id: UUID
    let source: String
    let title: String
    let url: String

    // Default id if server doesn't provide one
    init(id: UUID = UUID(), source: String, title: String, url: String) {
        self.id = id
        self.source = source
        self.title = title
        self.url = url
    }
}

struct TrendsResponse: Decodable {
    let version: String?
    let items: [TrendItem]
    let fetchedAt: String?
}

