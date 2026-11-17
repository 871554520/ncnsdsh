import SwiftUI

struct PluginsView: View {
    @EnvironmentObject private var store: PluginStore

    enum Segment: String, CaseIterable {
        case installed = "已安装"
        case market = "商店"
    }

    @State private var segment: Segment = .installed
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundStyle(DSH.Palette.tertiary)
                        TextField("搜索插件、厂商或分类", text: $query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(DSH.TypeScale.callout)
                            .foregroundStyle(DSH.Palette.text)
                        if !query.isEmpty {
                            Button {
                                query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DSH.Palette.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(DSH.Palette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Picker("", selection: $segment) {
                        ForEach(Segment.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    if segment == .installed {
                        list(filter(store.installed), empty: query.isEmpty ? "还没有装插件。去商店看看。" : "没有匹配的已安装插件。")
                    } else {
                        list(filter(store.store), empty: query.isEmpty ? "商店里的都装上了。" : "没有匹配的插件。")
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

    private func filter(_ plugins: [DSHPlugin]) -> [DSHPlugin] {
        let key = query.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return plugins }
        return plugins.filter {
            $0.name.localizedCaseInsensitiveContains(key)
                || $0.summary.localizedCaseInsensitiveContains(key)
                || $0.vendor.localizedCaseInsensitiveContains(key)
                || $0.category.contains(key)
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
