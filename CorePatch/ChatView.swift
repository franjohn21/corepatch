import SwiftUI
import SwiftData
import NaturalLanguage

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var chatManager: ChatManager?
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
                            if chatManager?.currentSession?.messages.isEmpty ?? true {
                                ChatBubble(
                                    message: ChatMessage(
                                        content: "Hey there! What's up? How can I help you today?",
                                        isFromUser: false
                                    ),
                                    showTimestamp: true
                                )
                            }
                        }
                        .padding(.top, 20)
                        
                        // Chat messages - sorted by timestamp for chronological order
                        ForEach(Array((chatManager?.currentSession?.messages.sorted { $0.timestamp < $1.timestamp } ?? []).enumerated()), id: \.element.id) { index, message in
                            ChatBubble(
                                message: message,
                                showTimestamp: shouldShowTimestamp(
                                    for: message,
                                    at: index,
                                    in: chatManager?.currentSession?.messages.sorted { $0.timestamp < $1.timestamp } ?? []
                                )
                            )
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
                .onChange(of: chatManager?.currentSession?.messages.count ?? 0) {
                    // Auto-scroll to bottom when new message arrives
                    if let lastMessage = chatManager?.currentSession?.messages.sorted(by: { $0.timestamp < $1.timestamp }).last {
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
        .onAppear {
            if chatManager == nil {
                chatManager = ChatManager(modelContext: modelContext)
            }
        }
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Clear input
        inputText = ""
        
        // Show typing indicator
        isTyping = true
        
        // Send message and get response via API
        Task {
            await sendMessageViaAPI(trimmedText)
        }
    }
    
    private func sendMessageViaAPI(_ message: String) async {
        guard let chatManager = chatManager else { return }
        
        // First, add the user message locally
        await MainActor.run {
            chatManager.addMessage(content: message, isFromUser: true)
        }
        
        do {
            // Send to API and get response
            let response = try await chatManager.sendChatMessage(message)
            
            await MainActor.run {
                isTyping = false
                // Response is already added to chat by the manager in sendChatMessage
            }
        } catch {
            await MainActor.run {
                isTyping = false
                // Add error message
                chatManager.addMessage(
                    content: "Sorry, I couldn't process your message. Please try again.",
                    isFromUser: false
                )
            }
            print("Error sending chat message: \(error)")
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
    
    private func shouldShowTimestamp(for message: ChatMessage, at index: Int, in messages: [ChatMessage]) -> Bool {
        // Always show timestamp for first message
        if index == 0 {
            return true
        }
        
        // Get previous message
        let previousMessage = messages[index - 1]
        
        // Show timestamp if more than 5 minutes have passed
        let timeDifference = message.timestamp.timeIntervalSince(previousMessage.timestamp)
        if timeDifference > 300 { // 5 minutes
            return true
        }
        
        // Show timestamp if it's a different day
        let calendar = Calendar.current
        if !calendar.isDate(message.timestamp, inSameDayAs: previousMessage.timestamp) {
            return true
        }
        
        return false
    }
}

// Note: ChatMessage is now defined in Models/ChatMessage.swift

struct ChatBubble: View {
    let message: ChatMessage
    let showTimestamp: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Show timestamp if it's been a while since last message
            if showTimestamp {
                Text(formatTimestamp(message.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                if message.isFromUser {
                    Spacer()
                    
                    // Hidden timestamp that appears on drag
                    if isDragging || dragOffset < -20 {
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .animation(.easeOut(duration: 0.2), value: isDragging)
                    }
                    
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                        .frame(maxWidth: 280, alignment: .trailing)
                } else {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                        .frame(maxWidth: 280, alignment: .leading)
                    
                    // Hidden timestamp that appears on drag
                    if isDragging || dragOffset < -20 {
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            .animation(.easeOut(duration: 0.2), value: isDragging)
                    }
                    
                    Spacer()
                }
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                            // Only allow dragging to the left to reveal timestamps
                            dragOffset = min(0, value.translation.width)
                            isDragging = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            dragOffset = 0
                            isDragging = false
                        }
                    }
            )
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        return date.formatted(date: .omitted, time: .shortened)
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
