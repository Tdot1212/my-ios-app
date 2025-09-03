import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @State private var showingTaskEditor = false
    @State private var filterOption = FilterOption.all
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTasks) { task in
                    TaskRowView(task: task)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                deleteTask(task)
                            }
                        }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Filter", selection: $filterOption) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
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
    
    private var filteredTasks: [TaskItem] {
        switch filterOption {
        case .all:
            return tasks
        case .pending:
            return tasks.filter { !$0.isDone }
        case .completed:
            return tasks.filter { $0.isDone }
        }
    }
    
    private func deleteTask(_ task: TaskItem) {
        context.delete(task)
        try? context.save()
    }
}

