import Foundation

struct ChatAPIMessage: Codable {
    let role: String
    let content: String
    let timestamp: String
}

struct ChatAPIRequest: Codable {
    let messages: [ChatAPIMessage]
    let userId: String
}

struct ChatAPIResponse: Codable {
    let message: ChatAPIResponseMessage
}

struct ChatAPIResponseMessage: Codable {
    let role: String
    let content: String
}

class ChatNetworkManager {
    private let apiURL = "https://api.snapfont.app/api/corepatch/chat"
    
    func sendChat(messages: [ChatAPIMessage]) async throws -> String {
        print("DEBUG ChatNetworkManager: Sending \(messages.count) messages to API")
        for (index, msg) in messages.enumerated() {
            print("DEBUG ChatNetworkManager: Message \(index): \(msg.role) - \(String(msg.content.prefix(50)))...")
        }
        
        guard let url = URL(string: apiURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Note: Messages should NOT include formData for regular chat
        let chatMessages = messages.map { msg in
            [
                "role": msg.role,
                "content": msg.content,
                "timestamp": msg.timestamp
            ]
        }
        
        let payload: [String: Any] = [
            "messages": chatMessages,
            "userId": "corepatch-user"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("DEBUG ChatNetworkManager: HTTP Error - Status: \(statusCode)")
            throw URLError(.badServerResponse)
        }
        
        // Debug: Print the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("DEBUG ChatNetworkManager: Raw API Response: \(responseString)")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatAPIResponse.self, from: data)
        return chatResponse.message.content
    }
}