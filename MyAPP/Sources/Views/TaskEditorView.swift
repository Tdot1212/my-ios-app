import SwiftUI
import SwiftData

struct TaskEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var note = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var selectedLabel: LabelTag?
    @State private var showingLabelPicker = false
    
    @Query private var labels: [LabelTag]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task title", text: $title)
                    
                    TextField("Note (optional)", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section {
                    HStack {
                        Text("Label")
                        Spacer()
                        Button(selectedLabel?.name ?? "None") {
                            showingLabelPicker = true
                        }
                        .foregroundColor(selectedLabel != nil ? Color(hex: selectedLabel!.colorHex) : .gray)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingLabelPicker) {
                LabelPickerView(selectedLabel: $selectedLabel)
            }
        }
    }
    
    private func saveTask() {
        let task = TaskItem(
            title: title,
            note: note.isEmpty ? nil : note,
            label: selectedLabel,
            dueDate: hasDueDate ? dueDate : nil
        )
        
        context.insert(task)
        
        // Schedule notification if due date is set
        if hasDueDate {
            Task {
                do {
                    try await NotificationManager.shared.scheduleNotification(for: task)
                } catch {
                    print("[ERR] Failed to schedule notification: \(error)")
                }
            }
        }
        
        try? context.save()
        dismiss()
    }
}

struct LabelPickerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLabel: LabelTag?
    
    @Query private var labels: [LabelTag]
    @State private var showingCreateLabel = false
    @State private var newLabelName = ""
    @State private var newLabelColor = "#4F46E5"
    
    private let colors = ["#4F46E5", "#EF4444", "#10B981", "#F59E0B", "#8B5CF6", "#EC4899"]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("None") {
                        selectedLabel = nil
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                Section("Labels") {
                    ForEach(labels) { label in
                        HStack {
                            Circle()
                                .fill(Color(hex: label.colorHex))
                                .frame(width: 16, height: 16)
                            Text(label.name)
                            Spacer()
                            if selectedLabel?.persistentModelID == label.persistentModelID {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLabel = label
                            dismiss()
                        }
                    }
                }
                
                Section {
                    Button("Create New Label") {
                        showingCreateLabel = true
                    }
                }
            }
            .navigationTitle("Select Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateLabel) {
                CreateLabelView { name, color in
                    let label = LabelTag(name: name, colorHex: color)
                    context.insert(label)
                    try? context.save()
                    selectedLabel = label
                    dismiss()
                }
            }
        }
    }
}

struct CreateLabelView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColor = "#4F46E5"
    
    let onSave: (String, String) -> Void
    
    private let colors = ["#4F46E5", "#EF4444", "#10B981", "#F59E0B", "#8B5CF6", "#EC4899"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Label name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name, selectedColor)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

