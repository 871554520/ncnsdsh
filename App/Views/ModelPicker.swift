import SwiftUI

/// 模型选择：底部拖拽面板，像 Codex 的模型下拉。
struct ModelPicker: View {
    @Binding var selection: String
    var models: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("选择模型")
                .font(DSH.TypeScale.headline)
                .foregroundStyle(DSH.Palette.text)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 10)

            ForEach(models, id: \.self) { model in
                Button {
                    selection = model
                    Haptics.tap()
                    dismiss()
                } label: {
                    HStack {
                        Text(model)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(DSH.Palette.text)
                        Spacer()
                        if model == selection {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(DSH.Palette.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if model != models.last {
                    Divider()
                        .overlay(DSH.Palette.hairline)
                        .padding(.leading, 20)
                }
            }

            Spacer(minLength: 0)
        }
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
    }
}

/// Codex 那种空状态：标识 + 一句话 + 模型下拉。
struct CodexIntro: View {
    var model: String
    var onPickModel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            BrandMark(size: 52)
                .padding(.bottom, 6)

            Text("开始吧")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(DSH.Palette.text)

            Button(action: onPickModel) {
                HStack(spacing: 6) {
                    Text(model)
                        .font(.system(.title3, design: .default))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(DSH.Palette.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DSH.Palette.surface, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 90)
    }
}
