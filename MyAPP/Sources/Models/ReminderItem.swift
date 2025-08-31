import Foundation
import SwiftData

@Model
final class ReminderItem {
    var title: String
    var note: String?
    var dueDate: Date?
    var repeatRule: String?
    var earlyMinutes: Int
    var isNotified: Bool
    
    init(title: String, note: String? = nil, dueDate: Date? = nil, repeatRule: String? = nil, earlyMinutes: Int = 0, isNotified: Bool = false) {
        self.title = title
        self.note = note
        self.dueDate = dueDate
        self.repeatRule = repeatRule
        self.earlyMinutes = earlyMinutes
        self.isNotified = isNotified
    }
}

