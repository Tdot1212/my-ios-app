import Foundation

struct ParsedCommand {
    let title: String
    let person: String?
    let dueDate: Date?
}

class CommandInterpreter {
    static let shared = CommandInterpreter()
    
    private init() {}
    
    func parseCommand(_ text: String) -> ParsedCommand {
        // TODO: Implement parsing logic using NSDataDetector and regex
        print("[CommandInterpreter] Parsing command: \(text)")
        
        // Placeholder implementation
        return ParsedCommand(
            title: text,
            person: nil,
            dueDate: nil
        )
    }
    
    private func extractPerson(from text: String) -> String? {
        // TODO: Extract person name if command starts with "remind <Name>"
        return nil
    }
    
    private func extractDateTime(from text: String) -> Date? {
        // TODO: Use NSDataDetector(.date) to extract date/time
        return nil
    }
    
    private func extractTitle(from text: String, person: String?, dateTime: Date?) -> String {
        // TODO: Extract title by removing person and date/time parts
        return text
    }
}
