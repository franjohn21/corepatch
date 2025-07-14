import SwiftUI

class OnboardingCoordinator: ObservableObject {
    @Published var currentPage = 0
    @Published var userName = ""
    @Published var selectedCoreWoundID: CoreWoundID? = nil
    @Published var assessmentResponses: [String: Int] = [:]
    
    let totalPages = 6 // Start with 6 screens for now
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            withAnimation {
                currentPage -= 1
            }
        }
    }
    
    func canProceed() -> Bool {
        switch currentPage {
        case 1: // Name input page
            return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 4: // Core wound selection
            return selectedCoreWoundID != nil
        default:
            return true
        }
    }
    
    func completeOnboarding() {
        // Save onboarding data
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(userName, forKey: "userName")
    }
}