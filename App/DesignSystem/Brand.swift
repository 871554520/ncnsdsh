import SwiftUI

/// NevercryNow 标识的 SwiftUI 版本，和 brand/*.svg 同一套比例。
struct BrandMark: View {
    var size: CGFloat = 64
    var showsDot = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.235, style: .continuous)
                .fill(Theme.markGradient)

            Path { path in
                path.move(to: CGPoint(x: size * 0.29, y: size * 0.72))
                path.addLine(to: CGPoint(x: size * 0.29, y: size * 0.28))
                path.addLine(to: CGPoint(x: size * 0.71, y: size * 0.72))
                path.addLine(to: CGPoint(x: size * 0.71, y: size * 0.28))
            }
            .stroke(
                Color.white,
                style: StrokeStyle(lineWidth: size * 0.113, lineCap: .round, lineJoin: .round)
            )

            if showsDot {
                Circle()
                    .fill(Theme.ink.opacity(0.75))
                    .frame(width: size * 0.10, height: size * 0.10)
                    .offset(x: size * 0.26, y: -size * 0.24)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.accent.opacity(0.35), radius: size * 0.28, y: size * 0.12)
    }
}

struct BrandWordmark: View {
    var dark = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NcnsDSH")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(dark ? .white : Theme.ink)
                .tracking(-0.4)
            Text("BY NEVERCRYNOW")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.muted)
                .tracking(2.2)
        }
    }
}

struct BrandBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.mint)
                .frame(width: 6, height: 6)
            Text("MADE BY NEVERCRYNOW")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1.8)
                .foregroundStyle(.white.opacity(0.86))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
        )
    }
}
