import Foundation
import SwiftData

/// Generates US federal holidays for a given year and inserts CalendarEvent records.
/// `category` is "holidayUS" and `country` is "US".
enum USFederalHolidays {

    static func importYear(_ year: Int, into context: ModelContext) {
        let cal = Calendar(identifier: .gregorian)
        func fixed(_ month: Int, _ day: Int, _ title: String) {
            guard let s = cal.date(from: DateComponents(year: year, month: month, day: day)) else { return }
            insert(title: title, start: s, end: s, context: context)
        }

        func nthWeekday(_ n: Int, weekday: Int, month: Int, title: String) {
            guard let firstOfMonth = cal.date(from: DateComponents(year: year, month: month, day: 1)) else { return }
            var comps = cal.dateComponents([.year, .month, .weekday, .weekOfMonth], from: firstOfMonth)
            comps.weekday = weekday
            comps.weekOfMonth = n
            if let d = cal.nextDate(after: firstOfMonth, matching: comps, matchingPolicy: .nextTime, direction: .forward) {
                insert(title: title, start: d, end: d, context: context)
            }
        }

        func lastWeekday(_ weekday: Int, month: Int, title: String) {
            guard let first = cal.date(from: DateComponents(year: year, month: month, day: 1)),
                  let range = cal.range(of: .day, in: .month, for: first),
                  let last = cal.date(from: DateComponents(year: year, month: month, day: range.count)) else { return }
            // Walk backward to the requested weekday
            var d = last
            while cal.component(.weekday, from: d) != weekday {
                guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
                d = prev
            }
            insert(title: title, start: d, end: d, context: context)
        }

        // MARK: - US Federal (core set)
        fixed(1, 1,  "New Year's Day")                                      // Jan 1
        nthWeekday(3, weekday: 2, month: 1,  title: "Martin Luther King Jr. Day") // 3rd Monday Jan
        nthWeekday(3, weekday: 2, month: 2,  title: "Presidents' Day")            // 3rd Monday Feb
        lastWeekday(2, month: 5, title: "Memorial Day")                            // Last Monday May
        fixed(6, 19, "Juneteenth National Independence Day")               // Jun 19
        fixed(7, 4,  "Independence Day")                                   // Jul 4
        nthWeekday(1, weekday: 2, month: 9,  title: "Labor Day")                 // 1st Monday Sep
        nthWeekday(2, weekday: 2, month: 10, title: "Columbus Day")              // 2nd Monday Oct
        fixed(11, 11,"Veterans Day")                                        // Nov 11
        nthWeekday(4, weekday: 5, month: 11, title: "Thanksgiving Day")         // 4th Thursday Nov
        fixed(12, 25,"Christmas Day")                                       // Dec 25
    }

    private static func insert(title: String, start: Date, end: Date, context: ModelContext) {
        // Avoid duplicate inserts for same title+day
        let startDay = Calendar.current.startOfDay(for: start)
        let existing = try? context.fetch(
            FetchDescriptor<CalendarEvent>(
                predicate: #Predicate { $0.title == title && $0.startDate == startDay }
            )
        )
        if let e = existing, e.isEmpty == false { return }

        let ev = CalendarEvent(
            title: title,
            note: "US Federal Holiday",
            startDate: startDay,
            endDate: startDay,
            category: "holidayUS",
            country: "US",
            eventType: "holidayUS"
        )
        context.insert(ev)
    }
}
