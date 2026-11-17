import AppIntents
import Foundation

/// 从 Siri / 快捷指令 / 聚焦打开 App 时要做什么。
enum NcnsIntentTarget: Equatable {
    case new(draft: String?)
    case recent
    case session(UUID)

    /// `ncnsdsh://new?draft=…`、`ncnsdsh://session/<uuid>`。
    static func from(_ url: URL) -> NcnsIntentTarget? {
        guard let scheme = url.scheme, scheme == "ncnsdsh" || scheme == "dsh" else { return nil }
        switch url.host {
        case "new":
            let draft = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first { $0.name == "draft" }?
                .value
            return .new(draft: draft)
        case "session":
            guard let first = url.pathComponents.dropFirst().first,
                  let id = UUID(uuidString: first)
            else { return nil }
            return .session(id)
        case "recent":
            return .recent
        default:
            return nil
        }
    }
}

/// App 启动后由 `RootView` 接上；intent 只负责把意图交出去。
@MainActor
enum NcnsIntentBridge {
    static var open: ((NcnsIntentTarget) -> Void)?
}

struct NewSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "新建会话"
    static var description = IntentDescription("打开 NcnsDSH，开一个新会话。")
    static var openAppWhenRun = true

    @Parameter(title: "草稿", description: "放进输入框，不会自动发送。")
    var draft: String?

    init() {}

    init(draft: String?) {
        self.draft = draft
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let text = draft?.trimmingCharacters(in: .whitespacesAndNewlines)
        NcnsIntentBridge.open?(.new(draft: (text?.isEmpty ?? true) ? nil : text))
        return .result()
    }
}

struct ContinueSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "继续最近的会话"
    static var description = IntentDescription("打开 NcnsDSH，回到最近在跑的那个会话。")
    static var openAppWhenRun = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        NcnsIntentBridge.open?(.recent)
        return .result()
    }
}

struct NcnsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NewSessionIntent(),
            phrases: [
                "用 \(.applicationName) 新建会话",
                "\(.applicationName) 新会话",
            ],
            shortTitle: "新建会话",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: ContinueSessionIntent(),
            phrases: [
                "用 \(.applicationName) 继续最近的会话",
                "\(.applicationName) 回到会话",
            ],
            shortTitle: "继续会话",
            systemImageName: "arrow.clockwise"
        )
    }
}
