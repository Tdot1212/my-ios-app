import Foundation

@MainActor
final class TrendsViewModel: ObservableObject {
    @Published var items: [TrendItem] = []
    @Published var isLoading = false
    @Published var errorText: String?

    func reload(geo: String = "US", limit: Int = 12) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                items = try await TrendsClient.shared.fetch(geo: geo, limit: limit)
                errorText = nil
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
