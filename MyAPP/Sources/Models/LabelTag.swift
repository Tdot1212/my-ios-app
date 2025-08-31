import Foundation
import SwiftData

@Model
final class LabelTag {
    var name: String
    var colorHex: String
    
    init(name: String, colorHex: String = "#4F46E5") {
        self.name = name
        self.colorHex = colorHex
    }
}

