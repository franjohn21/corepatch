import SwiftUI

struct NameInputScreen: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("What should we call you?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We'll personalize your journey")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                TextField("Your name", text: $coordinator.userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .padding(.horizontal, 40)
                
                Text("Don't worry, this stays private")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}