import Foundation
import SwiftData

@MainActor
class ChatManager: ObservableObject {
    private let modelContext: ModelContext
    @Published var currentSession: ChatSession?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateCurrentSession()
    }
    
    private func loadOrCreateCurrentSession() {
        let descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            if let latestSession = sessions.first {
                currentSession = latestSession
            } else {
                createNewSession()
            }
        } catch {
            print("Error loading chat sessions: \(error)")
            createNewSession()
        }
    }
    
    private func createNewSession() {
        let session = ChatSession(title: "Chat Session")
        modelContext.insert(session)
        currentSession = session
        saveContext()
    }
    
    func addMessage(content: String, isFromUser: Bool, messageType: MessageType = .general, relatedEntryID: UUID? = nil) {
        print("DEBUG ChatManager: Adding message - isFromUser: \(isFromUser), type: \(messageType), content: \(String(content.prefix(50)))...")
        
        guard let session = currentSession else {
            createNewSession()
            return
        }
        
        let message = ChatMessage(
            content: content,
            isFromUser: isFromUser,
            messageType: messageType,
            relatedEntryID: relatedEntryID
        )
        
        session.addMessage(message)
        saveContext()
        
        print("DEBUG ChatManager: Total messages in session: \(session.messages.count)")
    }
    
    func addFeedbackToChat(feedback: String, entryID: UUID, formData: [String: String], counterBelief: String, date: Date) {
        // Format the user message with actual form data
        let userPrompt = formatUserReflection(formData: formData, counterBelief: counterBelief, date: date)
        
        addMessage(
            content: userPrompt,
            isFromUser: true,
            messageType: .dailyReflection,
            relatedEntryID: entryID
        )
        
        addMessage(
            content: feedback,
            isFromUser: false,
            messageType: .feedback,
            relatedEntryID: entryID
        )
    }
    
    private func formatUserReflection(formData: [String: String], counterBelief: String, date: Date) -> String {
        var reflection = "Here's my daily evidence that '\(counterBelief)' for \(date.formatted(date: .abbreviated, time: .omitted)):\n\n"
        
        for (category, text) in formData {
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                reflection += "**\(category.capitalized)**: \(text)\n\n"
            }
        }
        
        reflection += "Can you provide some insights?"
        return reflection
    }
    
    func sendChatMessage(_ message: String) async throws -> String {
        // Create network manager for this request
        let networkManager = ChatNetworkManager()
        
        // Build full conversation history INCLUDING the message that was just added
        var messages: [ChatAPIMessage] = []
        
        // Add all existing messages (which now includes the user's message we just added)
        // Sort by timestamp to ensure chronological order
        if let session = currentSession {
            let sortedMessages = session.messages.sorted { $0.timestamp < $1.timestamp }
            for msg in sortedMessages {
                messages.append(ChatAPIMessage(
                    role: msg.isFromUser ? "user" : "assistant",
                    content: msg.content,
                    timestamp: ISO8601DateFormatter().string(from: msg.timestamp)
                ))
            }
        }
        
        // Send to API
        let response = try await networkManager.sendChat(messages: messages)
        
        // Add AI response to chat
        await MainActor.run {
            addMessage(content: response, isFromUser: false)
        }
        
        return response
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving chat context: \(error)")
        }
    }
    
    func getAllSessions() -> [ChatSession] {
        let descriptor = FetchDescriptor<ChatSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching chat sessions: \(error)")
            return []
        }
    }
}