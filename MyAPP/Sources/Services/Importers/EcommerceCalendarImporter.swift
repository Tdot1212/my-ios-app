import Foundation
import SwiftData

enum EcommerceCalendarImporter {
    static func importYear(_ year: Int, into context: ModelContext) {
        let cal = Calendar(identifier: .gregorian)
        func fixed(_ m:Int,_ d:Int,_ title:String) {
            guard let dt = cal.date(from: .init(year: year, month: m, day: d)) else { return }
            insert(title: title, start: dt, end: dt, context: context)
        }
        func range(_ m1:Int,_ d1:Int,_ m2:Int,_ d2:Int,_ title:String) {
            guard let s = cal.date(from: .init(year: year, month: m1, day: d1)),
                  let e = cal.date(from: .init(year: year, month: m2, day: d2)) else { return }
            insert(title: title, start: s, end: e, context: context)
        }
        func nthWeekday(_ n:Int, _ wk:Int, _ m:Int, _ title:String) {
            guard let first = cal.date(from: .init(year: year, month: m, day: 1)) else { return }
            var comps = DateComponents(year: year, month: m, weekday: wk, weekOfMonth: n)
            if let d = cal.nextDate(after: first, matching: comps, matchingPolicy: .nextTime, direction: .forward) {
                insert(title: title, start: d, end: d, context: context)
            }
        }
        func lastWeekday(_ wk:Int,_ m:Int,_ title:String) {
            guard let first = cal.date(from: .init(year: year, month: m, day: 1)),
                  let range = cal.range(of: .day, in: .month, for: first),
                  let last = cal.date(from: .init(year: year, month: m, day: range.count)) else { return }
            var d = last
            while cal.component(.weekday, from: d) != wk { d = cal.date(byAdding: .day, value: -1, to: d)! }
            insert(title: title, start: d, end: d, context: context)
        }
        func easterSunday() -> Date { // same as Social
            let a = year % 19, b = year / 100, c = year % 100
            let d = b / 4, e = b % 4, f = (b + 8) / 25, g = (b - f + 1) / 3
            let h = (19*a + b - d - g + 15) % 30, i = c / 4, k = c % 4
            let l = (32 + 2*e + 2*i - h - k) % 7, m = (a + 11*h + 22*l) / 451
            let month = (h + l - 7*m + 114) / 31
            let day = ((h + l - 7*m + 114) % 31) + 1
            return Calendar.current.date(from: .init(year: year, month: month, day: day))!
        }

        // Key commercial moments
        // January
        fixed(1, 1, "New Year's Day")
        // Chinese New Year (Lunar) → will be added with China importer
        // February
        fixed(2,14, "Valentine's Day")
        // March
        fixed(3, 8, "International Women's Day")
        // April
        insert(title: "Easter", start: easterSunday(), end: easterSunday(), context: context)
        // May
        nthWeekday(2, 1, 5, "Mother's Day")
        lastWeekday(2, 5, "Memorial Day")
        // June
        nthWeekday(3, 1, 6, "Father's Day")
        // July
        insert(title: "Amazon Prime Day (TBD)", start: cal.date(from: .init(year: year, month: 7, day: 15))!, end: cal.date(from: .init(year: year, month: 7, day: 15))!, context: context)
        fixed(7, 4, "Independence Day")
        // August–September Back to School
        range(8, 15, 9, 10, "Back to School")
        fixed(8,14, "APORRO 8th Anniversary")
        // September
        nthWeekday(1, 2, 9, "Labor Day")
        // October
        fixed(10,31, "Halloween")
        // November (based on Thanksgiving)
        if let tg = nthDate(.thursday, weekOfMonth: 4, month: 11, year: year) {
            // Thanksgiving is 4th Thu (already in US holiday)
            insert(title: "Black Friday", start: Calendar.current.date(byAdding: .day, value: 1, to: tg)!, end: Calendar.current.date(byAdding: .day, value: 1, to: tg)!, context: context)
            insert(title: "Cyber Monday", start: Calendar.current.date(byAdding: .day, value: 4, to: tg)!, end: Calendar.current.date(byAdding: .day, value: 4, to: tg)!, context: context)
        }
        // December
        // Green Monday: 2nd Monday of Dec
        nthWeekday(2, 2, 12, "Green Monday")
        // Super Saturday: last Saturday before Christmas
        if let xmas = cal.date(from: .init(year: year, month: 12, day: 25)) {
            var d = Calendar.current.date(byAdding: .day, value: -1, to: xmas)!
            while Calendar.current.component(.weekday, from: d) != 7 { d = Calendar.current.date(byAdding: .day, value: -1, to: d)! }
            insert(title: "Super Saturday (Panic Saturday)", start: d, end: d, context: context)
        }
        insert(title: "Christmas Eve & Day", start: cal.date(from: .init(year: year, month: 12, day: 24))!, end: cal.date(from: .init(year: year, month: 12, day: 25))!, context: context)
        fixed(12,31, "New Year's Eve")
    }

    private static func insert(title: String, start: Date, end: Date, context: ModelContext) {
        let day = Calendar.current.startOfDay(for: start)
        let existing = try? context.fetch(
            FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.title == title && $0.startDate == day })
        )
        if let e = existing, e.isEmpty == false { return }
        let ev = CalendarEvent(
            title: title,
            note: "E-commerce",
            startDate: day,
            endDate: Calendar.current.startOfDay(for: end),
            category: "ecommerce",
            country: "US",
            eventType: "ecommerce"
        )
        context.insert(ev)
    }
}

private enum Weekday: Int { case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday }
private func nthDate(_ weekday: Weekday, weekOfMonth: Int, month: Int, year: Int) -> Date? {
    let cal = Calendar.current
    guard let first = cal.date(from: .init(year: year, month: month, day: 1)) else { return nil }
    var comps = DateComponents(year: year, month: month, weekday: weekday.rawValue, weekOfMonth: weekOfMonth)
    return cal.nextDate(after: first, matching: comps, matchingPolicy: .nextTime, direction: .forward)
}
