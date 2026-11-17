import SwiftUI

/// 液态玻璃的拖拽形变：横向拉伸、纵向压缩、轻微旋转，松手用弹簧回位。
/// 只挂在「可以拿起来的」东西上（运行中胶囊、hero 卡、审批把手），列表行和气泡不动。
struct LiquidDrag: ViewModifier {
    var threshold: CGFloat = 90
    var maxStretch: CGFloat = 0.14
    var maxSquash: CGFloat = 0.10

    @State private var offset: CGSize = .zero
    @State private var armed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: 1 + min(abs(offset.width) / 500, maxStretch),
                y: 1 - min(abs(offset.width) / 1400, maxSquash)
            )
            .rotationEffect(.degrees(min(max(Double(offset.width) / 28, -10), 10)))
            .offset(offset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        offset = value.translation
                        let crossed = abs(value.translation.width) > threshold
                        if crossed != armed {
                            armed = crossed
                            if crossed { Haptics.soft() }
                        }
                    }
                    .onEnded { value in
                        let extra = value.predictedEndTranslation.width - value.translation.width
                        armed = false
                        withAnimation(
                            .interpolatingSpring(stiffness: 210, damping: 14, initialVelocity: Double(extra) / 600)
                        ) {
                            offset = .zero
                        }
                    }
            )
    }
}

extension View {
    /// 拖拽 → 形变 → 回弹。
    func liquidDrag(threshold: CGFloat = 90) -> some View {
        modifier(LiquidDrag(threshold: threshold))
    }
}

/// 卡片入场：轻微上浮 + 淡入，给首页 shelf 用。
struct RiseIn: ViewModifier {
    var delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.86).delay(delay)) {
                    shown = true
                }
            }
    }
}

extension View {
    func riseIn(delay: Double = 0) -> some View {
        modifier(RiseIn(delay: delay))
    }
}
