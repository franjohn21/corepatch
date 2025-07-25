import SwiftUI
import SwiftData

// Simple global text state manager - like React localStorage
class TextState {
    static let shared = TextState()
    
    // In-memory cache like React state - NO @Published to avoid SwiftUI cycles
    var texts: [Category: String] = [:]
    
    // Reference to the SwiftData context for persistence
    private var modelContext: ModelContext?
    private var currentWoundID: CoreWoundID?
    private var currentDate: Date?
    
    func setup(context: ModelContext, woundID: CoreWoundID, date: Date) {
        self.modelContext = context
        self.currentWoundID = woundID
        self.currentDate = date
        loadFromStorage()
    }
    
    // Load existing data from SwiftData (like reading from localStorage)
    private func loadFromStorage() {
        guard let context = modelContext,
              let woundID = currentWoundID,
              let date = currentDate else { return }
        
        let dayStart = Calendar.current.startOfDay(for: date)
        guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else { return }
        
        let woundIDString = woundID.rawValue
        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDString &&
            entry.createdAt >= dayStart &&
            entry.createdAt < dayEnd
        }
        
        let descriptor = FetchDescriptor<CorePatchEntry>(predicate: predicate)
        
        if let entries = try? context.fetch(descriptor) {
            for entry in entries {
                // Load all category texts from the entry
                for category in Category.allCases {
                    let text = entry.getText(for: category)
                    if !text.isEmpty {
                        texts[category] = text
                    }
                }
            }
        }
    }
    
    // Update in-memory state (like React setState)
    func setText(_ text: String, for category: Category) {
        texts[category] = text
    }
    
    // Read from in-memory state
    func getText(for category: Category) -> String {
        return texts[category] ?? ""
    }
    
    // Save to SwiftData (like writing to localStorage)
    func saveToStorage(for category: Category) {
        guard let context = modelContext,
              let woundID = currentWoundID else { return }
        
        let text = getText(for: category)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find existing entry for this category (without date filtering for simpler predicate)
        let woundIDString = woundID.rawValue
        // Find today's entry for this wound
        let dayStart = Calendar.current.startOfDay(for: currentDate ?? Date())
        guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else { return }
        
        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDString &&
            entry.createdAt >= dayStart &&
            entry.createdAt < dayEnd
        }
        let descriptor = FetchDescriptor<CorePatchEntry>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        
        if let existingEntry = try? context.fetch(descriptor).first {
            if trimmed.isEmpty {
                context.delete(existingEntry)
                texts.removeValue(forKey: category)
            } else if existingEntry.getText(for: category) != trimmed {
                existingEntry.setText(trimmed, for: category)
            }
        } else if !trimmed.isEmpty {
            let newEntry = CorePatchEntry(woundID: woundID, createdAt: Date())
            newEntry.setText(trimmed, for: category)
            context.insert(newEntry)
        }
        
        do {
            try context.save()
            print("TextState: Saved text for \(category)")
            NotificationCenter.default.post(name: .corePatchEntryDidChange, object: nil)
        } catch {
            print("TextState: Save error - \(error)")
        }
    }
}