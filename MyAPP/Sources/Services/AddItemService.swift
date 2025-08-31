import Foundation
import SwiftData

@MainActor
class AddItemService: ObservableObject {
    static let shared = AddItemService()
    
    private init() {}
    
    func processVoiceCommand(_ parsedCommand: ParsedCommand, context: ModelContext) async throws {
        // TODO: Implement full voice command processing
        print("[AddItemService] Processing command: \(parsedCommand)")
        
        // Create TaskItem
        let task = TaskItem(
            title: parsedCommand.title,
            dueDate: parsedCommand.dueDate
        )
        context.insert(task)
        
        // Create ReminderItem and schedule notification if due date exists
        if let dueDate = parsedCommand.dueDate {
            let reminder = ReminderItem(
                title: parsedCommand.title,
                dueDate: dueDate
            )
            context.insert(reminder)
            
            // TODO: Schedule notification
            // await NotificationManager.shared.scheduleNotification(for: reminder)
        }
        
        // Create CalendarEvent if due date exists
        if let dueDate = parsedCommand.dueDate {
            let endDate = Calendar.current.date(byAdding: .minute, value: 30, to: dueDate)!
            let calendarEvent = CalendarEvent(
                title: parsedCommand.title,
                startDate: dueDate,
                endDate: endDate,
                category: "personal",
                eventType: "personal"
            )
            context.insert(calendarEvent)
        }
        
        // Create NoteItem with DeepSeek draft if person exists
        if let person = parsedCommand.person {
            // TODO: Call DeepSeek to draft message
            let draftMessage = "Draft to \(person): TODO - Generate message using DeepSeek"
            let note = NoteItem(content: draftMessage)
            context.insert(note)
        }
        
        try context.save()
    }
    
    private func generateDeepSeekDraft(person: String, title: String, dueDate: Date?) async throws -> String {
        // TODO: Implement DeepSeek API call
        return "TODO: Generate draft message"
    }
}
