import SwiftUI
import NaturalLanguage

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Character placeholder at top
                        VStack(spacing: 20) {
                            // Placeholder for animated character
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 160)
                                .overlay(
                                    Text("Character\nPlaceholder")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                )
                            
                            // Welcome message
                            if messages.isEmpty {
                                ChatBubble(
                                    message: ChatMessage(
                                        id: "welcome",
                                        text: "Hey there! What's up? How can I help you today?",
                                        isFromUser: false,
                                        timestamp: Date()
                                    )
                                )
                            }
                        }
                        .padding(.top, 20)
                        
                        // Chat messages
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Typing indicator
                        if isTyping {
                            TypingIndicator()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .onChange(of: messages.count) { _ in
                    // Auto-scroll to bottom when new message arrives
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 12) {
                    // Text input
                    TextField("Message", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .lineLimit(1...4)
                    
                    // Send button
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            text: trimmedText,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Clear input
        inputText = ""
        
        // Show typing indicator
        isTyping = true
        
        // Generate AI response
        Task {
            await generateAIResponse(to: trimmedText)
        }
    }
    
    private func generateAIResponse(to userMessage: String) async {
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            isTyping = false
            
            // Generate response using Apple's on-device NL processing
            let response = generateLocalResponse(for: userMessage)
            
            let aiMessage = ChatMessage(
                id: UUID().uuidString,
                text: response,
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
        }
    }
    
    private func generateLocalResponse(for input: String) -> String {
        // Simple local AI responses - replace with Apple Intelligence API when available
        let lowercaseInput = input.lowercased()
        
        // Mental health focused responses
        if lowercaseInput.contains("anxious") || lowercaseInput.contains("anxiety") {
            return "I understand you're feeling anxious. Try taking three deep breaths with me. Breathe in for 4 counts, hold for 4, and breathe out for 6. You're doing great by reaching out. 🌸"
        }
        
        if lowercaseInput.contains("sad") || lowercaseInput.contains("down") || lowercaseInput.contains("depressed") {
            return "I hear that you're feeling down. Those feelings are valid, and it's okay to have difficult days. What's one small thing that usually brings you a little comfort? 💙"
        }
        
        if lowercaseInput.contains("stressed") || lowercaseInput.contains("overwhelmed") {
            return "Feeling overwhelmed is tough. Let's break things down together. What's the most pressing thing on your mind right now? Sometimes just naming it can help. 🌱"
        }
        
        if lowercaseInput.contains("sleep") || lowercaseInput.contains("tired") {
            return "Sleep is so important for our wellbeing. Have you tried a relaxing bedtime routine? Even 10 minutes of gentle stretching or meditation can help prepare your mind for rest. 🌙"
        }
        
        if lowercaseInput.contains("grateful") || lowercaseInput.contains("thankful") || lowercaseInput.contains("appreciate") {
            return "I love that you're focusing on gratitude! It's such a powerful practice for mental health. What's bringing you joy today? ✨"
        }
        
        if lowercaseInput.contains("help") || lowercaseInput.contains("support") {
            return "I'm here to support you! Whether you need someone to listen, want to explore coping strategies, or just need encouragement, I'm glad you reached out. What would be most helpful right now? 🤗"
        }
        
        // Greeting responses
        if lowercaseInput.contains("hello") || lowercaseInput.contains("hi") || lowercaseInput.contains("hey") {
            return "Hello! I'm so glad you're here. How are you feeling today? Remember, there's no pressure to be anything other than exactly where you are right now. 💫"
        }
        
        // Default empathetic response
        return "Thank you for sharing that with me. I'm here to listen and support you. Your feelings and experiences matter. How can I help you process what you're going through? 🌿"
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                    .frame(maxWidth: 280, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                    .frame(maxWidth: 280, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            animationOffset = 2
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
