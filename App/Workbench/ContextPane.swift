import SwiftUI

/// 上下文：本机会话的 token 账本 + 一键压缩。
struct ContextPane: View {
    let sessionID: UUID?

    @EnvironmentObject private var local: LocalStore
    @State private var confirming = false

    private let budget = 128_000

    private var session: LocalSession? {
        guard let sessionID else { return nil }
        return local.session(sessionID)
    }

    private var messageTokens: Int {
        let chars = session?.messages.reduce(0) { $0 + $1.text.count } ?? 0
        return Int(Double(chars) * 0.62)
    }

    private var systemTokens: Int { 1_450 }
    private var toolTokens: Int { 24_300 }

    private var used: Int { systemTokens + toolTokens + messageTokens }
    private var ratio: Double { min(1, Double(used) / Double(budget)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(String(format: "%.0f%%", ratio * 100))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(DSH.Palette.text)
                    .contentTransition(.numericText())

                ProgressView(value: ratio)
                    .tint(DSH.Palette.accent)
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                Text("上下文已用 \(short(used)) / \(short(budget)) tokens")
                    .font(DSH.TypeScale.footnote)
                    .foregroundStyle(DSH.Palette.secondary)

                VStack(spacing: 0) {
                    row("系统提示词", short(systemTokens))
                    divider
                    row("工具定义", short(toolTokens))
                    divider
                    row("对话消息", short(messageTokens))
                    divider
                    row("工作目录", session == nil ? "—" : "workspace")
                }
                .padding(.horizontal, 16)

                Button {
                    confirming = true
                } label: {
                    Text("压缩上下文")
                        .font(DSH.TypeScale.headline)
                        .foregroundStyle(DSH.Palette.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(DSH.Palette.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(session == nil)
                .opacity(session == nil ? 0.4 : 1)
            }
            .padding(20)
        }
        .confirmationDialog("保留最近 12 条消息，其余从本机记录里去掉？", isPresented: $confirming, titleVisibility: .visible) {
            Button("压缩", role: .destructive) {
                if let sessionID { local.compress(sessionID) }
                Haptics.success()
            }
            Button("取消", role: .cancel) {}
        }
    }

    private var divider: some View {
        Divider().overlay(DSH.Palette.hairline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(DSH.TypeScale.body)
                .foregroundStyle(DSH.Palette.text)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(DSH.Palette.secondary)
        }
        .padding(.vertical, 12)
    }

    private func short(_ value: Int) -> String {
        if value >= 10_000 { return String(format: "%.1f 万", Double(value) / 10_000) }
        return "\(value)"
    }
}
