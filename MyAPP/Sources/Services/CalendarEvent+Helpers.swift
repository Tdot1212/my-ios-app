import Foundation
import SwiftData

struct CalendarRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let start: Date
    let end: Date
    let type: EventType
}

extension CalendarEvent {
    var eventTypeEnum: EventType {
        EventType(rawValue: eventType) ?? .personal
    }
    var isAllDay: Bool {
        Calendar.current.startOfDay(for: startDate) == startDate &&
        Calendar.current.startOfDay(for: endDate) == endDate
    }
    func spansEntire(month: Date) -> Bool {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: month),
              let first = cal.date(from: cal.dateComponents([.year,.month], from: month)) else { return false }
        let last = cal.date(byAdding: .day, value: range.count - 1, to: first)!
        return startDate <= first && endDate >= last
    }
}

func buildCalendarRows(context: ModelContext, month: Date, filter: CalendarFilterState) -> ([CalendarRow], [CalendarRow]) {
    let cal = Calendar.current
    let monthStart = cal.date(from: cal.dateComponents([.year,.month], from: month))!
    let monthRange = cal.range(of: .day, in: .month, for: monthStart)!
    let monthEnd = cal.date(byAdding: .day, value: monthRange.count, to: monthStart)!

    var rows: [CalendarRow] = []
    var ribbons: [CalendarRow] = []

    // 1) CalendarEvents
    let events = try? context.fetch(FetchDescriptor<CalendarEvent>())
    for ev in events ?? [] {
        let type = ev.eventTypeEnum
        guard filter.includes(type) else { continue }
        let s = ev.startDate
        let e = ev.endDate
        if (s <= monthEnd && e >= monthStart) {
            let r = CalendarRow(title: ev.title,
                                subtitle: ev.note,
                                start: s, end: e, type: type)
            if ev.spansEntire(month: monthStart) { ribbons.append(r) } else { rows.append(r) }
        }
    }

    // 2) Tasks
    if filter.includes(.task) {
        let tasks = try? context.fetch(FetchDescriptor<TaskItem>())
        for t in tasks ?? [] {
            guard let d = t.dueDate, (d >= monthStart && d < monthEnd) else { continue }
            rows.append(CalendarRow(title: t.title, subtitle: "Task", start: d, end: d, type: .task))
        }
    }

    // 3) Reminders
    if filter.includes(.reminder) {
        let rems = try? context.fetch(FetchDescriptor<ReminderItem>())
        for r in rems ?? [] {
            guard let d = r.dueDate, (d >= monthStart && d < monthEnd) else { continue }
            rows.append(CalendarRow(title: r.title, subtitle: "Reminder", start: d, end: d, type: .reminder))
        }
    }

    // After collecting `rows` and `ribbons`:
    let prio: [EventType:Int] = [
        .holidayUS: 0, .ecommerce: 1, .social: 2, .offline: 3, .personal: 4, .task: 5, .reminder: 6
    ]

    func dedupe(_ arr: [CalendarRow]) -> [CalendarRow] {
        var dict: [String: CalendarRow] = [:]
        let cal = Calendar.current
        for r in arr {
            let k = "\(cal.startOfDay(for: r.start).timeIntervalSince1970)|\(r.title.lowercased())"
            if let e = dict[k] {
                let eP = prio[e.type] ?? 999
                let rP = prio[r.type] ?? 999
                if rP < eP { dict[k] = r } // keep higher priority (smaller number)
            } else {
                dict[k] = r
            }
        }
        return Array(dict.values).sorted { $0.start < $1.start }
    }

    rows = dedupe(rows)
    ribbons = dedupe(ribbons)
    return (rows, ribbons)
}
