//
//  CorePatchApp.swift
//  CorePatch
//
//  Created by Francis John on 6/25/25.
//

import SwiftUI
import SwiftData

@main
struct CorePatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var feedbackManager = FeedbackManagerWrapper()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(feedbackManager)
        }
        .modelContainer(for: [UserCoreWound.self, CorePatchEntry.self, ChatMessage.self, ChatSession.self]) { result in
            switch result {
            case .success(let container):
                feedbackManager.setModelContainer(container)
            case .failure(let error):
                print("Failed to create model container: \(error)")
            }
        }
    }
}

// Wrapper to handle FeedbackManager initialization
@MainActor
class FeedbackManagerWrapper: ObservableObject {
    private var manager: FeedbackManager?
    
    var isGenerating: Bool {
        manager?.isGenerating ?? false
    }
    
    func setModelContainer(_ container: ModelContainer) {
        if manager == nil {
            manager = FeedbackManager(modelContext: container.mainContext)
        }
    }
    
    func generateFeedback(for entry: CorePatchEntry) async {
        await manager?.generateFeedback(for: entry)
    }
}
