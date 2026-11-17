import SwiftUI

/// iPad / 横屏：左侧常驻会话栏，右侧对话——Codex 桌面那种骨架。
struct PadShell: View {
    @EnvironmentObject private var demo: DemoStore
    @EnvironmentObject private var chrome: AppChrome
    @EnvironmentObject private var plugins: PluginStore

    @State private var selected: UUID?
    @State private var showPlugins = false
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selected) {
                Section("会话") {
                    ForEach(demo.sessions) { session in
                        row(session)
                            .tag(session.id)
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(DSH.Palette.canvas)
            .navigationTitle("NcnsDSH")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        demo.newSession()
                        selected = demo.activeSessionID
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    Button {
                        showPlugins = true
                    } label: {
                        Label("插件", systemImage: "puzzlepiece.extension")
                            .font(.footnote.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    .background(DSH.Palette.surface, in: Capsule())

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.footnote.weight(.medium))
                            .frame(width: 40, height: 34)
                    }
                    .buttonStyle(.plain)
                    .background(DSH.Palette.surface, in: Capsule())
                }
                .foregroundStyle(DSH.Palette.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        } detail: {
            NavigationStack {
                if let id = selected {
                    ChatView(sessionID: id)
                } else {
                    emptyDetail
                }
            }
        }
        .tint(DSH.Palette.accent)
        .sheet(isPresented: $showPlugins) {
            PluginsView()
                .environmentObject(plugins)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: selected) { _, value in
            chrome.chatOpen = value != nil
        }
    }

    private func row(_ session: ChatSession) -> some View {
        HStack(spacing: 10) {
            RemoteArtwork(
                seed: session.title,
                github: ProjectMeta.githubSlug(for: session.workspace),
                cornerRadius: 6
            )
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(session.workspace)
                    .font(.system(size: 10))
                    .foregroundStyle(DSH.Palette.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if session.isRunning {
                Circle()
                    .fill(DSH.Palette.accent)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 2)
    }

    private var emptyDetail: some View {
        VStack(spacing: 12) {
            BrandMark(size: 48)
            Text("选一个会话")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(DSH.Palette.text)
            Text("或者按左下角的插件，给会话加能力。")
                .font(DSH.TypeScale.footnote)
                .foregroundStyle(DSH.Palette.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSH.Palette.canvas)
    }
}
