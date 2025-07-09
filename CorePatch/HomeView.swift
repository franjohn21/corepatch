import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    
    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    private var activeWound: UserCoreWound? { activeWounds.first }
    
    @State private var dayNumber: Int = 1
    @State private var selectedDay: Int = 1
    @State private var hasFeedback: Bool = false
    @State private var selectedTab: Int = 0
    @State private var showFeedbackModal: Bool = false
    @State private var completedCategories: [Category] = []
    @State private var allCategories: [Category] = Category.allCases
    @State private var currentEntry: CorePatchEntry? = nil
    @State private var currentCardText: String = ""
    @State private var cardOrder: [Category] = Category.allCases
    
    private var totalCategories: Int { Category.allCases.count }
    private var remainingCount: Int { max(0, totalCategories - completedCategories.count) }
    private var currentCard: Category? {
        cardOrder.first { !completedCategories.contains($0) }
    }
    private var todoCards: [Category] {
        cardOrder.filter { !completedCategories.contains($0) }
    }
    private var completedCount: Int { completedCategories.count }
    
    var body: some View {
        VStack {
            HStack {
                Text("Day \(selectedDay)/21")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { goToPreviousDay() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(selectedDay > 1 ? .primary : .gray)
                    }
                    .disabled(selectedDay <= 1)
                    
                    Button(action: { goToNextDay() }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(selectedDay < dayNumber ? .primary : .gray)
                    }
                    .disabled(selectedDay >= dayNumber)
                }
            }
            .padding()
            
            // Counter belief text
            if let wound = activeWound {
                Text(convertToSecondPerson(wound.counterBelief))
                    .font(.title2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            } else {
                Text("No active core wound selected.")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            
            // Tab system
            HStack(spacing: 0) {
                Button(action: { selectedTab = 0 }) {
                    VStack(spacing: 4) {
                        Text("Todo (\(remainingCount))")
                            .font(.system(size: 16, weight: .medium))
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == 0 ? .accentColor : .clear)
                    }
                }
                .foregroundColor(selectedTab == 0 ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                
                Button(action: { selectedTab = 1 }) {
                    VStack(spacing: 4) {
                        Text("Done (\(completedCount))")
                            .font(.system(size: 16, weight: .medium))
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == 1 ? .accentColor : .clear)
                    }
                }
                .foregroundColor(selectedTab == 1 ? .primary : .secondary)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Tab content
            if selectedTab == 0 {
                // Todo tab - List interface
                if remainingCount == 0 {
                    // Completion state
                    CompletionView(hasFeedback: hasFeedback)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(todoCards, id: \.self) { category in
                                TodoListCard(
                                    category: category,
                                    text: Binding(
                                        get: { 
                                            if category == currentCard {
                                                return currentCardText
                                            }
                                            return currentEntry?.getText(for: category) ?? ""
                                        },
                                        set: { newValue in
                                            if category == currentCard {
                                                currentCardText = newValue
                                            }
                                            currentEntry?.setText(newValue, for: category)
                                        }
                                    ),
                                    onComplete: { completeCard(category) }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.horizontal)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: todoCards.count)
                    }
                }
            } else {
                // Done tab - Scrollable list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(completedCategories, id: \.self) { category in
                            DoneCard(category: category, content: currentEntry?.getText(for: category) ?? "")
                        }
                        
                        if completedCategories.isEmpty {
                            VStack(spacing: 8) {
                                Text("No completed cards yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Complete cards in the Todo tab to see them here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await calculateDayNumber()
        }
        .onChange(of: selectedDay) {
            Task {
                await updateDataForSelectedDay()
            }
        }
        .sheet(isPresented: $showFeedbackModal) {
            FeedbackModalView(feedback: currentEntry?.feedback ?? "")
        }
    }
    
    private func goToPreviousDay() {
        if selectedDay > 1 {
            selectedDay -= 1
        }
    }
    
    private func goToNextDay() {
        if selectedDay < dayNumber {
            selectedDay += 1
        }
    }
    
    private func completeCard(_ category: Category) {
        print("DEBUG: completeCard called for \(category.displayName)")
        print("DEBUG: currentEntry exists: \(currentEntry != nil)")
        print("DEBUG: selectedDay: \(selectedDay), dayNumber: \(dayNumber)")
        
        guard let entry = currentEntry else {
            print("DEBUG: No current entry to save to - creating one now")
            // Try to create entry if we don't have one
            Task {
                await ensureCurrentEntry()
                // Retry completion after creating entry
                if let newEntry = currentEntry {
                    completeCardWithEntry(category, entry: newEntry)
                }
            }
            return
        }
        
        completeCardWithEntry(category, entry: entry)
    }
    
    private func completeCardWithEntry(_ category: Category, entry: CorePatchEntry) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Save the text to the entry
            if category == currentCard {
                entry.setText(currentCardText, for: category)
                currentCardText = ""
                print("DEBUG: Saved text for \(category.displayName): \(entry.getText(for: category).prefix(50))...")
            }
            
            // Save to context
            do {
                try context.save()
                print("DEBUG: Saved context after completing \(category.displayName)")
            } catch {
                print("DEBUG: Error saving context: \(error)")
            }
            
            // Update completed categories from the entry
            completedCategories = entry.completedCategories
            print("DEBUG: Completed categories: \(completedCategories.map { $0.displayName })")
        }
        
        // Check if all categories are completed and submit for feedback
        if completedCategories.count == totalCategories {
            print("DEBUG: All categories completed, submitting for feedback")
            Task {
                await submitForFeedback()
            }
        }
    }
    
    @MainActor
    private func ensureCurrentEntry() async {
        guard let wound = activeWound else { return }
        
        // Create entry for current day
        let newEntry = CorePatchEntry(woundID: wound.woundID)
        newEntry.createdAt = Date()
        context.insert(newEntry)
        
        do {
            try context.save()
            currentEntry = newEntry
            print("DEBUG: Created emergency entry for current day")
        } catch {
            print("DEBUG: Error creating emergency entry: \(error)")
        }
    }
    
    @MainActor
    private func submitForFeedback() async {
        guard let entry = currentEntry,
              let wound = activeWound else { return }
        
        // Create feedback manager if needed
        let feedbackManager = FeedbackManager(modelContext: context)
        
        // Submit for feedback (this will save feedback to the entry)
        await feedbackManager.generateFeedback(for: entry)
        
        // Refresh to show feedback
        await updateDataForSelectedDay()
    }
    
    private func feedbackPreview(_ feedback: String) -> String {
        let words = feedback.split(separator: " ")
        let maxWords = 15 // Approximately 2-3 lines
        if words.count <= maxWords {
            return feedback
        } else {
            return words.prefix(maxWords).joined(separator: " ") + "..."
        }
    }
    
    private func convertToSecondPerson(_ text: String) -> String {
        return text
            .replacingOccurrences(of: " I ", with: " you ")
            .replacingOccurrences(of: " I'm ", with: " you're ")
            .replacingOccurrences(of: " I've ", with: " you've ")
            .replacingOccurrences(of: " my ", with: " your ")
            .replacingOccurrences(of: " me", with: " you")
            .replacingOccurrences(of: " myself", with: " yourself")
            // Handle sentence beginnings
            .replacingOccurrences(of: "I ", with: "You ")
            .replacingOccurrences(of: "I'm ", with: "You're ")
            .replacingOccurrences(of: "I've ", with: "You've ")
            .replacingOccurrences(of: "My ", with: "Your ")
    }
    
    @MainActor
    private func calculateDayNumber() async {
        guard let wound = activeWound else {
            dayNumber = 1
            return
        }
        
        let woundIDRaw = wound.woundID.rawValue
        
        // Find the first entry for this core wound
        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw
        }
        let descriptor = FetchDescriptor<CorePatchEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        guard let entries = try? context.fetch(descriptor),
              let firstEntry = entries.first else {
            dayNumber = 1
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: firstEntry.createdAt)
        let today = calendar.startOfDay(for: Date())
        
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        dayNumber = daysSinceStart + 1 // +1 because day 1 is the first day, not day 0
        selectedDay = dayNumber // Start viewing the current day
        
        await updateDataForSelectedDay()
    }
    
    @MainActor
    private func updateDataForSelectedDay() async {
        guard let wound = activeWound else {
            completedCategories = []
            hasFeedback = false
            currentEntry = nil
            currentCardText = ""
            return
        }
        
        let woundIDRaw = wound.woundID.rawValue
        
        // Calculate the date for the selected day
        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw
        }
        let descriptor = FetchDescriptor<CorePatchEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        
        guard let entries = try? context.fetch(descriptor),
              let firstEntry = entries.first else {
            completedCategories = []
            hasFeedback = false
            currentEntry = nil
            currentCardText = ""
            return
        }
        
        let startDate = Calendar.current.startOfDay(for: firstEntry.createdAt)
        guard let targetDate = Calendar.current.date(byAdding: .day, value: selectedDay - 1, to: startDate) else {
            completedCategories = []
            hasFeedback = false
            currentEntry = nil
            currentCardText = ""
            return
        }
        
        let dayStart = Calendar.current.startOfDay(for: targetDate)
        guard let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) else {
            completedCategories = []
            hasFeedback = false
            currentEntry = nil
            currentCardText = ""
            return
        }
        
        // Find entry for this specific day
        let dayPredicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw &&
            entry.createdAt >= dayStart &&
            entry.createdAt < dayEnd
        }
        let dayDescriptor = FetchDescriptor<CorePatchEntry>(predicate: dayPredicate)
        
        if let dayEntries = try? context.fetch(dayDescriptor),
           let dayEntry = dayEntries.first {
            completedCategories = dayEntry.completedCategories
            hasFeedback = !(dayEntry.feedback?.isEmpty ?? true)
            currentEntry = dayEntry
            
            // Set current card text
            if let current = currentCard {
                currentCardText = dayEntry.getText(for: current)
            }
        } else {
            // Create new entry for this day if viewing current day (selectedDay == dayNumber)
            if selectedDay == dayNumber {
                let newEntry = CorePatchEntry(woundID: wound.woundID)
                newEntry.createdAt = targetDate
                context.insert(newEntry)
                
                do {
                    try context.save()
                    currentEntry = newEntry
                    print("DEBUG: Created new entry for selected day \(selectedDay)")
                } catch {
                    print("DEBUG: Error creating new entry: \(error)")
                    currentEntry = nil
                }
            } else {
                currentEntry = nil
                print("DEBUG: No entry exists for day \(selectedDay), and it's not the current day")
            }
            
            completedCategories = []
            hasFeedback = false
            currentCardText = ""
        }
    }
}

struct TodoListCard: View {
    let category: Category
    @Binding var text: String
    let onComplete: () -> Void
    @State private var dragOffset: CGSize = .zero
    @State private var isBeingDragged: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(category.emoji)
                    .font(.title2)
            }
            
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .scrollContentBackground(.hidden)
            
            HStack {
                Text("Swipe right to complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Complete") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            // Swipe indicator
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    dragOffset.width > 50 ? Color.green : Color.clear,
                    lineWidth: 2
                )
        )
        .offset(dragOffset)
        .scaleEffect(isBeingDragged ? 1.02 : 1.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isBeingDragged = true
                    if value.translation.width > 0 { // Only allow right swipe
                        dragOffset = CGSize(width: value.translation.width, height: 0)
                    }
                }
                .onEnded { value in
                    isBeingDragged = false
                    if value.translation.width > 100 && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Complete with slide-out animation
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = CGSize(width: 400, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onComplete()
                            dragOffset = .zero
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .animation(.spring(response: 0.3), value: isBeingDragged)
    }
}

struct DoneCard: View {
    let category: Category
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            
            if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No content written")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.1), Color.green.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(16)
        .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct CompletionView: View {
    let hasFeedback: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Done!")
                .font(.title)
                .fontWeight(.bold)
            
            if hasFeedback {
                Text("You've completed all 7 categories and received AI feedback!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("You've completed all 7 categories for today")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Generating AI feedback...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .frame(height: 200)
    }
}

struct FeedbackModalView: View {
    @Environment(\.dismiss) private var dismiss
    let feedback: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Feedback")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(feedback)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}