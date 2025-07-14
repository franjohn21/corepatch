import SwiftUI

struct ProblemRecognitionScreen: View {
    @State private var checkedItems: Set<Int> = []
    
    let problems = [
        "Achieving more but feeling emptier",
        "Relationships that feel one-sided",
        "Success that never feels \"enough\"",
        "Exhaustion from perfectionism",
        "Fear of being \"found out\"",
        "Difficulty saying no to others"
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("You've probably noticed these patterns...")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("Check all that apply:")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 15) {
                ForEach(Array(problems.enumerated()), id: \.offset) { index, problem in
                    HStack {
                        Button(action: {
                            if checkedItems.contains(index) {
                                checkedItems.remove(index)
                            } else {
                                checkedItems.insert(index)
                            }
                        }) {
                            HStack {
                                Image(systemName: checkedItems.contains(index) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(checkedItems.contains(index) ? .blue : .gray)
                                    .font(.title2)
                                
                                Text(problem)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            if !checkedItems.isEmpty {
                Text("These aren't character flaws. They're protective patterns your brain created long ago.")
                    .font(.body)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}