import Foundation
import UserNotifications
import SwiftData

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    static func requestAuth() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            print("Notification permission granted: \(granted)")
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    func scheduleNotification(for task: TaskItem) async throws {
        guard let dueDate = task.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due"
        content.body = task.title
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: "task-\(task.persistentModelID)", content: content, trigger: trigger)
        
        try await UNUserNotificationCenter.current().add(request)
        print("Scheduled notification for task: \(task.title)")
    }
    
    func scheduleNotification(for reminder: ReminderItem) async throws {
        guard let dueDate = reminder.dueDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = reminder.title
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: "reminder-\(reminder.persistentModelID)", content: content, trigger: trigger)
        
        try await UNUserNotificationCenter.current().add(request)
        print("Scheduled notification for reminder: \(reminder.title)")
    }
    
    func cancelNotification(for task: TaskItem) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["task-\(task.persistentModelID)"])
    }
    
    func scheduleEarlyNotification(for task: TaskItem, earlyMinutes: Int) async {
        guard let dueDate = task.dueDate else { return }
        
        let earlyDate = dueDate.addingTimeInterval(-TimeInterval(earlyMinutes * 60))
        
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "\(task.title) is due in \(earlyMinutes) minutes"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: earlyDate), repeats: false)
        
        let request = UNNotificationRequest(identifier: "task-early-\(task.persistentModelID)", content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled early notification for task: \(task.title)")
        } catch {
            print("Failed to schedule early notification: \(error)")
        }
    }
}

