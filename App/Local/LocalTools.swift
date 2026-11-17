import Foundation

/// 本机模式能动的只有这个沙盒工作区：`Documents/NcnsDSH/workspace`。
enum LocalTools {
    static var workspace: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let url = base.appendingPathComponent("NcnsDSH/workspace", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static let names = ["list_files", "read_file", "write_file"]

    static var definitions: [[String: Any]] {
        [
            [
                "type": "function",
                "function": [
                    "name": "list_files",
                    "description": "列出本机工作区里的文件和目录。",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "path": ["type": "string", "description": "相对工作区的目录，默认根目录。"]
                        ]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "read_file",
                    "description": "读一个文本文件，最多 20 KB。",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "path": ["type": "string", "description": "相对工作区的文件路径。"]
                        ],
                        "required": ["path"]
                    ]
                ]
            ],
            [
                "type": "function",
                "function": [
                    "name": "write_file",
                    "description": "写一个文本文件（覆盖）。父目录会自动创建。",
                    "parameters": [
                        "type": "object",
                        "properties": [
                            "path": ["type": "string", "description": "相对工作区的文件路径。"],
                            "content": ["type": "string", "description": "完整的文件内容。"]
                        ],
                        "required": ["path", "content"]
                    ]
                ]
            ],
        ]
    }

    static func run(name: String, arguments: String) -> String {
        let args = (try? JSONSerialization.jsonObject(with: Data(arguments.utf8))) as? [String: Any] ?? [:]

        do {
            switch name {
            case "list_files":
                let relative = args["path"] as? String ?? ""
                let dir = try resolve(relative)
                let items = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey])
                    .sorted { $0.lastPathComponent < $1.lastPathComponent }
                if items.isEmpty { return "（空目录）" }
                return items.map { url in
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    return isDir ? "\(url.lastPathComponent)/" : url.lastPathComponent
                }.joined(separator: "\n")

            case "read_file":
                guard let relative = args["path"] as? String else { return "错误：缺少 path" }
                let url = try resolve(relative)
                let data = try Data(contentsOf: url)
                let slice = data.prefix(20 * 1024)
                return String(decoding: slice, as: UTF8.self)

            case "write_file":
                guard let relative = args["path"] as? String, let content = args["content"] as? String else {
                    return "错误：缺少 path 或 content"
                }
                let url = try resolve(relative)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data(content.utf8).write(to: url, options: .atomic)
                return "已写入 \(url.lastPathComponent)（\(content.utf8.count) 字节）"

            default:
                return "错误：没有这个工具 \(name)"
            }
        } catch {
            return "错误：\(error.localizedDescription)"
        }
    }

    /// 只允许工作区内部的相对路径。
    private static func resolve(_ relative: String) throws -> URL {
        let base = workspace.standardizedFileURL
        let candidate = base.appendingPathComponent(relative).standardizedFileURL
        guard candidate.path == base.path || candidate.path.hasPrefix(base.path + "/") else {
            throw NSError(domain: "NcnsDSH", code: 1, userInfo: [NSLocalizedDescriptionKey: "路径不在工作区里"])
        }
        return candidate
    }
}
