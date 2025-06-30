import SwiftUI

struct YesterdayRecapCard: View {
    let count: Int          // 0…7 completed categories yesterday

    private var headline: String {
        switch count {
        case 0:
            return "No patches logged"
        case 1...3:
            return "\(count) patches logged"
        case 4...6:
            return "Great job: \(count) patches logged"
        default:
            return "Perfect: You logged 7 patches!"
        }
    }

    private var subtext: String {
        switch count {
        case 0:
            return "Today’s a fresh chance to rewire your brain."
        case 1...3:
            return "Keep the momentum going."
        case 4...6:
            return "Almost perfect, keep it up!"
        default:
            return "Amazing, do it again today!"
        }
    }

    var body: some View {
        CardContainer(iconName: "checkmark.circle", iconTint: .purple) {
            VStack(alignment: .leading, spacing: 4) {
                Text("YESTERDAY RECAP")
                    .cardSectionLabel()

                Text(headline)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtext)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
