import SwiftUI

enum EventType: String, CaseIterable, Identifiable, Codable {
    case holidayUS, holidayCN, social, ecommerce, offline, task, reminder, personal
    var id: String { rawValue }

    var label: String {
        switch self {
        case .holidayUS: "US Holidays"
        case .holidayCN: "China Holidays"
        case .social: "Social Media"
        case .ecommerce: "E-commerce"
        case .offline: "Offline Events"
        case .task: "Tasks"
        case .reminder: "Reminders"
        case .personal: "Personal"
        }
    }
    var color: Color {
        switch self {
        case .holidayUS: .teal
        case .holidayCN: .mint
        case .social: .pink
        case .ecommerce: .orange
        case .offline: .indigo
        case .task: .blue
        case .reminder: .purple
        case .personal: .gray
        }
    }
}
