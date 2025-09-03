import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var note: String?
    var label: LabelTag?
    var dueDate: Date?
    var isDone: Bool
    var createdAt: Date
    
    init(title: String, note: String? = nil, label: LabelTag? = nil, dueDate: Date? = nil, isDone: Bool = false) {
        self.title = title
        self.note = note
        self.label = label
        self.dueDate = dueDate
        self.isDone = isDone
        self.createdAt = Date()
    }
}

