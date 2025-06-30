import Foundation
import SwiftData

@Model
final class UserCoreWound {
    @Attribute(.unique) var woundIDString: String
    var startedAt: Date?
    var isActive: Bool = true

    // Computed property for the actual enum
    var woundID: CoreWoundID {
        get {
            guard let id = CoreWoundID(rawValue: woundIDString) else {
                // This should ideally not happen if woundIDString is always valid.
                // You might want to log an error or handle it more gracefully.
                fatalError("Invalid woundIDString: \(woundIDString) cannot be converted to CoreWoundID.")
            }
            return id
        }
        set {
            woundIDString = newValue.rawValue
        }
    }

    // MARK: – Computed helpers
    private var definition: WoundDefinition? {
        // Use the computed woundID property here
        WoundCatalog.shared.byID[woundID]
    }
    
    var title: String { definition?.title ?? "Unknown Wound" }
    var descriptionText: String { definition?.description ?? "No description available." }
    var counterBelief: String { definition?.counterBelief ?? "No counter-belief available." }

    init(woundID: CoreWoundID) {
        self.woundIDString = woundID.rawValue
        // startedAt and isActive are initialized with default values
    }

    // It's good practice to provide a public no-argument initializer
    // if SwiftData needs to create instances (e.g., during migration or decoding)
    // and you have a custom init. However, with all properties having defaults
    // or being set in init(woundID:), it might not be strictly necessary
    // unless you encounter issues. For now, we'll keep it simple.
    // public init() { } // If needed later
}
