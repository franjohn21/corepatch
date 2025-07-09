import SwiftUI
import SwiftData

struct FeedbackStatusView: View {
    let date: Date
    let woundID: CoreWoundID
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedbackManager: FeedbackManagerWrapper
    @State private var entry: CorePatchEntry?
    
    var body: some View {
        Group {
            if let entry = entry {
                if let feedbackText = entry.feedback {
                    // Show completed feedback
                    FeedbackCard(
                        feedbackText: feedbackText,
                        generatedAt: entry.feedbackGeneratedAt ?? Date()
                    )
                } else if feedbackManager.isGenerating {
                    // Show generating state
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating insights...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !entry.completedCategories.isEmpty {
                    // Has completed categories but no feedback yet
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("AI feedback available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Generate") {
                            Task {
                                await feedbackManager.generateFeedback(for: entry)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        }
        .task {
            await loadEntry()
        }
    }
    
    private func loadEntry() async {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return }
        
        let woundIDRaw = woundID.rawValue
        let descriptor = FetchDescriptor<CorePatchEntry>(
            predicate: #Predicate { entry in
                entry.woundIDRaw == woundIDRaw &&
                entry.createdAt >= dayStart &&
                entry.createdAt < dayEnd
            }
        )
        
        if let entries = try? modelContext.fetch(descriptor),
           let foundEntry = entries.first {
            await MainActor.run {
                self.entry = foundEntry
            }
        }
    }
}

struct FeedbackCard: View {
    let feedbackText: String
    let generatedAt: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("AI Insights", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("Generated \(generatedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Feedback text
            Text(feedbackText)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}