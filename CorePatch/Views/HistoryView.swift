import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    private var activeWound: UserCoreWound? { activeWounds.first }

    // MARK: – Contribution grid state -----------------------------------
    @State private var dayCounts: [Date: Int] = [:]  // midnight → completed(0…7)
    @State private var sheetDate: Date? = nil        // tapped day → editor

    @State private var timelineEntries: [CorePatchEntry] = []

    private let gridWeeks: Int = 21  // 21-week history

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                ContributionGrid(
                    dayCounts: dayCounts,
                    weeks: gridWeeks,
                    onDayTapped: { date in sheetDate = date },
                    cellAspect: 1  // square cells
                )
                .aspectRatio(CGFloat(gridWeeks) / 7, contentMode: .fit)
                .frame(maxWidth: .infinity, alignment: .leading)

                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(timelineEntries) { entry in
                        TimelineEntryCard(
                            entry: entry,
                            completed: patchCount(for: entry)
                        )
                    }
                }
                .padding(.top, 40)
            }
            .padding()
        }
        .navigationTitle("Your Activity")
        .sheet(item: $sheetDate) { date in
            CorePatchEntryView(targetDate: date)
        }
        .task(id: progressTaskID) {
            await refreshDayCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .corePatchEntryDidChange)) { _ in
            Task { await refreshDayCounts() }
        }
    }

    private var progressTaskID: String {
        let woundKey = activeWound?.woundID.rawValue ?? "none"
        let dayKey = Calendar.current.startOfDay(for: Date()).description
        return woundKey + dayKey
    }

    // MARK: – Fetch counts ------------------------------------------------
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

        var counts: [Date: Set<Category>] = [:]
        for entry in fetched
        where
            !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            let day = cal.startOfDay(for: entry.createdAt)
            counts[day, default: []].insert(entry.category)
        }
        dayCounts = counts.mapValues { $0.count }

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
