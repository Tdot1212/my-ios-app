import SwiftUI

struct VoiceCommandConfirmationView: View {
    @ObservedObject var creationService: CreationService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Intent") {
                    HStack {
                        Image(systemName: creationService.currentResult?.intent.systemImage ?? "questionmark")
                            .foregroundColor(.blue)
                        Text(creationService.currentResult?.intent.displayName ?? "Unknown")
                            .font(.headline)
                        Spacer()
                    }
                }
                
                Section("Details") {
                    TextField("Title", text: $creationService.editedTitle)
                    
                    DatePicker("Date & Time", selection: $creationService.editedDateTime, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Contact Name", text: $creationService.editedContactName)
                }
                
                Section("Original Text") {
                    Text(creationService.currentResult?.rawText ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Confirm Voice Command")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        creationService.cancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        creationService.save()
                        dismiss()
                    }
                    .disabled(creationService.editedTitle.isEmpty)
                }
            }
        }
    }
}

#Preview {
    VoiceCommandConfirmationView(creationService: CreationService.shared)
}
