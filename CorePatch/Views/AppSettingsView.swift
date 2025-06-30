import SwiftUI
import SwiftData

struct AppSettingsView: View {
    // Persisted name
    @AppStorage("userName") private var userName: String = ""
    
    @Environment(\.modelContext) private var context
    
    // active wound
    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    private var activeWound: UserCoreWound? { activeWounds.first }
    
    @State private var showingWoundSelector = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Profile
                Section(header: Text("Profile")) {
                    TextField("Your name", text: $userName)
                        .textInputAutocapitalization(.words)
                }
                
                // MARK: Core wound
                Section(header: Text("Current Core Wound")) {
                    HStack {
                        Text(activeWound?.title ?? "None selected")
                            .foregroundColor(activeWound == nil ? .secondary : .primary)
                        Spacer()
                        Button("Change") { showingWoundSelector = true }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingWoundSelector) {
            CoreWoundSelectionView()
        }
    }
}
