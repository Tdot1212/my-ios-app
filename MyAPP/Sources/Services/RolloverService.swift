import Foundation
import SwiftData

@MainActor
class RolloverService {
    static func autoRollover(_ context: ModelContext) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate<TaskItem> { task in
                !task.isDone && task.dueDate != nil && task.dueDate! < startOfToday
            }
        )
        
        do {
            let overdueTasks = try context.fetch(descriptor)
            for task in overdueTasks {
                if let dueDate = task.dueDate {
                    // Roll over to next day
                    task.dueDate = calendar.date(byAdding: .day, value: 1, to: dueDate)
                }
            }
            try context.save()
            print("Rolled over \(overdueTasks.count) overdue tasks")
        } catch {
            print("Failed to roll over tasks: \(error)")
        }
    }
}

