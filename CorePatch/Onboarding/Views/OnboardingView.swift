import SwiftUI

struct OnboardingView: View {
    @StateObject private var coordinator = OnboardingCoordinator()
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $coordinator.currentPage) {
                WelcomeScreen()
                    .tag(0)
                
                NameInputScreen(coordinator: coordinator)
                    .tag(1)
                
                ProblemRecognitionScreen()
                    .tag(2)
                
                ScienceScreen()
                    .tag(3)
                
                CoreWoundSelectionScreen(coordinator: coordinator)
                    .tag(4)
                
                CompletionScreen(coordinator: coordinator, hasCompletedOnboarding: $hasCompletedOnboarding)
                    .tag(5)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: coordinator.currentPage)
            
            VStack {
                Spacer()
                
                HStack {
                    // Back button
                    if coordinator.currentPage > 0 {
                        Button("Back") {
                            coordinator.previousPage()
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<coordinator.totalPages, id: \.self) { page in
                            Circle()
                                .fill(coordinator.currentPage == page ? Color.white : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Spacer()
                    
                    // Next button
                    if coordinator.currentPage < coordinator.totalPages - 1 {
                        Button("Next") {
                            coordinator.nextPage()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .disabled(!coordinator.canProceed())
                        .opacity(coordinator.canProceed() ? 1.0 : 0.5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .environmentObject(coordinator)
    }
}