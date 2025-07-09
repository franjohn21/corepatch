import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    private var activeWound: UserCoreWound? { activeWounds.first }

    // MARK: – State -----------------------------------
    @State private var dayCounts: [Date: Int] = [:]  // midnight → completed(0…7)
    @State private var sheetDate: IdentifiableDate? = nil        // tapped day → editor
    @State private var timelineEntries: [CorePatchEntry] = []

    private let gridWeeks: Int = 21  // 21-week history

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // MARK: - Calendar History Section
                    ContributionGrid(
                        dayCounts: dayCounts,
                        weeks: gridWeeks,
                        onDayTapped: { date in sheetDate = IdentifiableDate(date) },
                        cellAspect: 1  // square cells
                    )
                    .aspectRatio(CGFloat(gridWeeks) / 7, contentMode: .fit)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 24) // Additional padding after contribution grid
                    
                    // Timeline entries (if you want to keep them)
                    if !timelineEntries.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(timelineEntries) { entry in // Show all entries
                                Button(action: {
                                    sheetDate = IdentifiableDate(entry.createdAt)
                                }) {
                                    TimelineEntryCard(
                                        entry: entry,
                                        completed: patchCount(for: entry)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheetDate) { identifiableDate in
            CorePatchEntryView(targetDate: identifiableDate.date)
        }
        .task(id: progressTaskID) {
            await refreshDayCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .corePatchEntryDidChange)) { _ in
            Task { await refreshDayCounts() }
        }
    }
    
    // MARK: - Helper Functions
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

    private var progressTaskID: String {
        let woundKey = activeWound?.woundID.rawValue ?? "none"
        let dayKey = Calendar.current.startOfDay(for: Date()).description
        return woundKey + dayKey
    }

    // MARK: – Fetch data ------------------------------------------------
    
    @MainActor
    private func refreshDayCounts() async {
        guard let wound = activeWound else {
            dayCounts = [:]
            timelineEntries = []
            return
        }
        let woundIDRaw = wound.woundID.rawValue

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let daysBack = (gridWeeks * 7) - 1  // inclusive

        guard
            let oldest = cal.date(byAdding: .day, value: -daysBack, to: today),
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today)
        else { return }

        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw && entry.createdAt >= oldest
                && entry.createdAt < tomorrow
        }
        let desc = FetchDescriptor<CorePatchEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let fetched = try? context.fetch(desc) else {
            dayCounts = [:]
            timelineEntries = []
            return
        }

        var counts: [Date: Int] = [:]
        for entry in fetched {
            let day = cal.startOfDay(for: entry.createdAt)
            counts[day] = entry.completedCategories.count
        }
        dayCounts = counts

        var seenDays = Set<Date>()
        var uniqueByDay: [CorePatchEntry] = []
        for entry in fetched {
            let day = cal.startOfDay(for: entry.createdAt)
            if !seenDays.contains(day) {
                uniqueByDay.append(entry)
                seenDays.insert(day)
            }
        }

        timelineEntries = uniqueByDay
    }

    private func patchCount(for entry: CorePatchEntry) -> Int {
        let day = Calendar.current.startOfDay(for: entry.createdAt)
        return dayCounts[day] ?? 0
    }
}
