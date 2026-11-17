import SwiftUI

/// 界面层状态：现在有没有会话页盖在最上面。mini bar 靠它避让，避免压住输入栏。
@MainActor
final class AppChrome: ObservableObject {
    @Published var chatOpen = false
}
