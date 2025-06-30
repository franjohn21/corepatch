import SwiftUI

/// GitHub-style activity grid for the last *weeks*×7 days.
/// Provide a dictionary mapping "midnight Date → 0…7 completed categories".
struct ContributionGrid: View {

    struct DayColour {
        static let levels: [Color] = [
            Color(.systemGray5),          // 0 completed
            Color.green.opacity(0.35),    // 1   – darkest
            Color.green.opacity(0.55),    // 2-3
            Color.green.opacity(0.75),    // 4-5
            Color.green.opacity(0.95)     // 6-7 – brightest
        ]

        static func colour(for count: Int) -> Color {
            switch count {
            case 0:   return levels[0]
            case 1:   return levels[1]
            case 2,3: return levels[2]
            case 4,5: return levels[3]
            default:  return levels[4]
            }
        }
    }

    let dayCounts: [Date: Int]          // midnight key
    let weeks: Int                      // e.g. 5 = 35 squares

    var onDayTapped: ((Date) -> Void)? = nil
    var showLegend: Bool = true
    var cellAspect: CGFloat = 1.0

    private func monthLabel(for date: Date) -> String {
        let cal = Calendar.current
        let day = cal.component(.day, from: date)
        guard day <= 7 else { return "" }          // only label first row of month
        let monthIdx = cal.component(.month, from: date) - 1

        let abbrevs = DateFormatter().shortMonthSymbols ?? []
        if monthIdx >= 0, monthIdx < abbrevs.count {
            return abbrevs[monthIdx]
        }
        return ""
    }

    private var orderedDates: [[Date]] {
        // Column-major, oldest week on the left, rows Monday->Sunday.
        var columns: [[Date]] = []
        let cal = Calendar.current

        // Monday of CURRENT week
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)          // Sun=1 … Sat=7
        let daysSinceMonday = (weekday + 5) % 7                     // Mon=0, Sun=6
        guard let mondayThisWeek = cal.date(byAdding: .day,
                                            value: -daysSinceMonday,
                                            to: today)
        else { return columns }

        for w in (0..<weeks).reversed() {                           // oldest → newest
            var col: [Date] = []
            for d in 0..<7 {                                        // Mon→Sun rows
                if let date = cal.date(byAdding: .day,
                                        value: -(w * 7) + d,
                                        to: mondayThisWeek) {
                    col.append(date)
                }
            }
            columns.append(col)
        }
        return columns
    }

    private func weekdayLabel(for row: Int) -> String {
        switch row {          // 0 = Monday … 6 = Sunday
        case 0: return "Mon"
        case 3: return "Thu"
        case 6: return "Sun"
        default: return ""
        }
    }

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat     = 4
            let labelWidth: CGFloat = 24

            // width available for the coloured cells
            let available = geo.size.width - labelWidth - gap - CGFloat(weeks - 1) * gap
            let cell = available / CGFloat(weeks)
            let cellHeight = cell * cellAspect

            VStack(alignment: .leading, spacing: 6) {

                // MONTH LABEL ROW -----------------------------------------
                HStack(alignment: .center, spacing: gap) {
                    Text("")                                        // spacer
                        .frame(width: labelWidth, height: cellHeight)
                    ForEach(orderedDates.indices, id: \.self) { idx in
                        let label = monthLabel(for: orderedDates[idx].first!)
                        Text(label)
                            .font(.caption2)
                            .frame(minWidth: cell, alignment: .leading)
                            .fixedSize()            // don’t wrap; expand horizontally if needed
                            .opacity(label.isEmpty ? 0 : 1)
                    }
                }

                // WEEKDAY LABEL COLUMN ------------------------------------
                HStack(alignment: .top, spacing: gap) {

                    VStack(spacing: gap) {
                        ForEach(0..<7) { row in
                            Text(weekdayLabel(for: row))
                                .font(.caption2)
                                .frame(width: labelWidth,
                                       height: cellHeight,
                                       alignment: .leading)
                                .opacity(weekdayLabel(for: row).isEmpty ? 0 : 1)
                        }
                    }

                    // COLOURED GRID ---------------------------------------
                    HStack(alignment: .top, spacing: gap) {
                        ForEach(orderedDates, id: \.self) { column in
                            VStack(spacing: gap) {
                                ForEach(column, id: \.self) { day in
                                    let colour   = DayColour.colour(for: dayCounts[day] ?? 0)
                                    let isToday  = Calendar.current.isDateInToday(day)
                                    let isFuture = day > Calendar.current.startOfDay(for: Date())

                                    Rectangle()
                                        .fill((isFuture && !isToday) ? Color.clear : colour)
                                        .frame(width: cell, height: cellHeight)
                                        .cornerRadius(cell * 0.22)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: cell * 0.22)
                                                .stroke(Color.accentColor,
                                                        lineWidth: isToday ? 1 : 0)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            guard !(isFuture && !isToday) else { return }
                                            onDayTapped?(day)
                                        }
                                }
                            }
                        }
                    }
                }

                // LEGEND ------------------------------------------------------------------
                if showLegend {
                    HStack(spacing: 4) {
                        Text("")                                   // spacer
                            .frame(width: labelWidth)
                        Text("Less").font(.caption2)
                        ForEach(1..<DayColour.levels.count, id: \.self) { idx in
                            Rectangle()
                                .fill(DayColour.levels[idx])
                                .frame(width: cell, height: cellHeight)
                                .cornerRadius(cell * 0.22)
                        }
                        Text("More").font(.caption2)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}
