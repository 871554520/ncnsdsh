import SwiftUI

/// 首页导航目标：远端（宿主）会话与本机会话分开。
enum HomeRoute: Hashable {
    case remote(UUID)
    case local(UUID)
}

/// 全局导航状态：Tab、会话栈、以及深链/Intent 想打开的东西。
@MainActor
final class AppRouter: ObservableObject {
    @Published var tab: MainShell.Tab = .home
    @Published var path: [HomeRoute] = []

    func handle(_ target: NcnsIntentTarget, demo: DemoStore) {
        switch target {
        case .new(let draft):
            tab = .home
            demo.newSession(draft: draft)
            if let id = demo.activeSessionID {
                path = [.remote(id)]
            }
        case .recent:
            tab = .home
            if let id = demo.heroSession?.id {
                path = [.remote(id)]
            }
        case .session(let id):
            tab = .home
            path = [.remote(id)]
        }
    }
}
