import Foundation

struct IdentifiableDate: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
    
    init(_ date: Date) {
        self.date = date
    }
}