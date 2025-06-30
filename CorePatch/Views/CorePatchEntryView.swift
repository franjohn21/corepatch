import SwiftUI
import SwiftData
import RichTextKit

struct CorePatchEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Fetch the active wound once
    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    @State private var cachedActiveWound: UserCoreWound? = nil

    let targetDate: Date

    // UI state --------------------------------------------------------------
    @State private var selectedIndex: Int = 0
    @State private var currentCategory: Category = Category.allCases[0]
    @State private var currentText: String = ""
    @State private var attributedText = NSAttributedString(string: "")
    @FocusState private var isTextEditorFocused: Bool
    private let textState = TextState.shared
    @State private var navigationTrigger = 0
    @StateObject private var richTextContext = RichTextContext()
    @State private var currentSessionTexts: [Category: String] = [:]
    @State private var targetDatePersistedEntries: [Category: CorePatchEntry] = [:]
    @State private var autosaveTask: Task<Void, Never>? = nil
    private let autosaveDelay: Duration = .seconds(0.6)

    private var categories: [Category] { Category.allCases }
    
    // Simple computed property that mirrors React's derived state
    private var isCurrentCategoryCompleted: Bool {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let persistedText = targetDatePersistedEntries[currentCategory]?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !text.isEmpty || !persistedText.isEmpty
    }

    // MARK: – Derived completion status ------------------------------------
    @State private var completionCache: [Category: Bool] = [:]
    
    private func updateCompletionCache() {
        print("DEBUG updateCompletionCache called")
        var cache: [Category: Bool] = [:]
        for category in categories {
            let text = textState.getText(for: category).trimmingCharacters(in: .whitespacesAndNewlines)
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
            VStack(spacing: 24) {
                categoryGrid
                categoryPrompt
                textEditor
                Spacer()
                nextButton
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { 
                        // Save current attributed text before leaving
                        textState.setText(attributedText.string, for: currentCategory)
                        textState.saveToStorage(for: currentCategory)
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
                if let wound = cachedActiveWound {
                    textState.setup(context: context, woundID: wound.woundID, date: targetDate)
                }
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
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories.indices, id: \.self) { idx in
                categoryButton(for: idx)
            }
        }
    }
    
    private func categoryButton(for idx: Int) -> some View {
        let cat = categories[idx]
        let isCompleted = isCategoryCompleted(cat)
        
        return Button {
            // Save current attributed text before switching
            textState.setText(attributedText.string, for: currentCategory)
            
            selectedIndex = idx
            currentCategory = cat
            let plainText = textState.getText(for: cat)
            currentText = plainText
            attributedText = NSAttributedString(string: plainText)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : cat.iconName)
                    .font(.title2)
                    .foregroundStyle(isCompleted ? Color.green : (selectedIndex == idx ? Color.white : Color.primary))

                Text(cat.displayName)
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(selectedIndex == idx ? Color.accentColor : Color(.systemBackground))
            .foregroundStyle(selectedIndex == idx ? Color.white : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
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
        VStack(spacing: 8) {
            // Rich text formatting toolbar
            HStack(spacing: 16) {
                Button("B") {
                    richTextContext.toggleStyle(.bold)
                }
                .fontWeight(.bold)
                
                Button("I") {
                    richTextContext.toggleStyle(.italic)
                }
                .italic()
                
                Button("•") {
                    // Add bullet point at new line
                    let bullet = attributedText.string.isEmpty ? "• " : "\n• "
                    let newText = NSMutableAttributedString(attributedString: attributedText)
                    newText.append(NSAttributedString(string: bullet))
                    attributedText = newText
                }
                .font(.title2)
                
                Button("\"") {
                    // Insert quote prefix
                    let quote = "> "
                    let newText = NSMutableAttributedString(attributedString: attributedText)
                    newText.append(NSAttributedString(string: quote))
                    attributedText = newText
                }
                .font(.title3)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Rich text editor
            RichTextEditor(text: $attributedText, context: richTextContext)
                .focused($isTextEditorFocused)
                .id(currentCategory) // Force complete re-render on category change (like React key)
                .frame(minHeight: 120, maxHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3))
                )
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

        var fetchedEntriesMap: [Category: CorePatchEntry] = [:]
        var sessionTextsMap: [Category: String] = [:]

        if let fetched = try? context.fetch(descriptor) {
            for entry in fetched {
                fetchedEntriesMap[entry.category] = entry
                sessionTextsMap[entry.category] = entry.text
            }
        }
        
        if fetchedEntriesMap.isEmpty {
            print("loadEntriesForTargetDate: No entries fetched from SwiftData for wound \(unwrappedActiveWound.woundID) on \(targetDate.formatted(date: .numeric, time: .omitted)).")
        } else {
            print("loadEntriesForTargetDate: Fetched \(fetchedEntriesMap.count) entries.")
        }
        
        await MainActor.run {
            self.targetDatePersistedEntries = fetchedEntriesMap
            self.currentSessionTexts = sessionTextsMap
            self.currentCategory = categories[selectedIndex]
            let plainText = sessionTextsMap[self.currentCategory] ?? ""
            self.currentText = plainText
            self.attributedText = NSAttributedString(string: plainText)
            self.updateCompletionCache()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isTextEditorFocused = true
            }
        }
    }

    // MARK: – Navigation ---------------------------------------------------------
    private func advanceToNext() {
        // Save current attributed text before advancing
        textState.setText(attributedText.string, for: currentCategory)
        
        if selectedIndex < categories.count - 1 {
            selectedIndex += 1
            currentCategory = categories[selectedIndex]
            let plainText = textState.getText(for: currentCategory)
            currentText = plainText
            attributedText = NSAttributedString(string: plainText)
        } else {
            dismiss()
        }
    }
    
    private func saveCurrentCategoryText() {
        // Simple - just save to storage like localStorage.setItem()
        textState.saveToStorage(for: currentCategory)
        updateCompletionCache()
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
        guard let wound = cachedActiveWound else { return }

        let trimmed = (currentSessionTexts[currentCategory] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = targetDatePersistedEntries[currentCategory] {
            if trimmed.isEmpty {
                context.delete(existing)
                targetDatePersistedEntries.removeValue(forKey: currentCategory)
                currentSessionTexts.removeValue(forKey: currentCategory)
            } else if existing.text != trimmed {
                existing.text = trimmed
            } else {
                return   // no change
            }
        } else if !trimmed.isEmpty {
            let newEntry = CorePatchEntry(text: trimmed,
                                          category: currentCategory,
                                          woundID: wound.woundID,
                                          createdAt: Date())
            context.insert(newEntry)
            targetDatePersistedEntries[currentCategory] = newEntry
        } else {
            return       // nothing typed yet
        }

        do {
            try context.save()
            print("autosaveCurrentText: Saved text for \(currentCategory.displayName).")
            updateCompletionCache()
        } catch {
            print("autosaveCurrentText: ERROR – \(error.localizedDescription)")
        }
    }
}
