import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [TaskItem]
    @State private var showingTaskEditor = false
    
    init() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let overduePredicate = #Predicate<TaskItem> { task in
            !task.isDone && task.dueDate != nil && task.dueDate! < startOfToday
        }
        
        let todayPredicate = #Predicate<TaskItem> { task in
            !task.isDone && task.dueDate != nil && task.dueDate! >= startOfToday && task.dueDate! < endOfToday
        }
        
        let combinedPredicate = #Predicate<TaskItem> { task in
            overduePredicate.evaluate(task) || todayPredicate.evaluate(task)
        }
        
        _tasks = Query(filter: combinedPredicate, sort: \TaskItem.dueDate)
    }
    
    var body: some View {
        NavigationView {
            List {
                if !overdueTasks.isEmpty {
                    Section("Overdue") {
                        ForEach(overdueTasks) { task in
                            TaskRowView(task: task)
                        }
                    }
                }
                
                if !todayTasks.isEmpty {
                    Section("Today") {
                        ForEach(todayTasks) { task in
                            TaskRowView(task: task)
                        }
                    }
                }
                
                if overdueTasks.isEmpty && todayTasks.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No tasks for today")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Tap the + button to add a new task")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTaskEditor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTaskEditor) {
                TaskEditorView()
            }
        }
    }
    
    private var overdueTasks: [TaskItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return tasks.filter { !$0.isDone && $0.dueDate != nil && $0.dueDate! < startOfToday }
    }
    
    private var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        return tasks.filter { !$0.isDone && $0.dueDate != nil && $0.dueDate! >= startOfToday && $0.dueDate! < endOfToday }
    }
}

struct TaskRowView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var context
    
    var body: some View {
        HStack {
            Button(action: {
                task.isDone.toggle()
                try? context.save()
            }) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isDone ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isDone)
                    .foregroundColor(task.isDone ? .gray : .primary)
                
                if let note = task.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if let label = task.label {
                Circle()
                    .fill(Color(hex: label.colorHex))
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 4)
    }
}
