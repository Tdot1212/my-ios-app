import Foundation

enum TrendsError: Error { case badURL, badResponse }

final class TrendsClient {
    static let shared = TrendsClient()

    func fetch(geo: String = "US", limit: Int = 12) async throws -> [TrendItem] {
        var comps = URLComponents(
            url: AppConfig.trendsBaseURL.appendingPathComponent("/api/trends"),
            resolvingAgainstBaseURL: false
        )
        comps?.queryItems = [
            URLQueryItem(name: "geo", value: geo),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "v", value: String(Int(Date().timeIntervalSince1970))) // cache-buster during dev
        ]
        guard let url = comps?.url else { throw TrendsError.badURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw TrendsError.badResponse }

        let decoded = try JSONDecoder().decode(TrendsResponse.self, from: data)
        return decoded.items
    }
}
