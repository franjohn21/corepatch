import SwiftUI

struct CompletionScreen: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Welcome to your transformation journey, \(coordinator.userName)!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 20) {
                Text("You're ready to start your 21-day evidence collection program")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                VStack(spacing: 15) {
                    FeatureRow(icon: "brain.head.profile", text: "Daily challenges personalized to your core wound")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress as new neural pathways form")
                    FeatureRow(icon: "person.2.fill", text: "Join a community of others on the same journey")
                }
                .padding(.horizontal, 20)
            }
            
            Button(action: {
                coordinator.completeOnboarding()
                hasCompletedOnboarding = true
            }) {
                Text("Begin My Journey")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 25)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}