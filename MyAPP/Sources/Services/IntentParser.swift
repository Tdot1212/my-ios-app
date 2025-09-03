import Foundation
import EventKit

class IntentParser {
    static func parse(_ text: String) -> IntentResult {
        let lowercased = text.lowercased()
        
        // Determine intent type
        let intent: IntentResult.IntentType
        if lowercased.contains("task") || lowercased.contains("todo") || lowercased.contains("do") {
            intent = .task
        } else if lowercased.contains("remind") || lowercased.contains("reminder") {
            intent = .reminder
        } else if lowercased.contains("meeting") || lowercased.contains("event") || lowercased.contains("appointment") {
            intent = .calendar
        } else if lowercased.contains("message") || lowercased.contains("text") || lowercased.contains("call") {
            intent = .message
        } else {
            intent = .unknown
        }
        
        // Extract title (remove intent words and time/contact info)
        var title = text
        let intentWords = ["task", "todo", "remind", "reminder", "meeting", "event", "appointment", "message", "text", "call"]
        for word in intentWords {
            title = title.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract date/time using natural language parsing
        let dateTime = parseDateTime(from: text)
        
        // Extract contact name (simple string extraction for now)
        let contactName = extractContactName(from: text)
        
        return IntentResult(
            intent: intent,
            title: title.isEmpty ? "Untitled" : title,
            dateTime: dateTime,
            contactName: contactName,
            rawText: text
        )
    }
    
    private static func parseDateTime(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let now = Date()
        let calendar = Calendar.current
        
        // Simple natural language parsing
        if lowercased.contains("today") {
            return calendar.startOfDay(for: now)
        } else if lowercased.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        } else if lowercased.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        } else if lowercased.contains("in an hour") {
            return calendar.date(byAdding: .hour, value: 1, to: now)
        } else if lowercased.contains("in 2 hours") {
            return calendar.date(byAdding: .hour, value: 2, to: now)
        }
        
        // Try to parse specific time patterns
        let timePatterns = [
            "at \\d{1,2}(?::\\d{2})?\\s*(am|pm)?": { match in
                // Extract time and set to today
                return calendar.startOfDay(for: now)
            }
        ]
        
        for pattern in timePatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                return pattern(match)
            }
        }
        
        return nil
    }
    
    private static func extractContactName(from text: String) -> String? {
        // Simple contact extraction - look for "with" or "to" followed by a name
        let lowercased = text.lowercased()
        
        if let withRange = lowercased.range(of: "with ") {
            let afterWith = String(text[withRange.upperBound...])
            let words = afterWith.components(separatedBy: .whitespaces)
            if let firstName = words.first, !firstName.isEmpty {
                return firstName.capitalized
            }
        }
        
        if let toRange = lowercased.range(of: "to ") {
            let afterTo = String(text[toRange.upperBound...])
            let words = afterTo.components(separatedBy: .whitespaces)
            if let firstName = words.first, !firstName.isEmpty {
                return firstName.capitalized
            }
        }
        
        return nil
    }
}
