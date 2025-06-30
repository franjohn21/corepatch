import SwiftUI
import SwiftData

struct CoreWoundSelectionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query var storedWounds: [UserCoreWound]

    @State private var selectedID: CoreWoundID? = nil

    // All wound definitions, keep original JSON order
    private var definitions: [WoundDefinition] {
        CoreWoundID.allCases.compactMap { WoundCatalog.shared.byID[$0] }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Core Wound")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("What core wound resonates most with you?")
                        .font(.title3.bold())
                        .fixedSize(horizontal: false, vertical: true)

                    Text("This is a deep-seated belief about yourself that often stems from early experiences. It can influence your thoughts, feelings, and behaviors.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Radio-style list
                List(definitions, id: \.id) { def in
                    HStack {
                        Text(def.title)
                        Spacer()
                        Image(systemName: selectedID == def.id ? "circle.inset.filled" : "circle")
                            .foregroundColor(.primary)
                            .imageScale(.large)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selectedID = def.id }
                }
                .listStyle(.plain)

                Button("Continue") {
                    persistSelection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedID == nil)
            }
            .padding()
        }
    }
    
    private func persistSelection() {
        guard let id = selectedID else { return }
        
        // 1. Deactivate all wounds first
        for wound in storedWounds {
            wound.isActive = false
        }
        
        // 2. Activate (or create) the chosen wound
        if let existing = storedWounds.first(where: { $0.woundID == id }) {
            existing.isActive = true
            existing.startedAt = .now
        } else {
            context.insert(UserCoreWound(woundID: id))
        }
        
        try? context.save()      // Explicit save for safety
        dismiss()
    }
}
