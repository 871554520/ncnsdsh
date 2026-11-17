import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: HostStore
    @EnvironmentObject private var demo: DemoStore
    @EnvironmentObject private var account: AccountStore
    @EnvironmentObject private var local: LocalStore
    @EnvironmentObject private var phone: PhoneAuth
    @EnvironmentObject private var plugins: PluginStore

    @State private var showWeb = false
    @State private var showAccount = false
    @State private var showConnect = false
    @State private var showCredits = false
    @State private var showPhone = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    accountCard
                    phoneCard
                    hostCard
                    dataCard
                    localCard
                    pluginsCard
                    fileCard
                    webCard
                    aboutCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ink.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showAccount) {
            AccountView()
                .environmentObject(account)
        }
        .sheet(isPresented: $showConnect) {
            ConnectView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
        .sheet(isPresented: $showPhone) {
            PhoneLoginView()
                .environmentObject(phone)
        }
        .sheet(isPresented: $showWeb) {
            if let host = store.current {
                WebScreen(host: host)
                    .preferredColorScheme(.dark)
            }
        }
    }

    private var hostCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                if store.current != nil {
                    StatusDot()
                    Text("已连接")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                } else {
                    Circle().fill(Color.white.opacity(0.3)).frame(width: 7, height: 7)
                    Text("未连接")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Text(store.current?.displayName ?? "—")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }

            if let host = store.current {
                Text(host.originText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.dim)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Button("重新配对") {
                        Haptics.soft()
                        store.disconnect()
                    }
                    .buttonStyle(NcnsGlassButtonStyle(compact: true))

                    Button("在 Safari 打开") {
                        if let url = URL(string: host.originText) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(NcnsGlassButtonStyle(compact: true))
                }
            } else {
                Button("连接电脑") {
                    Haptics.tap()
                    showConnect = true
                }
                .buttonStyle(NcnsGlassButtonStyle(compact: true))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("数据源", systemImage: "cylinder.split.1x2")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text("演示数据")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.mint)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Theme.mint.opacity(0.14), in: Capsule())
            }

            Text("界面和交互已经按最终形态跑通，数据还是本地的 demo。接上 `dsh-plugin-mobile-gateway` 的 WebSocket 之后，这里会显示连接状态与事件吞吐。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }

    private var accountCard: some View {
        Button {
            Haptics.tap()
            showAccount = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: account.isSignedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(account.isSignedIn ? Theme.mint : Theme.accent)
                    .frame(width: 38, height: 38)
                    .background((account.isSignedIn ? Theme.mint : Theme.accent).opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("DeepSeek 账号")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(account.isSignedIn ? "已登录 · \(account.selectedModel)" : "未登录 · 登录后可以用本机模式")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .ncnsGlass(cornerRadius: 22)
    }

    private var localCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.mint)
                    .frame(width: 34, height: 34)
                    .background(Theme.mint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("本机工作区")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text("Documents/NcnsDSH/workspace")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }

                Spacer(minLength: 8)

                Text("\(local.recent.count) 个会话")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.dim)
            }

            Text("本机会话能读写这个目录。它不在 iCloud 里，也不会同步给宿主。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }

    private var phoneCard: some View {
        Button {
            Haptics.tap()
            showPhone = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: phone.signedIn ? "iphone.gen3.badge.checkmark" : "iphone")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(phone.signedIn ? DSH.Palette.success : DSH.Palette.accent)
                    .frame(width: 38, height: 38)
                    .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("手机号")
                        .font(DSH.TypeScale.headline)
                        .foregroundStyle(DSH.Palette.text)
                    Text(phone.signedIn ? phone.masked : "未登录 · 用于同步与提醒")
                        .font(DSH.TypeScale.footnote)
                        .foregroundStyle(DSH.Palette.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DSH.Palette.tertiary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .ncnsGlass(cornerRadius: 16)
    }

    private var pluginsCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DSH.Palette.accent)
                .frame(width: 34, height: 34)
                .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("插件")
                    .font(DSH.TypeScale.headline)
                    .foregroundStyle(DSH.Palette.text)
                Text("已安装 \(plugins.installed.count) 个 · 商店里还有 \(plugins.store.count) 个")
                    .font(DSH.TypeScale.footnote)
                    .foregroundStyle(DSH.Palette.secondary)
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 16)
    }

    private var fileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "folder")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("文件")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text(AppFiles.displayPath)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }

                Spacer()
            }

            Text("本机会话读写的 workspace、构建下载的 IPA 都在这里。在「文件」App 的「我的 iPhone → NcnsDSH」里能直接看到、拷出来。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button("在「文件」中打开") {
                    Haptics.tap()
                    AppFiles.reveal()
                }
                .buttonStyle(NcnsGlassButtonStyle(compact: true))

                Button("复制路径") {
                    AppFiles.copyPath()
                    Haptics.success()
                }
                .buttonStyle(NcnsGlassButtonStyle(compact: true))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }

    private var webCard: some View {
        Button {
            Haptics.tap()
            showWeb = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("网页版")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Text("插件页、终端、文件预览这些还没原生的功能")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .ncnsGlass(cornerRadius: 22)
        .disabled(store.current == nil)
        .opacity(store.current == nil ? 0.5 : 1)
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                BrandMark(size: 44)
                BrandWordmark()
                Spacer()
                Text(Bundle.main.appVersion)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.dim)
            }

            Text("视觉参照 tv 与 Apple Music；玻璃只出现在 chrome 和可交互卡片上，内容区保持不透明，保证对比度。")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                BrandBadge()
                Spacer()
                Button {
                    Haptics.tap()
                    showCredits = true
                } label: {
                    HStack(spacing: 4) {
                        Text("关于与制作人员")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }
}

extension Bundle {
    var appVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(short) (\(build))"
    }
}
