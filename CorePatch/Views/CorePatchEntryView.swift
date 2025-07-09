import SwiftUI
import SwiftData

struct CorePatchEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var feedbackManager: FeedbackManagerWrapper

    // Fetch the active wound once
    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    @State private var cachedActiveWound: UserCoreWound? = nil

    let targetDate: Date

    // UI state --------------------------------------------------------------
    @State private var selectedIndex: Int = 0
    @State private var currentCategory: Category = Category.allCases[0]
    @State private var currentText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    @State private var navigationTrigger = 0
    @State private var currentEntry: CorePatchEntry? = nil
    @State private var autosaveTask: Task<Void, Never>? = nil
    private let autosaveDelay: Duration = .seconds(0.6)

    private var categories: [Category] { Category.allCases }
    
    // Simple computed property that mirrors React's derived state
    private var isCurrentCategoryCompleted: Bool {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let persistedText = currentEntry?.getText(for: currentCategory).trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !text.isEmpty || !persistedText.isEmpty
    }

    // MARK: – Derived completion status ------------------------------------
    @State private var completionCache: [Category: Bool] = [:]
    
    private func updateCompletionCache() {
        print("DEBUG updateCompletionCache called")
        var cache: [Category: Bool] = [:]
        for category in categories {
            // Check current editing text if this is the current category
            let text = if category == currentCategory {
                currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                currentEntry?.getText(for: category).trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            cache[category] = !text.isEmpty
        }
        print("DEBUG: Setting completionCache = \(cache)")
        completionCache = cache
        print("DEBUG: completionCache updated successfully")
    }

    // MARK: – Convenience ---------------------------------------------------
    /// “June 26 2025”
    private var displayDate: String {
        targetDate.formatted(date: .long, time: .omitted)
    }
    
    /// Already stored on the active wound (falls back to empty string).
    private var positiveBelief: String {
        cachedActiveWound?.counterBelief ?? ""
    }
    
    /// Helper to check if a category is completed
    private func isCategoryCompleted(_ category: Category) -> Bool {
        if category == currentCategory {
            return isCurrentCategoryCompleted
        } else {
            return completionCache[category] ?? false
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if currentEntry?.isLocked == true {
                    // Locked view with feedback
                    ScrollView {
                        VStack(spacing: 20) {
                            // Lock indicator
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                Text("This entry has been completed")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top)
                            
                            categoryGrid
                            
                            // Show feedback
                            if let feedback = currentEntry?.feedback {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("AI Feedback", systemImage: "sparkles")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(feedback)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    
                                    if let generatedAt = currentEntry?.feedbackGeneratedAt {
                                        Text("Generated \(generatedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top)
                            }
                            
                            // Show all category texts in read-only mode
                            ForEach(categories, id: \.self) { category in
                                if let text = currentEntry?.getText(for: category),
                                   !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(category.emoji)
                                            Text(category.displayName)
                                                .font(.headline)
                                        }
                                        
                                        Text(text)
                                            .font(.body)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                } else {
                    // Editable view
                    VStack(spacing: 20) {
                        categoryGrid
                        categoryPrompt
                        textEditor
                        Spacer()
                        nextButton
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {  
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { 
                        // Save current text before leaving
                        if currentEntry?.isLocked != true {
                            saveCurrentCategoryText()
                            queueFeedbackIfNeeded()
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(displayDate).font(.headline)
                }
            }
            .task(id: TaskID(woundID: cachedActiveWound?.woundID, date: targetDate)) {
                await loadEntriesForTargetDate()
            }
            .onAppear {
                cachedActiveWound = activeWounds.first
                // TextState setup no longer needed with new model
            }
            .onChange(of: activeWounds) { _, newWounds in
                cachedActiveWound = newWounds.first
            }
            .onDisappear {
                autosaveTask?.cancel()
            }
            .onChange(of: navigationTrigger) { _, _ in
                advanceToNext()
            }
        }
    }
    
    private var categoryGrid: some View {
        HStack(spacing: 8) {
            ForEach(categories.indices, id: \.self) { idx in
                categoryButton(for: idx)
            }
        }
        .frame(height: 44)
    }
    
    private func categoryButton(for idx: Int) -> some View {
        let cat = categories[idx]
        let isCompleted = isCategoryCompleted(cat)
        
        return Button {
            guard currentEntry?.isLocked != true else { return }
            
            print("categoryButton: Switching from \(currentCategory) to \(cat)")
            
            // Save current text before switching
            saveCurrentCategoryText()
            
            selectedIndex = idx
            currentCategory = cat
            let loadedText = currentEntry?.getText(for: cat) ?? ""
            currentText = loadedText
            print("categoryButton: Loaded text for \(cat): '\(loadedText)'")
        } label: {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : cat.iconName)
                .font(.title3)
                .foregroundStyle(isCompleted ? Color.green : (selectedIndex == idx ? Color.white : Color.primary))
                .frame(width: 44, height: 44)
                .background(selectedIndex == idx ? Color.accentColor : Color(.systemGray6))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: selectedIndex == idx ? 0 : 1)
                )
                .opacity(currentEntry?.isLocked == true ? 0.6 : 1.0)
        }
    }
    
    private var categoryPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(currentCategory.emoji)
                Text(currentCategory.displayName)
                    .font(.title3.bold())
            }

            Text("How was something right with you in the \(currentCategory.displayName.lowercased()) area of life recently?")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var textEditor: some View {
        TextEditor(text: $currentText)
            .focused($isTextEditorFocused)
            .id(currentCategory) // Force complete re-render on category change (like React key)
            .frame(minHeight: 120, maxHeight: 200)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3))
            )
            .onChange(of: currentText) { _, newValue in
                updateCompletionCache()
                scheduleAutosave()
            }
    }
    
    private var nextButton: some View {
        Button("Next") {
            navigationTrigger += 1
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }

    private struct TaskID: Equatable {
        let woundID: CoreWoundID?
        let date: Date
    }

    private func loadEntriesForTargetDate() async {
        print("loadEntriesForTargetDate: Called. targetDate raw: \(targetDate) (\(targetDate.timeIntervalSince1970))")
        guard let unwrappedActiveWound = cachedActiveWound else {
            print("loadEntriesForTargetDate: Guard failed because activeWound is nil.")
            return
        }

        let capturedWoundIDRaw = unwrappedActiveWound.woundID.rawValue
        let capturedDayStart = Calendar.current.startOfDay(for: targetDate)
        guard let capturedDayEnd = Calendar.current.date(byAdding: .day, value: 1, to: capturedDayStart) else { return }

        print("loadEntriesForTargetDate: Fetching entries for wound \(unwrappedActiveWound.woundID) between \(capturedDayStart.formatted()) and \(capturedDayEnd.formatted())")

        // ❗️FIX: Predicate now compares the persisted `woundIDRaw` (String) with our captured raw value.
        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == capturedWoundIDRaw &&
            entry.createdAt >= capturedDayStart &&
            entry.createdAt < capturedDayEnd
        }
        let descriptor = FetchDescriptor<CorePatchEntry>(predicate: predicate)

        // Fetch or create single entry for the target date
        let entry: CorePatchEntry
        if let fetched = try? context.fetch(descriptor), let existingEntry = fetched.first {
            print("loadEntriesForTargetDate: Found existing entry with \(existingEntry.completedCategories.count) completed categories")
            print("loadEntriesForTargetDate: Entry contents:")
            for cat in Category.allCases {
                let text = existingEntry.getText(for: cat)
                if !text.isEmpty {
                    print("  - \(cat): '\(text)'")
                }
            }
            entry = existingEntry
        } else {
            print("loadEntriesForTargetDate: Creating new entry for \(targetDate.formatted(date: .numeric, time: .omitted))")
            let newEntry = CorePatchEntry(woundID: unwrappedActiveWound.woundID, createdAt: capturedDayStart)
            context.insert(newEntry)
            
            // Save immediately to ensure it's persisted
            do {
                try context.save()
                print("loadEntriesForTargetDate: New entry saved to database")
            } catch {
                print("loadEntriesForTargetDate: Error saving new entry - \(error)")
            }
            
            entry = newEntry
        }
        
        await MainActor.run {
            self.currentEntry = entry
            self.updateCompletionCache()
            
            // Find first uncompleted category
            if let firstIncomplete = categories.firstIndex(where: { category in
                let text = entry.getText(for: category).trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty
            }) {
                self.selectedIndex = firstIncomplete
                self.currentCategory = categories[firstIncomplete]
            } else {
                // All completed, stay on first
                self.selectedIndex = 0
                self.currentCategory = categories[0]
            }
            
            self.currentText = entry.getText(for: self.currentCategory)
            print("loadEntriesForTargetDate: Set currentText to '\(self.currentText)' for category \(self.currentCategory)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isTextEditorFocused = true
            }
        }
    }

    // MARK: – Navigation ---------------------------------------------------------
    private func advanceToNext() {
        // Save current text before advancing
        saveCurrentCategoryText()
        
        if selectedIndex < categories.count - 1 {
            selectedIndex += 1
            currentCategory = categories[selectedIndex]
            currentText = currentEntry?.getText(for: currentCategory) ?? ""
        } else {
            queueFeedbackIfNeeded()
            dismiss()
        }
    }
    
    private func saveCurrentCategoryText() {
        guard let entry = currentEntry else { 
            print("saveCurrentCategoryText: No current entry!")
            return 
        }
        
        // Don't save if entry is locked
        guard !entry.isLocked else {
            print("saveCurrentCategoryText: Entry is locked, not saving")
            return
        }
        
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("saveCurrentCategoryText: Saving '\(trimmedText)' for category \(currentCategory)")
        
        // Save current text to the entry
        entry.setText(currentText, for: currentCategory)
        
        // Verify the text was set
        let savedText = entry.getText(for: currentCategory)
        print("saveCurrentCategoryText: Verification - saved text is '\(savedText)'")
        
        do {
            try context.save()
            print("saveCurrentCategoryText: Successfully saved to SwiftData")
            updateCompletionCache()
        } catch {
            print("saveCurrentCategoryText: ERROR – \(error.localizedDescription)")
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            try? await Task.sleep(for: autosaveDelay)
            autosaveCurrentText()
        }
    }

    @MainActor
    private func autosaveCurrentText() {
        guard let entry = currentEntry else { return }
        
        // Don't autosave if entry is locked
        guard !entry.isLocked else { return }

        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingText = entry.getText(for: currentCategory).trimmingCharacters(in: .whitespacesAndNewlines)

        // Only save if text has changed
        if trimmed != existingText {
            entry.setText(trimmed, for: currentCategory)
            
            do {
                try context.save()
                print("autosaveCurrentText: Saved text for \(currentCategory).")
                updateCompletionCache()
            } catch {
                print("autosaveCurrentText: ERROR – \(error.localizedDescription)")
            }
        }
    }
    
    private func queueFeedbackIfNeeded() {
        print("DEBUG: queueFeedbackIfNeeded called")
        guard let entry = currentEntry else { 
            print("DEBUG: No current entry")
            return 
        }
        
        // Don't queue if entry already has feedback
        guard !entry.isLocked else {
            print("DEBUG: Entry already has feedback, not queueing")
            return
        }
        
        // Save current text first
        entry.setText(currentText, for: currentCategory)
        
        print("DEBUG: Found entry with \(entry.completedCategories.count) completed categories")
        
        if !entry.completedCategories.isEmpty {
            print("DEBUG: Generating feedback for entry")
            Task {
                await feedbackManager.generateFeedback(for: entry)
            }
        }
    }
}
