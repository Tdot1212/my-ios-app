import Foundation
import SwiftData

enum ICSImporter {
    static func importICS(from url: URL,
                          filterYears: Set<Int>,
                          country: String,
                          category: String,
                          context: ModelContext) async
    {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let text = String(data: data, encoding: .utf8) else { return }

            // Very small parser: reads DTSTART/DTEND/SUMMARY lines
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

            var summary: String?
            var dtStart: Date?
            var dtEnd: Date?

            let fmt = DateFormatter()
            fmt.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            fmt.timeZone = TimeZone(secondsFromGMT: 0)

            func flush() {
                if let s = summary, let start = dtStart {
                    let year = Calendar.current.component(.year, from: start)
                    if filterYears.contains(year) {
                        insert(
                            title: s.trimmed(),
                            start: start,
                            end: dtEnd,
                            category: category,
                            country: country,
                            context: context
                        )
                    }
                }
                summary = nil; dtStart = nil; dtEnd = nil
            }

            for line in lines {
                if line.hasPrefix("BEGIN:VEVENT") { flush() }
                if line.hasPrefix("SUMMARY:") { summary = String(line.dropFirst(8)) }
                if line.hasPrefix("DTSTART:") {
                    let raw = String(line.dropFirst(8))
                    dtStart = fmt.date(from: raw) ?? DateOnlyParser.parseYYYYMMDD(raw)
                }
                if line.hasPrefix("DTEND:") {
                    let raw = String(line.dropFirst(6))
                    dtEnd = fmt.date(from: raw) ?? DateOnlyParser.parseYYYYMMDD(raw)
                }
                if line.hasPrefix("END:VEVENT") { flush() }
            }
            try? context.save()
        } catch {
            print("ICS import failed:", error)
        }
    }
}

enum DateOnlyParser {
    /// Accepts YYYYMMDD (all-day ICS) and returns Date at 00:00 local
    static func parseYYYYMMDD(_ s: String) -> Date? {
        guard s.count == 8,
              let y = Int(s.prefix(4)),
              let m = Int(s.dropFirst(4).prefix(2)),
              let d = Int(s.suffix(2))
        else { return nil }
        return Calendar.current.date(from: DateComponents(year: y, month: m, day: d))
    }
}

extension String { func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) } }

private func insert(title: String, start: Date, end: Date?, category: String, country: String, context: ModelContext) {
    let day = Calendar.current.startOfDay(for: start)
    let existing = try? context.fetch(
        FetchDescriptor<CalendarEvent>(predicate: #Predicate { $0.title == title && $0.startDate == day })
    )
    if let e = existing, e.isEmpty == false { return }
    
    let ev = CalendarEvent(
        title: title,
        note: "Imported from ICS",
        startDate: day,
        endDate: end != nil ? Calendar.current.startOfDay(for: end!) : day,
        category: category,
        country: country,
        eventType: category
    )
    context.insert(ev)
}
