import Foundation

/// 插件条目：本地目录 + 商店目录共用一套结构。
struct DSHPlugin: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var vendor: String
    var summary: String
    var version: String
    var symbol: String
    var category: String
    var installed: Bool
    var official: Bool
    var permissions: [String]
}

extension DSHPlugin {
    static let catalog: [DSHPlugin] = [
        DSHPlugin(
            id: "dsh-mobile-gateway",
            name: "Mobile Gateway",
            vendor: "Clarklevis1995",
            summary: "把宿主会话通过 WebSocket 暴露给手机，支持配对码与可信设备。",
            version: "0.12.1",
            symbol: "antenna.radiowaves.left.and.right",
            category: "连接",
            installed: true,
            official: false,
            permissions: ["网络", "会话"]
        ),
        DSHPlugin(
            id: "dsh-drawai",
            name: "DrawAI",
            vendor: "DeepSeek",
            summary: "在会话里直接读写 .drawio 画布、导出 PNG/SVG、做分镜板。",
            version: "0.9.3",
            symbol: "pencil.and.ruler",
            category: "创作",
            installed: true,
            official: true,
            permissions: ["文件", "画布"]
        ),
        DSHPlugin(
            id: "dsh-web-search",
            name: "Web Search",
            vendor: "DeepSeek",
            summary: "给智能体一个联网搜索工具，带来源引用。",
            version: "1.4.0",
            symbol: "magnifyingglass",
            category: "工具",
            installed: true,
            official: true,
            permissions: ["网络"]
        ),
        DSHPlugin(
            id: "dsh-schedule",
            name: "Schedule",
            vendor: "DeepSeek",
            summary: "定时触发会话：每天汇总、每周清理，都能挂在本机跑。",
            version: "0.6.2",
            symbol: "clock.arrow.circlepath",
            category: "自动化",
            installed: false,
            official: true,
            permissions: ["后台", "会话"]
        ),
        DSHPlugin(
            id: "dsh-git",
            name: "Git",
            vendor: "community",
            summary: "提交、分支、diff 预览；危险命令会先问一次。",
            version: "0.4.5",
            symbol: "arrow.triangle.branch",
            category: "开发",
            installed: false,
            official: false,
            permissions: ["文件", "子进程"]
        ),
        DSHPlugin(
            id: "dsh-office",
            name: "Office",
            vendor: "DeepSeek",
            summary: "读写 docx / xlsx / pptx，导出 PDF。",
            version: "1.1.0",
            symbol: "doc.richtext",
            category: "文档",
            installed: false,
            official: true,
            permissions: ["文件"]
        ),
        DSHPlugin(
            id: "dsh-voice",
            name: "Voice",
            vendor: "community",
            summary: "语音输入与朗读，支持中文音色。",
            version: "0.3.0",
            symbol: "waveform",
            category: "输入",
            installed: false,
            official: false,
            permissions: ["麦克风"]
        ),
        DSHPlugin(
            id: "dsh-remote",
            name: "Remote Access",
            vendor: "liguobao",
            summary: "P2P 端到端加密通道，出门也能连回家里的 DSH。",
            version: "0.6.5",
            symbol: "network",
            category: "连接",
            installed: false,
            official: false,
            permissions: ["网络", "后台"]
        ),
    ]
}
