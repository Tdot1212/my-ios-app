import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \NoteItem.createdAt, order: .reverse) private var notes: [NoteItem]
    @State private var showingNoteEditor = false
    @State private var selectedNote: NoteItem?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    NoteRowView(note: note) {
                        selectedNote = note
                    }
                }
                .onDelete(perform: deleteNotes)
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNoteEditor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNoteEditor) {
                NoteEditorView()
            }
            .sheet(item: $selectedNote) { note in
                NoteDetailView(note: note)
            }
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        for index in offsets {
            context.delete(notes[index])
        }
        try? context.save()
    }
}

struct NoteRowView: View {
    let note: NoteItem
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.content)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            Text(note.createdAt, style: .date)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $content)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() {
        let note = NoteItem(content: content)
        context.insert(note)
        try? context.save()
        dismiss()
    }
}

struct NoteDetailView: View {
    let note: NoteItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingAIError = false
    @State private var aiErrorMessage = ""
    @State private var isProcessingAI = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(note.content)
                        .padding()
                    
                    Divider()
                    
                    HStack {
                        Button("Translate to Chinese") {
                            translateToChinese()
                        }
                        .disabled(isProcessingAI)
                        
                        Spacer()
                        
                        Button("Summarize") {
                            summarize()
                        }
                        .disabled(isProcessingAI)
                    }
                    .padding(.horizontal)
                    
                    if isProcessingAI {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing...")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("AI Error", isPresented: $showingAIError) {
                Button("OK") { }
            } message: {
                Text(aiErrorMessage)
            }
        }
    }
    
    private func translateToChinese() {
        isProcessingAI = true
        
        Task {
            do {
                let translation = try await DeepSeekClient.shared.translateToChinese(note.content)
                await MainActor.run {
                    let translatedNote = NoteItem(content: "Translation:\n\(translation)")
                    context.insert(translatedNote)
                    try? context.save()
                    isProcessingAI = false
                }
            } catch {
                await MainActor.run {
                    aiErrorMessage = "Failed to translate: \(error.localizedDescription)"
                    showingAIError = true
                    isProcessingAI = false
                }
            }
        }
    }
    
    private func summarize() {
        isProcessingAI = true
        
        Task {
            do {
                let summary = try await DeepSeekClient.shared.summarize(note.content)
                await MainActor.run {
                    let summaryNote = NoteItem(content: "Summary:\n\(summary)")
                    context.insert(summaryNote)
                    try? context.save()
                    isProcessingAI = false
                }
            } catch {
                await MainActor.run {
                    aiErrorMessage = "Failed to summarize: \(error.localizedDescription)"
                    showingAIError = true
                    isProcessingAI = false
                }
            }
        }
    }
}








