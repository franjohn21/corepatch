import SwiftUI

/// Git-Hub grid uses 0-to-7 counts → we reuse same colour levels.
private func activityColour(for count: Int) -> Color {
    switch count {
    case 0:  return Color(.systemGray5)
    case 1:  return Color.green.opacity(0.35)
    case 2,3: return Color.green.opacity(0.55)
    case 4,5: return Color.green.opacity(0.75)
    default: return Color.green.opacity(0.95)
    }
}

struct TimelineEntryCard: View {
    let entry: CorePatchEntry
    let completed: Int       // 0…7

    private var headerDate: String {
        entry.createdAt.formatted(.dateTime.month(.abbreviated).day())
    }
    private var relativePrefix: String {
        let cal = Calendar.current
        if cal.isDateInToday(entry.createdAt) { return "Today • " }
        if cal.isDateInYesterday(entry.createdAt) { return "Yesterday • " }
        return ""
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                // DATE
                Text("\(relativePrefix)\(headerDate)")
                    .cardSectionLabel()

                // COUNTER BELIEF
                Text(.init(entry.oppositeBelief))      // render Markdown (bold, italic…)
                    .font(.headline)

                // COMPLETED
                Text("\(completed)/7 categories completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Circle()
                .fill(activityColour(for: completed))
                .frame(width: 20, height: 20)
        }
        .cardStyle()
    }
}
