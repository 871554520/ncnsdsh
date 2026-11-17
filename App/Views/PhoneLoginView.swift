import SwiftUI

struct PhoneLoginView: View {
    @EnvironmentObject private var auth: PhoneAuth
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @FocusState private var focus: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if auth.signedIn {
                        signedIn
                    } else if auth.step == .phone {
                        phoneStep
                    } else {
                        codeStep
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(DSH.Palette.canvas)
            .navigationTitle("手机号登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Steps

    private var phoneStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("用手机号登录")
                .font(DSH.TypeScale.title)
                .foregroundStyle(DSH.Palette.text)

            Text("验证码会以演示形式在本地生成；接上后端之后换成真实短信。")
                .font(DSH.TypeScale.footnote)
                .foregroundStyle(DSH.Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Text("+86")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DSH.Palette.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                TextField("11 位手机号", text: $auth.phone)
                    .keyboardType(.numberPad)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(DSH.Palette.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if let error = auth.error {
                Text(error)
                    .font(DSH.TypeScale.footnote)
                    .foregroundStyle(DSH.Palette.danger)
            }

            Button {
                Task { await auth.sendCode() }
            } label: {
                HStack(spacing: 8) {
                    if auth.sending {
                        ProgressView().tint(.white)
                    }
                    Text(auth.sending ? "发送中…" : "发送验证码")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: DSH.Radius.card, style: .continuous)
                        .fill(auth.canSend ? DSH.Palette.accent : DSH.Palette.surface)
                )
                .foregroundStyle(auth.canSend ? .white : DSH.Palette.tertiary)
            }
            .buttonStyle(.plain)
            .disabled(!auth.canSend)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var codeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("验证码已发送")
                .font(DSH.TypeScale.title)
                .foregroundStyle(DSH.Palette.text)

            Text("发送到 \(auth.masked)。演示环境：任意 6 位数字都通过。")
                .font(DSH.TypeScale.footnote)
                .foregroundStyle(DSH.Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField("6 位验证码", text: $code)
                .keyboardType(.numberPad)
                .font(.system(.title2, design: .monospaced).weight(.semibold))
                .foregroundStyle(DSH.Palette.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($focus)

            if let error = auth.error {
                Text(error)
                    .font(DSH.TypeScale.footnote)
                    .foregroundStyle(DSH.Palette.danger)
            }

            Button {
                auth.verify(code)
            } label: {
                Text("登录")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DSH.Palette.accent, in: RoundedRectangle(cornerRadius: DSH.Radius.card, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button("换个号码") {
                auth.back()
                code = ""
            }
            .font(DSH.TypeScale.footnote)
            .foregroundStyle(DSH.Palette.accent)
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { focus = true }
    }

    private var signedIn: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(DSH.Palette.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text("已登录")
                        .font(DSH.TypeScale.headline)
                        .foregroundStyle(DSH.Palette.text)
                    Text(auth.masked)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(DSH.Palette.secondary)
                }
                Spacer()
            }

            Button("退出登录") {
                auth.signOut()
                dismiss()
            }
            .buttonStyle(NcnsGlassButtonStyle(compact: true))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
