import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase)   private var scenePhase

    @Query(filter: #Predicate<UserCoreWound> { $0.isActive == true })
    private var activeWounds: [UserCoreWound]
    private var activeWound: UserCoreWound? { activeWounds.first }

    @State private var completedCount: Int = 0
    private var totalCategories: Int { Category.allCases.count }
    private var remainingCount: Int { max(0, totalCategories - completedCount) }

    @State private var dayCounts: [Date: Int] = [:]   // midnight→completed(0…7)
    @State private var yesterdaysCount: Int = 0        // 0…7

    private var todayString: String {
        Date().formatted(date: .long, time: .omitted)
    }

    @State private var sheetDate: Date? = nil

    @State private var orbProgress: Double = 0.57

    private let gridWeeks: Int = 21

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Orb gauge
            OrbProgressGauge(progress: orbProgress)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

            if let wound = activeWound {
                (
                    Text("It’s time to rewrite your story around ") +
                    Text(wound.title).bold()
                )
                .font(.title2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("No active core wound selected.")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            Text(todayString)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, -16)

            // Tappable “Today’s Reprogramming” card ---------------------
            Button {
                sheetDate = Date()                     // open today
            } label: {
                ChecklistProgressCard(remaining: remainingCount,
                                      total: totalCategories)
            }
            .buttonStyle(.plain)

            // Tappable “Yesterday Recap” card ---------------------------
            Button {
                if let yesterday = Calendar.current.date(byAdding: .day,
                                                          value: -1,
                                                          to: Date()) {
                    sheetDate = yesterday               // open yesterday
                }
            } label: {
                YesterdayRecapCard(count: yesterdaysCount)
            }
            .buttonStyle(.plain)

            Button(action: {
                sheetDate = Date()         // today’s entry
                print("Complete today's entry button tapped")
            }) {
                Text("Complete today's entry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)

        }
        .padding()
            .sheet(item: $sheetDate) { date in
                CorePatchEntryView(targetDate: date)
            }
        .task(id: progressTaskID) {
            await refreshProgress()
            await refreshDayCounts()
            await refreshYesterday()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {                                             // fire-and-forget
                    await refreshProgress()
                    await refreshDayCounts()
                    await refreshYesterday()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .corePatchEntryDidChange)) { _ in
            Task {
                await refreshProgress()
                await refreshDayCounts()
                await refreshYesterday()
            }
        }
    }

    private var progressTaskID: String {
        let woundKey = activeWound?.woundID.rawValue ?? "none"
        let dayKey = Calendar.current.startOfDay(for: Date()).description
        return woundKey + dayKey
    }

    @MainActor
    private func refreshProgress() async {
        guard let wound = activeWound else {
            completedCount = 0
            return
        }
        let woundIDRaw = wound.woundID.rawValue
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: Date())
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return }

        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw &&
            entry.createdAt >= dayStart &&
            entry.createdAt < dayEnd          // ← uses captured constant
        }
        let descriptor = FetchDescriptor<CorePatchEntry>(predicate: predicate)

        if let fetched = try? context.fetch(descriptor) {
            // Filter out rows whose text is only whitespace
            let valid = fetched.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let uniqueCats = Set(valid.map(\.category))
            completedCount = uniqueCats.count
        } else {
            completedCount = 0
        }
    }

    // MARK: – 35-day activity grid
    @MainActor
    private func refreshDayCounts() async {
        guard let wound = activeWound else {
            dayCounts = [:]; return
        }
        let woundIDRaw = wound.woundID.rawValue

        let cal     = Calendar.current
        let today   = cal.startOfDay(for: Date())
        let daysBack = (gridWeeks * 7) - 1      // e.g. 8 weeks → 55 days

        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: today) else { return }
        guard let oldest = cal.date(byAdding: .day, value: -daysBack, to: today) else { return }

        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw &&
            entry.createdAt >= oldest &&
            entry.createdAt < tomorrow        // ← captured constant
        }
        let desc = FetchDescriptor<CorePatchEntry>(predicate: predicate)

        guard let fetched = try? context.fetch(desc) else {
            dayCounts = [:]; return
        }

        // count per day
        var counts: [Date: Set<Category>] = [:]
        for entry in fetched {
            let day = cal.startOfDay(for: entry.createdAt)
            if entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
            counts[day, default: []].insert(entry.category)
        }
        print("DEBUG – today has",
            counts[cal.startOfDay(for: Date())]?.count ?? 0,
            "completed categories")

        dayCounts = counts.mapValues { $0.count }
    }

    @MainActor
    private func refreshYesterday() async {
        guard let wound = activeWound else {
            yesterdaysCount = 0; return
        }
        let woundIDRaw = wound.woundID.rawValue

        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        guard
            let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart),
            let yesterdayEnd   = cal.date(byAdding: .day, value: 1,  to: yesterdayStart)
        else { return }

        let predicate = #Predicate<CorePatchEntry> { entry in
            entry.woundIDRaw == woundIDRaw &&
            entry.createdAt >= yesterdayStart &&
            entry.createdAt <  yesterdayEnd
        }
        let desc = FetchDescriptor<CorePatchEntry>(predicate: predicate)

        guard let fetched = try? context.fetch(desc) else {
            yesterdaysCount = 0; return
        }

        let valid = fetched.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let uniqueCats = Set(valid.map(\.category))
        yesterdaysCount = uniqueCats.count
    }
}
