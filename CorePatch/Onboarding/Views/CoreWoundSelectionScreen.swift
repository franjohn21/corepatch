import SwiftUI

struct CoreWoundSelectionScreen: View {
    @ObservedObject var coordinator: OnboardingCoordinator
    @State private var selectedWoundID: CoreWoundID? = nil
    
    // Simplified wound options for onboarding
    private let woundOptions: [(CoreWoundID, String, String)] = [
        (.PEOPLE_ALWAYS_LEAVE_ME, "\"People always leave me\"", "Fear of abandonment in relationships"),
        (.SOMETHING_IS_WRONG_WITH_ME, "\"Something is wrong with me\"", "Feeling fundamentally flawed or broken"),
        (.IM_NOT_GOOD_ENOUGH, "\"I'm not good enough\"", "Persistent feeling of inadequacy despite achievements"),
        (.I_CANT_TRUST_ANYONE, "\"I can't trust anyone\"", "Difficulty trusting others and being vulnerable"),
        (.I_HAVE_NO_CONTROL, "\"I have no control\"", "Feeling powerless in life situations")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("Which core belief feels most familiar?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("Select the one that resonates most with you:")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 15) {
                ForEach(woundOptions, id: \.0) { wound in
                    WoundOptionCard(
                        id: wound.0,
                        title: wound.1,
                        description: wound.2,
                        isSelected: selectedWoundID == wound.0,
                        onTap: {
                            selectedWoundID = wound.0
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            
            if selectedWoundID != nil {
                Text("This belief likely formed in childhood as a way to protect yourself. The good news? It can be changed.")
                    .font(.body)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onChange(of: selectedWoundID) { _, newValue in
            // Update coordinator when selection changes
            coordinator.selectedCoreWoundID = newValue
        }
    }
}

struct WoundOptionCard: View {
    let id: CoreWoundID
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}