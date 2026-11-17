import SwiftUI

/// NevercryNow 标识：渐变底 + 白色圆角块 + 里面的终端提示符。
/// 和 `brand/mark.svg`、App 图标同一套比例（都以边长 1000 为单位）。
struct BrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.235, style: .continuous)
                .fill(Theme.markGradient)

            RoundedRectangle(cornerRadius: size * 0.109, style: .continuous)
                .fill(.white)
                .frame(width: size * 0.586, height: size * 0.586)

            Path { path in
                path.move(to: CGPoint(x: size * 0.389, y: size * 0.383))
                path.addLine(to: CGPoint(x: size * 0.5, y: size * 0.5))
                path.addLine(to: CGPoint(x: size * 0.389, y: size * 0.617))
            }
            .stroke(
                Theme.ink,
                style: StrokeStyle(lineWidth: size * 0.055, lineCap: .round, lineJoin: .round)
            )

            Capsule()
                .fill(Theme.ink)
                .frame(width: size * 0.107, height: size * 0.055)
                .offset(x: size * 0.0925, y: size * 0.117)
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

/// 关于与制作人员。
struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Member: Identifiable {
        let id = UUID()
        let name: String
        let role: String
    }

    private let members: [Member] = [
        Member(name: "郑壹鸣", role: "设计与开发"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    people
                    stack
                    legal
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(AmbientBackdrop(intensity: 0.5))
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                BrandMark(size: 72)
                BrandWordmark()
                Spacer()
            }

            Text("一个能装进口袋的 DeepSeek Harness 客户端。本机直连模型，也能连上跑 `dsh web` 的电脑；"
                 + "界面按 tv 与 Apple Music 的版式重做，玻璃只出现在该出现的地方。")
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            BrandBadge()
        }
    }

    private var people: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("制作人员")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .textCase(.uppercase)
                .tracking(1.2)

            ForEach(members) { member in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.markGradient)
                            .frame(width: 38, height: 38)
                        Text(String(member.name.prefix(1)))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(member.role)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer()
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var stack: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("技术")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .textCase(.uppercase)
                .tracking(1.2)

            Text("SwiftUI · WebKit · App Intents · ActivityKit · GitHub Actions")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))

            Text("配色：靛蓝 #5B8CFF → 薄荷 #57E0B8；暗色底 #0B0B0F。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.dim)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var legal: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("版本")
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text(Bundle.main.appVersion)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }
            HStack {
                Text("许可")
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text("MIT")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }
            Link(destination: URL(string: "https://github.com/NevercRyNow/ncnsdsh")!) {
                Text("github.com/NevercRyNow/ncnsdsh")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 2)
        }
        .font(.system(size: 13))
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
