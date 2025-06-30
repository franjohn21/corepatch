import SwiftUI

struct HistoryRow: View {
    let entry: CorePatchEntry
    let count: Int

    private var dateString: String {
        entry.createdAt.formatted(date: .long, time: .omitted)
    }

    var body: some View {
        Text("\(dateString) \(entry.oppositeBelief) - \(count)/7")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
