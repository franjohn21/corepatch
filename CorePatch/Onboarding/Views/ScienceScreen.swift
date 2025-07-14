import SwiftUI

struct ScienceScreen: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("Your brain is more changeable than you think")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 25) {
                ScienceFactCard(
                    icon: "brain",
                    title: "Neuroplasticity",
                    description: "New neural pathways form at any age through repeated practice"
                )
                
                ScienceFactCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Evidence-Based",
                    description: "Built on CBT, Attachment Theory, and Schema Therapy research"
                )
                
                ScienceFactCard(
                    icon: "clock",
                    title: "Realistic Timeline",
                    description: "Meaningful changes in 21 days, lasting transformation in 66 days"
                )
            }
            
            Text("No magic. Just science.")
                .font(.title2)
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct ScienceFactCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}