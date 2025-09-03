import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @State private var showingTaskEditor = false
    @State private var isRecording = false
    
    @Query private var tasks: [TaskItem]
    @Query private var reminders: [ReminderItem]
    
    private var todaysTasks: [TaskItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow && !task.isDone
        }
    }
    
    private var todaysReminders: [ReminderItem] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return reminders.filter { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dashboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Welcome back! Here's your summary for today.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        // Cards
                        VStack(spacing: 16) {
                            // Today's Tasks Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "list.bullet.clipboard")
                                        .foregroundColor(Color(hex: "#4F46E5"))
                                    Text("Today's Tasks")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                if todaysTasks.isEmpty {
                                    Text("No tasks due today...")
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    Text("\(todaysTasks.count) due today")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Today's Reminders Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "checklist.checked")
                                        .foregroundColor(Color(hex: "#4F46E5"))
                                    Text("Today's Reminders")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                if todaysReminders.isEmpty {
                                    Text("No reminders due today...")
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    Text("\(todaysReminders.count) due today")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100) // Space for floating mic button
                    }
                    .padding(.top)
                }
                
                // Floating Mic Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // TODO: Implement voice recording
                            print("Mic button tapped")
                        }) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(
                                    Circle()
                                        .fill(isRecording ? Color.red : Color(hex: "#4F46E5"))
                                )
                                .shadow(radius: 8)
                        }
                        .accessibilityLabel("Voice command")
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.1, maximumDistance: .infinity)
                                .onEnded { _ in
                                    // Release gesture
                                    isRecording = false
                                    // TODO: Stop recording and process
                                }
                                .onChanged { pressing in
                                    isRecording = pressing
                                    if pressing {
                                        // TODO: Start recording
                                    }
                                }
                        )
                        Spacer()
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Task") {
                        showingTaskEditor = true
                    }
                }
            }
            .sheet(isPresented: $showingTaskEditor) {
                TaskEditorView()
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [TaskItem.self, ReminderItem.self, NoteItem.self, CalendarEvent.self, LabelTag.self], inMemory: true)
}
