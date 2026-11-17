import SwiftUI

struct LocalChatView: View {
    let sessionID: UUID

    @EnvironmentObject private var local: LocalStore
    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var chrome: AppChrome
    @Environment(\.scenePhase) private var scenePhase

    @State private var draft = ""
    @State private var showModelPicker = false
    @State private var pickedModel: String = ""
    @FocusState private var composerFocused: Bool

    private var session: LocalSession? { local.session(sessionID) }
    private var messages: [LocalMessage] { session?.messages ?? [] }
    private var isRunning: Bool { local.runningID == sessionID }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if messages.isEmpty {
                        CodexIntro(model: pickedModel.isEmpty ? (session?.model ?? account.selectedModel) : pickedModel) {
                            showModelPicker = true
                        }
                    }

                    ForEach(messages) { message in
                        LocalMessageRow(message: message)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    .animation(Motion.panel, value: messages.count)

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.bottom)
            .onChange(of: messages.count) { _, _ in
                withAnimation(Motion.gentle) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: messages.last?.text.count ?? 0) { _, _ in
                if isRunning {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .background(DSH.Palette.canvas)
        .navigationTitle(session?.title ?? "本机会话")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isRunning {
                    Button("停止") {
                        Haptics.soft()
                        local.stop()
                    }
                    .font(.system(size: 13, weight: .semibold))
                }
            }
        }
        .onAppear {
            pickedModel = session?.model ?? account.selectedModel
            chrome.chatOpen = true
        }
        .onDisappear { chrome.chatOpen = false }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let error = local.error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0xFFB86B))
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                composer
            }
            .background(Theme.ink.opacity(0.001))
        }
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "cpu")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.mint)
            Text("本机模式")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("不连电脑，模型直连 DeepSeek。它能读写这个 App 的工作区（\(LocalTools.names.joined(separator: " / "))），文件放在「文件」App 的「我的 iPhone → NcnsDSH → workspace」里。")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 28)
    }

    private var composer: some View {
        ComposerBar(
            text: $draft,
            placeholder: "让本机做点什么…",
            model: pickedModel.isEmpty ? (session?.model ?? account.selectedModel) : pickedModel,
            isBusy: isRunning,
            onSend: {
                let outgoing = draft
                draft = ""
                local.send(
                    outgoing,
                    in: sessionID,
                    model: pickedModel.isEmpty ? (session?.model ?? account.selectedModel) : pickedModel,
                    key: account.key
                )
            },
            focused: $composerFocused
        )
    }

    private func send() {
        let text = draft
        draft = ""
        Haptics.soft()
        local.send(text, in: sessionID, model: session?.model ?? account.selectedModel, key: account.key)
    }
}

private struct LocalMessageRow: View {
    let message: LocalMessage

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 56)
                Text(message.text)
                    .font(DSH.TypeScale.body)
                    .foregroundStyle(DSH.Palette.text)
                    .multilineTextAlignment(.trailing)
                    .textSelection(.enabled)
            }

        case .tool:
            HStack(spacing: 10) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.mint)
                    .frame(width: 22, height: 22)
                    .background(Theme.mint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(message.toolName ?? "tool")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                    Text(message.text.replacingOccurrences(of: "\n", with: " · "))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: DSH.Radius.card, style: .continuous))

        case .assistant, .system:
            VStack(alignment: .leading, spacing: 8) {
                if message.text.isEmpty {
                    ShimmerLine(color: Theme.mint).frame(width: 120)
                } else {
                    Text(message.text)
                        .font(DSH.TypeScale.body)
                        .lineSpacing(5)
                        .foregroundStyle(.white.opacity(0.94))
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
