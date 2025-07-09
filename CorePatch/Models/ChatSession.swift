import Foundation
import SwiftData

@Model
final class ChatSession {
    var id: UUID
    var createdAt: Date
    var title: String
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage]
    
    init(title: String = "Chat Session") {
        self.id = UUID()
        self.createdAt = Date()
        self.title = title
        self.messages = []
    }
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        message.session = self
    }
    
    var lastMessage: ChatMessage? {
        messages.last
    }
    
    var messageCount: Int {
        messages.count
    }
}