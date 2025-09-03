import Foundation

struct IntentResult: Identifiable, Codable {
    let id = UUID()
    let intent: IntentType
    let title: String
    let dateTime: Date?
    let contactName: String?
    let rawText: String
    
    enum IntentType: String, CaseIterable, Codable {
        case task = "task"
        case reminder = "reminder"
        case calendar = "calendar"
        case message = "message"
        case unknown = "unknown"
        
        var displayName: String {
            switch self {
            case .task: return "Task"
            case .reminder: return "Reminder"
            case .calendar: return "Calendar Event"
            case .message: return "Message"
            case .unknown: return "Unknown"
            }
        }
        
        var systemImage: String {
            switch self {
            case .task: return "checklist"
            case .reminder: return "bell"
            case .calendar: return "calendar"
            case .message: return "message"
            case .unknown: return "questionmark"
            }
        }
    }
}
