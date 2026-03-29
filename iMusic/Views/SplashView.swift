import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var hatRotation: Double = -15
    @State private var waveOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Ocean gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.12, blue: 0.28),
                    Color(red: 0.06, green: 0.22, blue: 0.45),
                    Color(red: 0.08, green: 0.30, blue: 0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated wave lines
            VStack {
                Spacer()
                ZStack {
                    ForEach(0..<3) { i in
                        WaveShape(offset: waveOffset + CGFloat(i) * 40)
                            .fill(Color.white.opacity(0.04 + Double(i) * 0.02))
                            .frame(height: 80)
                            .offset(y: CGFloat(i * 12))
                    }
                }
                .frame(height: 100)
            }
            .ignoresSafeArea()

            // Gold decorative circles
            Circle()
                .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.08), lineWidth: 1)
                .frame(width: 280, height: 280)
            Circle()
                .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.05), lineWidth: 1)
                .frame(width: 220, height: 220)

            VStack(spacing: 24) {
                // Logo with gold ring
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3),
                                    Color(red: 0.85, green: 0.65, blue: 0.0).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 130, height: 130)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                    Color(red: 0.85, green: 0.55, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 130, height: 130)

                    Image("iMusicLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4), radius: 16, y: 6)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .rotation3DEffect(.degrees(hatRotation), axis: (x: 0, y: 1, z: 0))

                VStack(spacing: 8) {
                    Text("iMusic")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.92, blue: 0.4),
                                    Color(red: 1.0, green: 0.75, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 8)

                    Text("Your music, your way.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .italic()
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
                hatRotation = 0
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.5)) {
                textOpacity = 1.0
                textOffset = 0
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                waveOffset = 60
            }
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: midHeight))
        for x in stride(from: 0, through: width, by: 2) {
            let y = midHeight + sin((x + offset) / 30) * 10
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}
