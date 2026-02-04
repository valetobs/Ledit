import SwiftUI

struct SplashScreen: View {
    @State private var iconOpacity: Double = 0
    @State private var iconScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    @State private var fadeOut: Double = 1.0
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Clean dark background
            Color(red: 0.06, green: 0.06, blue: 0.08)
                .ignoresSafeArea()
            
            // Centered content
            VStack(spacing: 20) {
                // Simple icon
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 50, weight: .thin))
                    .foregroundColor(.white)
                    .opacity(iconOpacity)
                    .scaleEffect(iconScale)
                
                // App name
                Text("Ledit")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
            }
        }
        .opacity(fadeOut)
        .onAppear {
            // Icon fades in and scales up
            withAnimation(.easeOut(duration: 0.6)) {
                iconOpacity = 1
                iconScale = 1.0
            }
            
            // Text fades in after icon
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1
            }
            
            // Fade out and transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    fadeOut = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Animated Transition Modifier
struct SlideTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 50)
    }
}

extension View {
    func slideTransition(isPresented: Bool) -> some View {
        modifier(SlideTransition(isPresented: isPresented))
    }
}

// MARK: - Bounce Animation
struct BounceEffect: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func bounceEffect() -> some View {
        modifier(BounceEffect())
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

#Preview {
    SplashScreen(onComplete: {})
}
