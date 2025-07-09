import SwiftUI
import SwiftData

struct AppSettingsView: View {
    // Persisted name
    @AppStorage("userName") private var userName: String = ""
    
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var feedbackManager: FeedbackManagerWrapper
    
    // active wound
    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    private var activeWound: UserCoreWound? { activeWounds.first }
    
    @State private var showingWoundSelector = false
    @State private var isGeneratingTestFeedback = false
    @State private var showingDayPicker = false
    @State private var selectedDay = 7
    
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
                
                // MARK: Developer Tools
                #if DEBUG
                Section(header: Text("Developer Tools")) {
                    Button(action: createAndSubmitTestEntry) {
                        HStack {
                            Image(systemName: "hammer.fill")
                            Text("Submit Test Entry")
                            Spacer()
                            if isGeneratingTestFeedback {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isGeneratingTestFeedback || activeWound == nil)
                    
                    Button(action: { showingDayPicker = true }) {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip to Day...")
                        }
                    }
                    .disabled(activeWound == nil)
                    
                    if activeWound == nil {
                        Text("Select a core wound first")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingWoundSelector) {
            CoreWoundSelectionView()
        }
        .sheet(isPresented: $showingDayPicker) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Skip to Day")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This will create entries for previous days to simulate being on the selected day.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Picker("Day", selection: $selectedDay) {
                        ForEach(1...21, id: \.self) { day in
                            Text("Day \(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    
                    Button("Skip to Day \(selectedDay)") {
                        skipToDay(selectedDay)
                        showingDayPicker = false
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Skip to Day")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Cancel") {
                        showingDayPicker = false
                    }
                )
            }
        }
    }
    
    private func createAndSubmitTestEntry() {
        guard let activeWound = activeWound else { return }
        
        isGeneratingTestFeedback = true
        
        // Create a test entry with pre-filled data
        let testEntry = CorePatchEntry(woundID: activeWound.woundID, createdAt: Date())
        
        // Set test data for each category
        testEntry.careerText = "Had a productive day at work. Finished the big presentation I've been working on and received positive feedback from my manager. Feeling confident about my professional growth."
        
        testEntry.spiritualText = "Took 10 minutes this morning to meditate and reflect. Felt more centered and connected to my purpose. Grateful for the quiet moments of peace."
        
        testEntry.mentalText = "Noticed I handled stress better today. When things got hectic, I remembered to take deep breaths and stay focused on one task at a time."
        
        testEntry.emotionText = "Felt genuinely happy when a colleague complimented my work. Allowed myself to fully experience the joy without downplaying it. Progress!"
        
        testEntry.physicalText = "Went for a 30-minute walk during lunch break. My body felt energized afterward. Also remembered to drink plenty of water throughout the day."
        
        testEntry.socialText = "Had a great conversation with my friend Sarah. We laughed about old memories and I felt truly connected. Building stronger relationships feels good."
        
        testEntry.financesText = "Reviewed my budget and I'm on track for the month. Put an extra $50 into savings. Small steps but feeling more in control of my financial future."
        
        // Insert into context
        context.insert(testEntry)
        
        // Save
        do {
            try context.save()
            print("DEBUG: Test entry created and saved")
            
            // Generate feedback
            Task {
                await feedbackManager.generateFeedback(for: testEntry)
                await MainActor.run {
                    isGeneratingTestFeedback = false
                }
            }
        } catch {
            print("DEBUG: Error saving test entry: \(error)")
            isGeneratingTestFeedback = false
        }
    }
    
    private func skipToDay(_ targetDay: Int) {
        guard let activeWound = activeWound else { return }
        
        print("DEBUG: Skipping to day \(targetDay)")
        
        // Calculate the start date (today minus the target day number)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get existing entries for this wound to check for duplicates
        let woundIDRaw = activeWound.woundID.rawValue
        let existingPredicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw
        }
        let existingDescriptor = FetchDescriptor<CorePatchEntry>(predicate: existingPredicate)
        let existingEntries = (try? context.fetch(existingDescriptor)) ?? []
        
        // Create entries for each day leading up to the target day
        for dayOffset in 0..<(targetDay - 1) {
            guard let entryDate = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let dayStart = calendar.startOfDay(for: entryDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Check if entry already exists for this date
            let hasExistingEntry = existingEntries.contains { entry in
                entry.createdAt >= dayStart && entry.createdAt < dayEnd
            }
            
            if hasExistingEntry {
                let dayNumber = targetDay - dayOffset - 1
                print("DEBUG: Entry already exists for day \(dayNumber + 1), skipping")
                continue
            }
            
            // Create new empty entry for this day
            let dayEntry = CorePatchEntry(woundID: activeWound.woundID)
            dayEntry.createdAt = entryDate
            
            // Leave all category texts empty (they default to empty strings)
            // No need to set any text fields - they'll remain empty
            
            context.insert(dayEntry)
            let dayNumber = targetDay - dayOffset - 1
            print("DEBUG: Created empty entry for day \(dayNumber + 1) on date \(entryDate)")
        }
        
        // Save all entries
        do {
            try context.save()
            print("DEBUG: Successfully skipped to day \(targetDay)")
        } catch {
            print("DEBUG: Error saving skip entries: \(error)")
        }
    }
}
