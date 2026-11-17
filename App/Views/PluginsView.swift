import SwiftUI

struct PluginsView: View {
    @EnvironmentObject private var store: PluginStore

    enum Segment: String, CaseIterable {
        case installed = "已安装"
        case market = "商店"
    }

    @State private var segment: Segment = .installed

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("", selection: $segment) {
                        ForEach(Segment.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    if segment == .installed {
                        list(store.installed, empty: "还没有装插件。去商店看看。")
                    } else {
                        list(store.store, empty: "商店里的都装上了。")
                    }
                }
                .padding(.horizontal, DSH.Inset.gutter)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(DSH.Palette.canvas)
            .navigationTitle("插件")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func list(_ plugins: [DSHPlugin], empty: String) -> some View {
        if plugins.isEmpty {
            Text(empty)
                .font(DSH.TypeScale.callout)
                .foregroundStyle(DSH.Palette.secondary)
                .padding(.vertical, 24)
        } else {
            VStack(spacing: 10) {
                ForEach(plugins) { plugin in
                    row(plugin)
                }
            }
        }
    }

    private func row(_ plugin: DSHPlugin) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: plugin.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(plugin.installed ? DSH.Palette.accent : DSH.Palette.secondary)
                .frame(width: 40, height: 40)
                .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(plugin.name)
                        .font(DSH.TypeScale.headline)
                        .foregroundStyle(DSH.Palette.text)
                    if plugin.official {
                        Text("官方")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DSH.Palette.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(DSH.Palette.accent.opacity(0.14), in: Capsule())
                    }
                }

                Text("\(plugin.vendor) · \(plugin.version)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(DSH.Palette.tertiary)

                Text(plugin.summary)
                    .font(DSH.TypeScale.footnote)
                    .foregroundStyle(DSH.Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 1)

                if !plugin.permissions.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(plugin.permissions, id: \.self) { permission in
                            Text(permission)
                                .font(.system(size: 9))
                                .foregroundStyle(DSH.Palette.tertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DSH.Palette.surface, in: Capsule())
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 8)

            Button {
                store.toggle(plugin)
            } label: {
                Text(plugin.installed ? "移除" : "安装")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(plugin.installed ? DSH.Palette.secondary : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(plugin.installed ? DSH.Palette.surface : DSH.Palette.accent)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: DSH.Radius.card, style: .continuous))
    }
}
