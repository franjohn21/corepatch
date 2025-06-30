import SwiftUI

/// A ultra-realistic "orb" progress gauge with animated gradients and depth.
struct OrbProgressGauge: View {
    /// Progress between 0 and 1.
    var progress: Double
    /// Diameter of the gauge.
    var size: CGFloat = 140
    
    @State private var animationOffset: Double = -180
    @State private var pulseScale: Double = 1.0
    
    private var percentage: Int { Int((progress.clamped(to: 0...1)) * 100) }
    
    var body: some View {
        ZStack {
            // Outer glow layers for depth
            Circle()
                .fill(
                    RadialGradient(colors: [
                        .cyan.opacity(0.4),
                        .blue.opacity(0.2),
                        .clear
                    ],
                    center: .center,
                    startRadius: size * 0.3,
                    endRadius: size * 0.8)
                )
                .frame(width: size * 1.6)
                .blur(radius: 25)
                .scaleEffect(pulseScale)
            
            // Secondary glow
            Circle()
                .fill(.cyan.opacity(0.3))
                .frame(width: size * 1.2)
                .blur(radius: 15)
            
            // Main orb body with multiple layers
            ZStack {
                // Base orb with cloud-like texture
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            .white.opacity(0.9),
                            .cyan.opacity(0.8),
                            .blue.opacity(0.7),
                            .purple.opacity(0.5),
                            .indigo.opacity(0.8)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: size * 0.6)
                    )
                
                // Animated swirling layer
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                .clear,
                                .cyan.opacity(0.6),
                                .blue.opacity(0.4),
                                .purple.opacity(0.3),
                                .clear,
                                .teal.opacity(0.5),
                                .clear
                            ],
                            center: .center,
                            angle: .degrees(animationOffset)
                        )
                    )
                    .blendMode(.overlay)
                
                // Inner highlight for glossy effect
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            .white.opacity(0.6),
                            .white.opacity(0.3),
                            .clear
                        ],
                        center: UnitPoint(x: 0.25, y: 0.25),
                        startRadius: 0,
                        endRadius: size * 0.3)
                    )
                
                // Subtle moving particles effect
                Circle()
                    .fill(
                        RadialGradient(colors: [
                            .white.opacity(0.3),
                            .cyan.opacity(0.2),
                            .clear,
                            .blue.opacity(0.1),
                            .clear
                        ],
                        center: UnitPoint(x: 0.7, y: 0.6),
                        startRadius: size * 0.1,
                        endRadius: size * 0.4)
                    )
                    .rotationEffect(.degrees(animationOffset * 0.7))
                    .blendMode(.screen)
            }
            .frame(width: size * 0.85, height: size * 0.85)
            
            // Progress ring with enhanced styling
            Circle()
                .trim(from: 0, to: progress.clamped(to: 0...1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .teal.opacity(0.9),
                            .green,
                            .mint,
                            .teal.opacity(0.9)
                        ]),
                        center: .center),
                    style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .teal, radius: 8, x: 0, y: 0)
                .animation(.easeInOut(duration: 0.8), value: progress)
            
            // Enhanced percentage label with depth
            Text("\(percentage)%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [
                        .white,
                        .white.opacity(0.9)
                    ], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .shadow(color: .cyan.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            // Continuous back-and-forth swirling animation (autoreverses)
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                animationOffset = 180                    // animate to +180 then reverse
            }

            // Subtle pulse animation stays the same
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
