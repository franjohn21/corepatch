import Foundation

struct WoundDefinition: Codable, Identifiable {
    var id: CoreWoundID // Matches the "id" in JSON, decoded as CoreWoundID
    var title: String
    var description: String
    var counterBelief: String
}