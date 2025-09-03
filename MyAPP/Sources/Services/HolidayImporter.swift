import Foundation
import SwiftData

@MainActor
class HolidayImporter: ObservableObject {
    static let shared = HolidayImporter()
    
    private let usHolidaysURL = "https://calendar.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics"
    private let cnHolidaysURL = "https://calendar.google.com/calendar/ical/zh.cn%23holiday%40group.v.calendar.google.com/public/basic.ics"
    
    private init() {}
    
    func importHolidays(context: ModelContext) async throws {
        // Import US holidays
        try await importHolidaysFromURL(usHolidaysURL, country: "US", context: context)
        
        // Import CN holidays
        try await importHolidaysFromURL(cnHolidaysURL, country: "CN", context: context)
    }
    
    private func importHolidaysFromURL(_ urlString: String, country: String, context: ModelContext) async throws {
        guard let url = URL(string: urlString) else {
            throw HolidayError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HolidayError.requestFailed
        }
        
        guard let icsContent = String(data: data, encoding: .utf8) else {
            throw HolidayError.invalidData
        }
        
        let events = try parseICS(icsContent, country: country)
        
        for event in events {
            context.insert(event)
        }
        
        try context.save()
        print("Imported \(events.count) \(country) holidays")
    }
    
    private func parseICS(_ content: String, country: String) throws -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentEvent: (title: String, startDate: Date, endDate: Date)?
        
        for line in lines {
            if line.hasPrefix("BEGIN:VEVENT") {
                currentEvent = nil
            } else if line.hasPrefix("SUMMARY:") {
                let title = String(line.dropFirst(8))
                if let event = currentEvent {
                    currentEvent = (title: title, startDate: event.startDate, endDate: event.endDate)
                }
            } else if line.hasPrefix("DTSTART:") {
                let dateString = String(line.dropFirst(8))
                if let date = parseICSDate(dateString) {
                    if let event = currentEvent {
                        currentEvent = (title: event.title, startDate: date, endDate: event.endDate)
                    } else {
                        currentEvent = (title: "", startDate: date, endDate: date)
                    }
                }
            } else if line.hasPrefix("DTEND:") {
                let dateString = String(line.dropFirst(6))
                if let date = parseICSDate(dateString) {
                    if let event = currentEvent {
                        currentEvent = (title: event.title, startDate: event.startDate, endDate: date)
                    }
                }
            } else if line.hasPrefix("END:VEVENT") {
                if let event = currentEvent, !event.title.isEmpty {
                    let calendarEvent = CalendarEvent(
                        title: event.title,
                        startDate: event.startDate,
                        endDate: event.endDate,
                        category: "holiday",
                        country: country
                    )
                    events.append(calendarEvent)
                }
                currentEvent = nil
            }
        }
        
        return events
    }
    
    private func parseICSDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without time
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: dateString)
    }
}

enum HolidayError: Error {
    case invalidURL
    case requestFailed
    case invalidData
}

