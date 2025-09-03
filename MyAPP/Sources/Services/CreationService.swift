import Foundation
import SwiftUI

@MainActor
class CreationService: ObservableObject {
    static let shared = CreationService()
    
    @Published var showingConfirmation = false
    @Published var currentResult: IntentResult?
    @Published var editedTitle = ""
    @Published var editedDateTime: Date = Date()
    @Published var editedContactName = ""
    
    private init() {}
    
    func apply(result: IntentResult) {
        currentResult = result
        editedTitle = result.title
        editedDateTime = result.dateTime ?? Date()
        editedContactName = result.contactName ?? ""
        showingConfirmation = true
        
        print("[CreationService] Parsed intent: \(result.intent.rawValue)")
        print("[CreationService] Title: \(result.title)")
        print("[CreationService] DateTime: \(result.dateTime?.description ?? "none")")
        print("[CreationService] Contact: \(result.contactName ?? "none")")
    }
    
    func save() {
        guard let result = currentResult else { return }
        
        // For now, just print the final result
        print("[CreationService] Saving:")
        print("  Intent: \(result.intent.rawValue)")
        print("  Title: \(editedTitle)")
        print("  DateTime: \(editedDateTime)")
        print("  Contact: \(editedContactName)")
        
        // TODO: Actually create the item based on intent type
        // This will integrate with your existing TaskItem, ReminderItem, etc.
        
        // Reset and close
        showingConfirmation = false
        currentResult = nil
        editedTitle = ""
        editedDateTime = Date()
        editedContactName = ""
    }
    
    func cancel() {
        showingConfirmation = false
        currentResult = nil
        editedTitle = ""
        editedDateTime = Date()
        editedContactName = ""
    }
}
