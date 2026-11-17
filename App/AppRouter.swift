import SwiftUI

/// 全局导航状态：Tab、会话栈、以及深链/Intent 想打开的东西。
@MainActor
final class AppRouter: ObservableObject {
    @Published var tab: MainShell.Tab = .home
    @Published var path: [UUID] = []

    func handle(_ target: NcnsIntentTarget, demo: DemoStore) {
        switch target {
        case .new(let draft):
            tab = .home
            demo.newSession(draft: draft)
            if let id = demo.activeSessionID {
                path = [id]
            }
        case .recent:
            tab = .home
            if let id = demo.heroSession?.id {
                path = [id]
            }
        case .session(let id):
            tab = .home
            path = [id]
        }
    }
}
