import SwiftUI

struct ChecklistProgressCard: View {
    let remaining: Int     // how many categories still empty
    let total: Int         // total categories (7)

    private var completed: Int { total - remaining }
    private var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }

    var body: some View {
        CardContainer(
            // need extra bottom space for the bar, ADD: a little more bottom padding to give breathing-room under the bar
            insets: EdgeInsets(top: 16, leading: 16, bottom: 32, trailing: 16),
            iconName: remaining == 0 ? "checkmark.circle.fill" : "checklist",
            iconTint: .accentColor
        ) {
             VStack(alignment: .leading, spacing: 8) {
                 Text("Today's Reprogramming")
                     .cardSectionLabel()

                 Text(remaining == 0 ? "All Done!" :
                               "\(remaining) Remaining")
                     .font(.title3.bold())
             }
        }
         .overlay(
             ProgressBar(fraction: fraction)
                 .frame(height: 6)
                 .padding(.horizontal)
                 .padding(.bottom, 16),
             alignment: .bottom
         )
    }
    private struct ProgressBar: View {
        let fraction: Double
        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: geo.size.width)

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * fraction)
                }
            }
        }
    }
}
