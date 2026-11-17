import SwiftUI

/// 全 App 的「背景呼吸」：两团慢慢漂移的靛蓝/薄荷光，压在近黑底上。
/// 20Hz 刷新足够；开了 Reduce Motion 或没开动画时退化成一张静态渐变。
struct AmbientBackdrop: View {
    var intensity: Double = 1
    var showsMint = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.ink

            if reduceMotion {
                glow(time: 0)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { context in
                    glow(time: context.date.timeIntervalSinceReferenceDate)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func glow(time: TimeInterval) -> some View {
        let x = 0.5 + 0.14 * sin(time / 11)
        let y = 0.20 + 0.06 * cos(time / 13)
        let second = 0.30 * intensity

        return ZStack {
            RadialGradient(
                colors: [Theme.accent.opacity(0.34 * intensity), Color.clear],
                center: UnitPoint(x: x, y: y),
                startRadius: 0,
                endRadius: 460
            )

            if showsMint {
                RadialGradient(
                    colors: [Theme.mint.opacity(second), Color.clear],
                    center: UnitPoint(x: 1 - x, y: 0.86),
                    startRadius: 0,
                    endRadius: 420
                )
            }
        }
    }
}

/// 玻璃表面的高光：一条斜着慢慢扫过的亮带，给 hero 用。
struct SpecularSweep: View {
    var opacity: Double = 0.16
    var period: Double = 9

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            if reduceMotion {
                Color.clear
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let phase = (t.truncatingRemainder(dividingBy: period)) / period
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(opacity), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 0.7, height: geo.size.height * 1.6)
                    .rotationEffect(.degrees(18))
                    .offset(x: -geo.size.width + geo.size.width * 2.1 * phase, y: 0)
                }
                .clipped()
            }
        }
        .allowsHitTesting(false)
    }
}

/// 运行中的呼吸环：只给真正在跑的东西用。
struct BreathingRing: View {
    var color: Color = Theme.mint
    var lineWidth: CGFloat = 1

    @State private var expanded = false

    var body: some View {
        Circle()
            .stroke(color.opacity(0.55), lineWidth: lineWidth)
            .scaleEffect(expanded ? 1.5 : 1)
            .opacity(expanded ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    expanded = true
                }
            }
    }
}
