import Foundation
import SwiftData

/// One journal line the user writes during Reprogramming.
@Model
final class CorePatchEntry: Identifiable {
    // Persistent fields -----------------------------------------------------
    @Attribute(.unique) var id: UUID
    var text: String
    var category: Category // SwiftData can store rawRepresentable enums
    var createdAt: Date
    
    /// The raw string value of the wound ID, which is what's persisted.
    /// This is what we will use in #Predicate.
    @Attribute(originalName: "woundID") var woundIDRaw: String?

    // MARK: – Convenience (not persisted) -----------------------------------
    
    /// Midnight-normalised date for quick “entries today” queries.
    var dayKey: Date {
        createdAt.stripTimeToMidnight()
    }

    var oppositeBelief: String {
        WoundCatalog.shared.byID[woundID]?.counterBelief ?? "—"
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

    init(text: String,
         category: Category,
         woundID: CoreWoundID,
         createdAt: Date = .now)
    {
        self.id = UUID()
        self.text = text
        self.category = category
        self.createdAt = createdAt
        self.woundIDRaw = woundID.rawValue            // OK: optional accepts String
    }
    
    // SwiftData requires a public no-arg initializer if other initializers are present.
    public init() {
        self.id = UUID()
        self.text = ""
        self.category = .mental // Default category
        self.createdAt = .now
        self.woundIDRaw = CoreWoundID.SOMETHING_IS_WRONG_WITH_ME.rawValue // Default wound
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
                // We can still use `e.woundID` here because of our computed property.
                print(" • id: \(e.id) | woundID: \(e.woundID) | cat: \(e.category) | created: \(df.string(from: e.createdAt)) | text: '\(e.text)'")
            }
            print("-------------------------------------------------------------------------------")
        } catch {
            print("DEBUG DUMP: FAILED – \(error.localizedDescription)")
        }
    }
}
