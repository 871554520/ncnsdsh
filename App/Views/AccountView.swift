import SwiftUI
import UIKit

struct AccountView: View {
    @EnvironmentObject private var account: AccountStore
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""
    @State private var reveal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if account.isSignedIn {
                        signedIn
                    } else {
                        signedOut
                    }

                    Text("Key 只存在这台手机的钥匙串里，不会上传到除 DeepSeek 以外的地方。想换 Key 就先退出登录。")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ink.ignoresSafeArea())
            .navigationTitle("DeepSeek 账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Signed in

    private var signedIn: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.mint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("已登录")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(masked)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("默认模型")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .textCase(.uppercase)
                Picker("模型", selection: $account.selectedModel) {
                    ForEach(account.models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack(spacing: 10) {
                Button("重新验证") {
                    Task { await account.refreshModels() }
                }
                .buttonStyle(NcnsGlassButtonStyle(compact: true))

                Button("退出登录") {
                    account.signOut()
                    Haptics.soft()
                }
                .buttonStyle(NcnsGlassButtonStyle(compact: true))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }

    // MARK: - Signed out

    private var signedOut: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("用 DeepSeek API Key 登录")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("在 platform.deepseek.com 建一个 Key，粘贴进来。登录后就能在「本机」里直接对话，不需要电脑。")
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Group {
                    if reveal {
                        TextField("sk-…", text: $input)
                    } else {
                        SecureField("sk-…", text: $input)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, design: .monospaced))
                .foregroundStyle(.white)

                Button {
                    reveal.toggle()
                } label: {
                    Image(systemName: reveal ? "eye.slash" : "eye")
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .ncnsGlass(cornerRadius: 16, interactive: true)

            Button {
                Task { await account.signIn(input) }
            } label: {
                HStack(spacing: 8) {
                    if case .checking = account.state {
                        ProgressView().tint(.white)
                    }
                    Text("登录")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.ncnsProminent)
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)

            if case .failed(let message) = account.state {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xFFB86B))
            }

            Link("去建一个 Key", destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .ncnsGlass(cornerRadius: 22)
    }

    private var masked: String {
        let key = account.key
        guard key.count > 10 else { return "sk-…" }
        return "\(key.prefix(6))…\(key.suffix(4))"
    }
}
