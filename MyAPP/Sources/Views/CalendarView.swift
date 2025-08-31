import SwiftUI
import SwiftData

enum CalendarMode: String, CaseIterable, Identifiable { case month, list; var id: String { rawValue } }

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @State private var mode: CalendarMode = .month
    @State private var currentMonth = Date()
    @State private var filter = CalendarFilterState()

    @State private var rows: [CalendarRow] = []
    @State private var ribbons: [CalendarRow] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                header

                Picker("TimeView", selection: $mode) {
                    Label("Month", systemImage: "square.grid.2x2").tag(CalendarMode.month)
                    Label("List",  systemImage: "list.bullet").tag(CalendarMode.list)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if mode == .month {
                    MonthCalendarView(month: $currentMonth, rows: rows, filter: filter, ribbons: ribbons)
                } else {
                    CalendarListView(month: currentMonth, rows: rows)
                }
            }
            .navigationTitle("Calendar")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { filterMenu } }
            .onAppear(perform: reload)
            .onChange(of: currentMonth) { _, _ in reload() }
            .onChange(of: filterHash) { _, _ in reload() }
        }
    }

    private var header: some View {
        HStack {
            Button { stepMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(currentMonth, format: .dateTime.month(.wide).year()).font(.title2.bold())
            Spacer()
            Button { stepMonth(+1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
    }

    private var filterMenu: some View {
        Menu {
            Section("Show Event Types") {
                Button("Show All") { filter.showAll() }
                Button("Show None") { filter.showNone() }
            }
            Divider()
            Toggle(EventType.holidayUS.label, isOn: $filter.showHolidayUS)
            Toggle(EventType.holidayCN.label, isOn: $filter.showHolidayCN)
            Toggle(EventType.social.label,    isOn: $filter.showSocial)
            Toggle(EventType.ecommerce.label, isOn: $filter.showEcomm)
            Toggle(EventType.offline.label,   isOn: $filter.showOffline)
            Toggle(EventType.task.label,      isOn: $filter.showTask)
            Toggle(EventType.reminder.label,  isOn: $filter.showReminder)
            Toggle(EventType.personal.label,  isOn: $filter.showPersonal)
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private func stepMonth(_ delta: Int) {
        currentMonth = Calendar.current.date(byAdding: .month, value: delta, to: currentMonth) ?? currentMonth
    }

    private func reload() {
        (rows, ribbons) = buildCalendarRows(context: context, month: currentMonth, filter: filter)
    }

    // Changing any filter bool should reload rows:
    private var filterHash: Int {
        var h = 0
        h = h &* 31 &+ (filter.showHolidayUS ? 1 : 0)
        h = h &* 31 &+ (filter.showHolidayCN ? 1 : 0)
        h = h &* 31 &+ (filter.showSocial ? 1 : 0)
        h = h &* 31 &+ (filter.showEcomm ? 1 : 0)
        h = h &* 31 &+ (filter.showOffline ? 1 : 0)
        h = h &* 31 &+ (filter.showTask ? 1 : 0)
        h = h &* 31 &+ (filter.showReminder ? 1 : 0)
        h = h &* 31 &+ (filter.showPersonal ? 1 : 0)
        return h
    }
}

struct MonthCalendarView: View {
    @Binding var month: Date
    let rows: [CalendarRow]
    let filter: CalendarFilterState
    let ribbons: [CalendarRow]

    private var monthSpanningEvents: [CalendarRow] {
        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        
        return rows.filter { event in
            // Check if event starts and ends in the same month
            let startsInMonth = calendar.isDate(event.start, equalTo: firstOfMonth, toGranularity: .month)
            let endsInMonth = calendar.isDate(event.end, equalTo: firstOfMonth, toGranularity: .month)
            
            // Check if event spans the entire month (from first to last day)
            let monthRange = calendar.range(of: .day, in: .month, for: firstOfMonth)!
            let lastOfMonth = calendar.date(byAdding: .day, value: monthRange.count - 1, to: firstOfMonth)!
            
            let spansEntireMonth = calendar.isDate(event.start, inSameDayAs: firstOfMonth) && 
                                  calendar.isDate(event.end, inSameDayAs: lastOfMonth)
            
            return startsInMonth && endsInMonth && spansEntireMonth
        }
    }

    private var weeks: [[Date]] {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year,.month], from: month))!
        let range = cal.range(of: .day, in: .month, for: start)!
        let firstWeekday = cal.component(.weekday, from: start) // 1=Sun…
        var days: [Date] = []
        for _ in 1..<firstWeekday { days.append(.distantPast) } // leading blanks
        for d in range {
            let day = cal.date(byAdding: .day, value: d-1, to: start)!
            days.append(day)
        }
        while days.count % 7 != 0 { days.append(.distantFuture) } // trailing blanks
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0+7]) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month-long ribbons (Pride, Movember, etc.)
            if monthSpanningEvents.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(monthSpanningEvents) { r in
                            Text(r.title)
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(r.type.color.opacity(0.15))
                                .foregroundStyle(r.type.color)
                                .clipShape(Capsule())
                        }
                    }.padding(.horizontal)
                }
            }

            // Weekday symbols
            HStack {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { s in
                    Text(s).font(.caption).frame(maxWidth: .infinity)
                }
            }.padding(.horizontal, 8).foregroundStyle(.secondary)

            // Grid
            VStack(spacing: 8) {
                ForEach(weeks.indices, id: \.self) { wi in
                    HStack(spacing: 8) {
                        ForEach(weeks[wi], id: \.self) { day in
                            DayCell(day: day, month: month, items: items(on: day))
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func items(on date: Date) -> [CalendarRow] {
        let cal = Calendar.current
        return rows.filter { event in
            // Don't show month-spanning events in individual day cells
            if monthSpanningEvents.contains(where: { $0.id == event.id }) {
                return false
            }
            return cal.isDate(event.start, inSameDayAs: date)
        }
    }
}

private struct DayCell: View {
    let day: Date
    let month: Date
    let items: [CalendarRow]

    var inMonth: Bool {
        guard day != .distantPast && day != .distantFuture else { return false }
        return Calendar.current.isDate(day, equalTo: month, toGranularity: .month)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if inMonth {
                Text(day, format: .dateTime.day())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                // show up to 3 lines of titles (or dots)
                ForEach(items.prefix(3)) { row in
                    HStack(spacing: 6) {
                        Circle().fill(row.type.color).frame(width: 6, height: 6)
                        Text(row.title)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(3)                 // or .lineLimit(nil) on iOS 17+
                            .minimumScaleFactor(0.82)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(minHeight: 82)
        .padding(8)
        .background(
            inMonth ? Color(.systemGray6) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .opacity(inMonth ? 1 : 0)
    }
}

struct CalendarListView: View {
    let month: Date
    let rows: [CalendarRow]

    var grouped: [(Date,[CalendarRow])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: rows) { cal.startOfDay(for: $0.start) }
        return dict.keys.sorted().map { ($0, dict[$0]!.sorted{ $0.start < $1.start }) }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { day, items in
                Section {
                    ForEach(items) { r in
                        HStack(alignment: .top, spacing: 12) {
                            VStack {
                                Text(day.formatted(.dateTime.weekday(.abbreviated))).font(.caption).foregroundStyle(.secondary)
                                Text(day.formatted(.dateTime.day())).font(.title2.weight(.bold))
                            }.frame(width: 56)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.title)
                                    .font(.footnote.weight(.semibold))
                                    .lineLimit(3)                 // or .lineLimit(nil) on iOS 17+
                                    .minimumScaleFactor(0.82)
                                if let s = r.subtitle, s.isEmpty == false { Text(s).foregroundStyle(.secondary) }
                                Text(timeRange(r)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Circle().fill(r.type.color).frame(width: 10, height: 10)
                        }.padding(.vertical, 4)
                    }
                } header: {
                    Text(day, format: .dateTime.month(.wide).day()).font(.headline)
                }
            }
        }.listStyle(.plain)
    }

    private func timeRange(_ r: CalendarRow) -> String {
        if Calendar.current.isDate(r.start, inSameDayAs: r.end) == false {
            return "\(r.start.formatted(date: .abbreviated, time: .shortened)) → \(r.end.formatted(date: .abbreviated, time: .shortened))"
        }
        return r.start.formatted(date: .omitted, time: .shortened)
    }
}




