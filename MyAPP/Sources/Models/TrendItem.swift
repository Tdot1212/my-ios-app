import Foundation
import SwiftData

@Model
final class TrendItem {
    var headline: String
    var url: String?
    var fetchedAt: Date
    
    init(headline: String, url: String? = nil) {
        self.headline = headline
        self.url = url
        self.fetchedAt = Date()
    }
}

