import Foundation

extension Date: Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
