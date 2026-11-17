import Foundation

/// 本机会话：不连宿主，模型直连 DeepSeek，工具只动 App 沙盒里的工作区。
struct LocalMessage: Codable, Identifiable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
        case tool
        case system
    }

    var id: UUID = UUID()
    var role: Role
    var text: String = ""
    var toolCalls: [LocalToolCall] = []
    var toolCallID: String?
    var toolName: String?
    var createdAt: Date = Date()
}

struct LocalToolCall: Codable, Hashable {
    var id: String
    var name: String
    var arguments: String
}

struct LocalSession: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var messages: [LocalMessage] = []
    var model: String

    var initial: String { String(title.prefix(1)) }

    var preview: String {
        guard let last = messages.last(where: { $0.role == .assistant && !$0.text.isEmpty }) else {
            return "还没有回复"
        }
        let flat = last.text.replacingOccurrences(of: "\n", with: " ")
        return String(flat.prefix(80))
    }
}
