import Foundation

class WoundCatalog {
    static let shared = WoundCatalog()

    let byID: [CoreWoundID: WoundDefinition]

    private init() {
        guard let url = Bundle.main.url(forResource: "WoundCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let definitions = try? JSONDecoder().decode([WoundDefinition].self, from: data) else {
            fatalError("Failed to load WoundCatalog.json from bundle.")
        }
        
        var dictionary = [CoreWoundID: WoundDefinition]()
        for definition in definitions {
            dictionary[definition.id] = definition
        }
        self.byID = dictionary
    }
}