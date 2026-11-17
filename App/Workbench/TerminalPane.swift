import SwiftUI

/// 本机终端：只操作 App 工作区，命令有限但都是真的。
struct TerminalPane: View {
    @State private var lines: [String] = ["NcnsDSH 终端 · 输入 help 看命令"]
    @State private var input = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(line.hasPrefix("$") ? DSH.Palette.accent : DSH.Palette.text.opacity(0.86))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Color.clear.frame(height: 1).id("end")
                    }
                    .padding(14)
                }
                .onChange(of: lines.count) { _, _ in
                    proxy.scrollTo("end", anchor: .bottom)
                }
            }

            HStack(spacing: 6) {
                Text("$")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(DSH.Palette.accent)
                TextField("输入命令", text: $input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(DSH.Palette.text)
                    .focused($focused)
                    .onSubmit(run)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DSH.Palette.surface)
        }
        .onAppear { focused = true }
    }

    private func run() {
        let command = input.trimmingCharacters(in: .whitespaces)
        guard !command.isEmpty else { return }
        input = ""
        lines.append("$ " + command)
        lines.append(contentsOf: Shell.run(command))
    }
}

/// 极小的 shell：没有子进程，只有文件系统调用。
enum Shell {
    static func run(_ line: String) -> [String] {
        let parts = line.split(separator: " ").map(String.init)
        guard let head = parts.first else { return [] }
        let args = Array(parts.dropFirst())

        switch head {
        case "help":
            return [
                "可用命令：",
                "  pwd              当前目录",
                "  ls [目录]        列出文件",
                "  cat <文件>       查看文本",
                "  mkdir <目录>     新建目录",
                "  rm <文件>        删除文件",
                "  echo <文本>      原样输出",
                "  clear            清屏",
            ]

        case "pwd":
            return [AppFiles.workspace.path]

        case "clear":
            return ["__CLEAR__"]

        case "echo":
            return [args.joined(separator: " ")]

        case "ls":
            let target = resolve(args.first ?? "")
            guard let target else { return ["ls: 路径不在工作区里"] }
            guard let items = try? FileManager.default.contentsOfDirectory(at: target, includingPropertiesForKeys: [.isDirectoryKey]) else {
                return ["ls: 打不开 \(args.first ?? "/")"]
            }
            if items.isEmpty { return ["（空）"] }
            return items
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
                .map { url in
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    return isDir ? url.lastPathComponent + "/" : url.lastPathComponent
                }

        case "cat":
            guard let name = args.first, let url = resolve(name) else { return ["cat: 需要一个文件"] }
            guard let data = try? Data(contentsOf: url) else { return ["cat: 读不到 \(name)"] }
            let text = String(decoding: data.prefix(4000), as: UTF8.self)
            return text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        case "mkdir":
            guard let name = args.first, let url = resolve(name) else { return ["mkdir: 需要一个目录名"] }
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return ["已创建 \(name)"]

        case "rm":
            guard let name = args.first, let url = resolve(name) else { return ["rm: 需要一个文件名"] }
            try? FileManager.default.removeItem(at: url)
            return ["已删除 \(name)"]

        default:
            return ["未知命令：\(head)。输入 help。"]
        }
    }

    private static func resolve(_ relative: String) -> URL? {
        let base = AppFiles.workspace.standardizedFileURL
        let target = (relative.isEmpty ? base : base.appendingPathComponent(relative)).standardizedFileURL
        guard target.path == base.path || target.path.hasPrefix(base.path + "/") else { return nil }
        return target
    }
}
