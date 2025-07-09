import Foundation
import SwiftUI
import SwiftData

// MARK: - Feedback Models
struct EntryFeedback: Codable {
    let feedback: String
    let generatedAt: Date
}


// MARK: - Feedback Manager
@MainActor
class FeedbackManager: ObservableObject {
    @Published var isGenerating: Bool = false
    
    private let modelContext: ModelContext
    private let networkManager: FeedbackNetworkManager
    private var chatManager: ChatManager?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.chatManager = ChatManager(modelContext: modelContext)
        self.networkManager = FeedbackNetworkManager(chatManager: chatManager!)
    }
    
    // MARK: - Generate Feedback for Entry
    func generateFeedback(for entry: CorePatchEntry) async {
        print("DEBUG FeedbackManager: generateFeedback called for entry with \(entry.completedCategories.count) completed categories")
        
        // Check if entry already has feedback
        if entry.feedback != nil {
            print("DEBUG FeedbackManager: Entry already has feedback, skipping")
            return
        }
        
        // Check if there are completed categories
        if entry.completedCategories.isEmpty {
            print("DEBUG FeedbackManager: No completed categories, skipping feedback generation")
            return
        }
        
        isGenerating = true
        
        do {
            print("DEBUG FeedbackManager: Calling networkManager.generateFeedback")
            let feedback = try await networkManager.generateFeedback(
                categoryTexts: entry.categoryTexts,
                woundID: entry.woundID,
                date: entry.createdAt,
                counterBelief: entry.oppositeBelief
            )
            
            print("DEBUG FeedbackManager: Feedback generated successfully")
            // Save feedback directly to the entry
            entry.feedback = feedback.feedback
            entry.feedbackGeneratedAt = feedback.generatedAt
            
            // Also add feedback to chat with form data and counter belief
            let formData = entry.categoryTexts
            let counterBelief = entry.oppositeBelief
            chatManager?.addFeedbackToChat(
                feedback: feedback.feedback, 
                entryID: entry.id, 
                formData: formData, 
                counterBelief: counterBelief,
                date: entry.createdAt
            )
            
            try modelContext.save()
            print("DEBUG FeedbackManager: Feedback saved to entry and chat")
            
        } catch {
            print("DEBUG FeedbackManager: Feedback generation failed: \(error)")
        }
        
        isGenerating = false
    }
    
}

// MARK: - Network Manager
@MainActor
class FeedbackNetworkManager {
    private let apiURL = "https://api.snapfont.app/api/corepatch/chat"
    private let chatManager: ChatManager
    
    init(chatManager: ChatManager) {
        self.chatManager = chatManager
    }
    
    func generateFeedback(categoryTexts: [String: String], woundID: CoreWoundID, date: Date, counterBelief: String) async throws -> EntryFeedback {
        print("DEBUG NetworkManager: generateFeedback called with \(categoryTexts.count) categories")
        
        guard let url = URL(string: apiURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Map internal categories to API schema
        let mappedAreas = mapCategoriesToAPISchema(categoryTexts)
        
        // Build messages array with chat history
        var messages: [ChatRequestMessage] = []
        
        // Add existing chat history
        if let currentSession = chatManager.currentSession {
            for chatMessage in currentSession.messages {
                // Only include general chat messages, not feedback-related messages
                if chatMessage.messageType == .general {
                    messages.append(ChatRequestMessage(
                        role: chatMessage.isFromUser ? "user" : "assistant",
                        content: chatMessage.content,
                        timestamp: ISO8601DateFormatter().string(from: chatMessage.timestamp),
                        formData: nil
                    ))
                }
            }
        }
        
        // Add the current submission
        messages.append(ChatRequestMessage(
            role: "user",
            content: "Here's my daily evidence that '\(counterBelief)' for \(date.formatted(date: .abbreviated, time: .omitted))",
            timestamp: ISO8601DateFormatter().string(from: date),
            formData: ChatFormData(
                date: date.formatted(.iso8601.year().month().day()),
                areas: mappedAreas
            )
        ))
        
        let payload = ChatRequest(
            messages: messages,
            userId: "corepatch-user" // You might want to make this dynamic
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("DEBUG NetworkManager: HTTP Error - Status: \(statusCode)")
            throw NetworkError.serverError
        }
        
        // Debug: Print the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("DEBUG NetworkManager: Raw API Response: \(responseString)")
        }
        
        // Decode the response
        do {
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            return EntryFeedback(
                feedback: chatResponse.message.content,
                generatedAt: Date()
            )
        } catch {
            print("DEBUG NetworkManager: Failed to decode response: \(error)")
            
            // If decoding fails, use raw response as fallback
            if let responseString = String(data: data, encoding: .utf8) {
                return EntryFeedback(feedback: responseString, generatedAt: Date())
            }
            
            throw error
        }
    }
    
    private func mapCategoriesToAPISchema(_ categoryTexts: [String: String]) -> [String: String] {
        var mapped: [String: String] = [:]
        
        for (key, value) in categoryTexts {
            let mappedKey: String
            switch key {
            case "emotion":
                mappedKey = "emotional"
            case "social":
                mappedKey = "relationships"
            case "finances":
                mappedKey = "financial"
            default:
                mappedKey = key
            }
            mapped[mappedKey] = value
        }
        
        return mapped
    }
}

// MARK: - Helper Models
struct ChatRequest: Codable {
    let messages: [ChatRequestMessage]
    let userId: String
}

struct ChatRequestMessage: Codable {
    let role: String
    let content: String
    let timestamp: String
    let formData: ChatFormData?
}

struct ChatFormData: Codable {
    let date: String
    let areas: [String: String]
}

struct ChatResponse: Codable {
    let message: ChatMessageResponse
}

struct ChatMessageResponse: Codable {
    let role: String
    let content: String
}

enum NetworkError: Error {
    case invalidURL
    case serverError
    case noData
}