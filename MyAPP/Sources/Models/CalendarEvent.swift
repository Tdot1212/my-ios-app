import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var title: String
    var note: String?
    var startDate: Date
    var endDate: Date
    var category: String
    var country: String?
    var eventType: String
    
    init(title: String, note: String? = nil, startDate: Date, endDate: Date, category: String = "personal", country: String? = nil, eventType: String = "personal") {
        self.title = title
        self.note = note
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.country = country
        self.eventType = eventType
    }
}

