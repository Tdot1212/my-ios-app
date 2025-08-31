import Foundation
import SwiftData

enum CNHoliday {
    static let country = "CN"

    // Standardized titles (use these *everywhere* so colors & de-dupe work)
    static let newYear      = "New Year's Day"
    static let springEve    = "Spring Festival Eve"
    static let spring       = "Chinese New Year (Spring Festival)"
    static let qingming     = "Qingming Festival (Tomb-Sweeping Day)"
    static let labor        = "Labor Day"
    static let dragonBoat   = "Dragon Boat Festival"
    static let midAutumn    = "Mid-Autumn Festival"
    static let national     = "National Day Golden Week"

    /// Fixed-date helpers
    static func fixedDates(for year: Int) -> [(title: String, start: Date, end: Date?)] {
        let cal = Calendar(identifier: .gregorian)
        func d(_ m: Int, _ day: Int) -> Date { cal.date(from: DateComponents(year: year, month: m, day: day))! }

        // National Day is a 7-day range (Oct 1–7)
        return [
            (newYear,   d(1, 1),      nil),
            (labor,     d(5, 1),      nil),
            (national,  d(10, 1),     d(10, 7))
        ]
    }

    /// Built-in fallback for lunar/solar moving holidays (so the app works even without ICS).
    /// Source notes:
    /// - 2025 official set: CNY Jan 29, Qingming Apr 4, Dragon Boat May 31–Jun 2, Mid-Autumn Oct 6. :contentReference[oaicite:0]{index=0}
    /// - Dragon Boat 2026 Jun 19. :contentReference[oaicite:1]{index=1}
    /// - Chinese New Year 2024–2029 window (late Jan–mid Feb) reference. :contentReference[oaicite:2]{index=2}
    /// - Qingming dates 2024–2031 reference. :contentReference[oaicite:3]{index=3}
    static func fallbackMoving(for year: Int) -> [(title: String, start: Date, end: Date?)] {
        let cal = Calendar(identifier: .gregorian)
        func d(_ m: Int, _ day: Int) -> Date { cal.date(from: DateComponents(year: year, month: m, day: day))! }

        // You can extend these tables anytime (safe to re-import; we de-dupe later).
        let cny: [Int: (m: Int, d: Int)] = [
            2024:(2,10), 2025:(1,29), 2026:(2,17), 2027:(2,6), 2028:(1,26), 2029:(2,13)
        ]
        let qing: [Int: (m: Int, d: Int)] = [ // Qingming occurs Apr 4–6 depending on the year
            2024:(4,4), 2025:(4,4), 2026:(4,5), 2027:(4,5), 2028:(4,4), 2029:(4,4),
            2030:(4,5), 2031:(4,5)
        ]
        let dragon: [Int: (m: Int, d: Int)] = [
            2025:(5,31), 2026:(6,19) // add more when you like
        ]
        let midAut: [Int: (m: Int, d: Int)] = [
            2025:(10,6), 2026:(9,25) // add more when you like
        ]

        var rows: [(String, Date, Date?)] = []

        if let c = cny[year] {
            rows.append((spring, d(c.m, c.d), nil))
            rows.append((springEve, Calendar.current.date(byAdding: .day, value: -1, to: d(c.m, c.d))!, nil))
        }
        if let q = qing[year] { rows.append((qingming, d(q.m, q.d), nil)) }
        if let dr = dragon[year] {
            let start = d(dr.m, dr.d)
            let end   = Calendar.current.date(byAdding: .day, value: 2, to: start)! // typical 3-day holiday
            rows.append((dragonBoat, start, end))
        }
        if let ma = midAut[year] { rows.append((midAutumn, d(ma.m, ma.d), nil)) }
        return rows
    }
}

enum ChinaHolidayImporter {
    /// Import CN holidays for a year range. Currently uses built-in fallback data.
    /// Future: Add ICS import capability when ICSImporter is available.
    static func importYears(_ years: ClosedRange<Int>,
                            context: ModelContext,
                            icsURL: URL? = nil) async
    {
        // 1) ICS first (keeps future years fresh)
        if let url = icsURL {
            await ICSImporter.importICS(from: url, filterYears: Set(years), country: CNHoliday.country, category: "holidayCN", context: context)
        }

        // 2) Fixed + moving fallback
        for y in years {
            for row in CNHoliday.fixedDates(for: y) + CNHoliday.fallbackMoving(for: y) {
                insert(
                    title: row.title,
                    start: row.start,
                    end: row.end,
                    context: context
                )
            }
        }

        try? context.save()
    }
    
    private static func insert(title: String, start: Date, end: Date?, context: ModelContext) {
        let day = Calendar.current.startOfDay(for: start)
        let existing = try? context.fetch(
            FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.title == title && $0.startDate == day })
        )
        if let e = existing, e.isEmpty == false { return }
        
        let ev = CalendarEvent(
            title: title,
            note: "Chinese Holiday",
            startDate: day,
            endDate: end != nil ? Calendar.current.startOfDay(for: end!) : day,
            category: "holidayCN",
            country: CNHoliday.country,
            eventType: "holidayCN"
        )
        context.insert(ev)
    }
}
