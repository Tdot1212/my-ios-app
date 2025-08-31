import Foundation

struct TrendDTO: Codable, Identifiable {
    var id: String { "\(source)|\(title)" }
    let source: String
    let title: String
    let url: String?
}

enum TrendsClient {
    // Set this once (Settings screen or a Constants.swift).
    static var base = UserDefaults.standard.string(forKey: "SCRAPER_BASE") ?? "" // e.g. "https://orbit-trends-proxy.vercel.app"

    static func setBase(_ url: String) { UserDefaults.standard.set(url, forKey: "SCRAPER_BASE"); base = url }

    static func fetchAll(geo: String = "US", limit: Int = 12) async throws -> [TrendDTO] {
        guard let url = URL(string: "\(base)/api/trends?geo=\(geo)&limit=\(limit)") else {
            throw URLError(.badURL)
        }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        struct Envelope: Codable { let items: [TrendDTO] }
        return try JSONDecoder().decode(Envelope.self, from: data).items
    }
}
