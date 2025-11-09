import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: Snapshot DTO
struct Snapshot: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    
    // The actual data from FinanceData
    var expenses: [Expense]
    var paychecks: [Paycheck]
    var recurringExpenses: [RecurringExpense]
    
    // optional: add recurring paycheck info or other settings here
    // var recurringPaycheck: RecurringPaycheck?   // if you have one
}

// MARK: File system helper
fileprivate enum SaveFiles {
    static let savesFolderName = "saves"
    
    static var savesDirectoryURL: URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent(savesFolderName, isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    static func filename(for name: String) -> String {
        // sanitize name: remove slashes, spaces -> use safe characters
        let safe = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: "\\", with: "-")
                    .replacingOccurrences(of: " ", with: "_")
        let iso = ISO8601DateFormatter().string(from: Date())
        return "\(safe)__\(iso).json"
    }

    static func urlFor(filename: String) -> URL {
        return savesDirectoryURL.appendingPathComponent(filename)
    }
    
    static func listSaveFiles() -> [URL] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: savesDirectoryURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles]) else { return [] }
        return files.filter { $0.pathExtension.lowercased() == "json" }.sorted { (a,b) in
            (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date() >
            (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
        }
    }
}
