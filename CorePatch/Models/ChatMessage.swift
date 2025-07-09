import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var timestamp: Date
    var isFromUser: Bool
    var messageType: MessageType
    var relatedEntryID: UUID?
    @Relationship(inverse: \ChatSession.messages) var session: ChatSession?
    
    init(content: String, isFromUser: Bool, messageType: MessageType = .general, relatedEntryID: UUID? = nil) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.isFromUser = isFromUser
        self.messageType = messageType
        self.relatedEntryID = relatedEntryID
    }
}

enum MessageType: String, CaseIterable, Codable {
    case general = "general"
    case feedback = "feedback"
    case dailyReflection = "daily_reflection"
}