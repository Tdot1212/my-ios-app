import Foundation
import SwiftData

@Model
final class NoteItem {
    var content: String
    var createdAt: Date
    
    init(content: String) {
        self.content = content
        self.createdAt = Date()
    }
}

