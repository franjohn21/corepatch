import Foundation
import SwiftData

/// Represents one complete day of journaling across all categories.
@Model
final class CorePatchEntry: Identifiable {
    // Persistent fields -----------------------------------------------------
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    
    /// The raw string value of the wound ID, which is what's persisted.
    /// This is what we will use in #Predicate.
    @Attribute(originalName: "woundID") var woundIDRaw: String?
    
    // Category texts - one property per category
    var careerText: String = ""
    var spiritualText: String = ""
    var mentalText: String = ""
    var emotionText: String = ""
    var physicalText: String = ""
    var socialText: String = ""
    var financesText: String = ""
    
    // Feedback stored directly on the entry
    var feedback: String?
    var feedbackGeneratedAt: Date?

    // MARK: – Convenience (not persisted) -----------------------------------
    
    /// Midnight-normalised date for quick “entries today” queries.
    var dayKey: Date {
        createdAt.stripTimeToMidnight()
    }

    var oppositeBelief: String {
        WoundCatalog.shared.byID[woundID]?.counterBelief ?? "—"
    }
    
    /// Entry is locked once feedback has been generated
    var isLocked: Bool {
        feedback != nil
    }

    /// Computed property for easy access to the enum type throughout the app.
    /// The getter provides a safe fallback.
    var woundID: CoreWoundID {
        get {
            if let raw = woundIDRaw,
               let enumValue = CoreWoundID(rawValue: raw) {
                return enumValue
            }
            return .SOMETHING_IS_WRONG_WITH_ME        // safe fallback
        }
        set { woundIDRaw = newValue.rawValue }
    }

    init(woundID: CoreWoundID, createdAt: Date = .now) {
        self.id = UUID()
        self.createdAt = createdAt
        self.woundIDRaw = woundID.rawValue
        
        // Initialize all category texts as empty
        self.careerText = ""
        self.spiritualText = ""
        self.mentalText = ""
        self.emotionText = ""
        self.physicalText = ""
        self.socialText = ""
        self.financesText = ""
        
        // Initialize feedback as nil
        self.feedback = nil
        self.feedbackGeneratedAt = nil
    }
    
    // SwiftData requires a public no-arg initializer if other initializers are present.
    public init() {
        self.id = UUID()
        self.createdAt = .now
        self.woundIDRaw = CoreWoundID.SOMETHING_IS_WRONG_WITH_ME.rawValue
        
        // Initialize all category texts as empty
        self.careerText = ""
        self.spiritualText = ""
        self.mentalText = ""
        self.emotionText = ""
        self.physicalText = ""
        self.socialText = ""
        self.financesText = ""
        
        // Initialize feedback as nil
        self.feedback = nil
        self.feedbackGeneratedAt = nil
    }
    
    // MARK: - Category Text Helpers
    
    /// Get text for a specific category
    func getText(for category: Category) -> String {
        switch category {
        case .career: return careerText
        case .spiritual: return spiritualText
        case .mental: return mentalText
        case .emotion: return emotionText
        case .physical: return physicalText
        case .social: return socialText
        case .finances: return financesText
        }
    }
    
    /// Set text for a specific category
    func setText(_ text: String, for category: Category) {
        switch category {
        case .career: careerText = text
        case .spiritual: spiritualText = text
        case .mental: mentalText = text
        case .emotion: emotionText = text
        case .physical: physicalText = text
        case .social: socialText = text
        case .finances: financesText = text
        }
    }
    
    /// Check if a category has non-empty text
    func hasText(for category: Category) -> Bool {
        !getText(for: category).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Get all categories that have text
    var completedCategories: [Category] {
        Category.allCases.filter { hasText(for: $0) }
    }
    
    /// Get all category texts as a dictionary
    var categoryTexts: [String: String] {
        var texts: [String: String] = [:]
        for category in Category.allCases {
            let text = getText(for: category)
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                texts[String(describing: category)] = text
            }
        }
        return texts
    }
}

// MARK: - Debug helpers
extension CorePatchEntry {

    /// Dump every CorePatchEntry row currently in the persistent store.
    @MainActor
    static func debugDump(in context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<CorePatchEntry>(
                sortBy: [.init(\.createdAt, order: .forward)]
            )
            let rows = try context.fetch(descriptor)

            if rows.isEmpty {
                print("DEBUG DUMP: CorePatchEntry store is EMPTY.")
                return
            }

            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .medium

            print("DEBUG DUMP: \(rows.count) CorePatchEntry rows ------------------------------")
            for e in rows {
                let completedCount = e.completedCategories.count
                print(" • id: \(e.id) | woundID: \(e.woundID) | created: \(df.string(from: e.createdAt)) | completed: \(completedCount)/7 categories | feedback: \(e.feedback != nil ? "✓" : "✗")")
                for category in Category.allCases {
                    let text = e.getText(for: category)
                    if !text.isEmpty {
                        print("   - \(category): '\(text.prefix(50))\(text.count > 50 ? "..." : "")'")
                    }
                }
            }
            print("-------------------------------------------------------------------------------")
        } catch {
            print("DEBUG DUMP: FAILED – \(error.localizedDescription)")
        }
    }
}
