import Foundation
import SwiftUI

/// 插件目录：已安装 / 商店，装了什么存在 UserDefaults。
@MainActor
final class PluginStore: ObservableObject {
    @Published private(set) var plugins: [DSHPlugin] = []

    private let key = "plugins.installed.v1"

    init() {
        load()
    }

    var installed: [DSHPlugin] {
        plugins.filter(\.installed)
    }

    var store: [DSHPlugin] {
        plugins.filter { !$0.installed }
    }

    func toggle(_ plugin: DSHPlugin) {
        guard let index = plugins.firstIndex(where: { $0.id == plugin.id }) else { return }
        plugins[index].installed.toggle()
        Haptics.soft()
        save()
    }

    private func load() {
        let saved = UserDefaults.standard.stringArray(forKey: key)
        if let saved {
            plugins = DSHPlugin.catalog.map { plugin in
                var copy = plugin
                copy.installed = saved.contains(plugin.id)
                return copy
            }
        } else {
            plugins = DSHPlugin.catalog
        }
    }

    private func save() {
        UserDefaults.standard.set(plugins.filter(\.installed).map(\.id), forKey: key)
    }
}

/// 手机号登录（演示态：验证码由 App 自己发，任意 6 位数字都通过）。
@MainActor
final class PhoneAuth: ObservableObject {
    enum Step: Equatable {
        case phone
        case code
    }

    @Published var phone = ""
    @Published private(set) var step: Step = .phone
    @Published private(set) var signedIn = false
    @Published private(set) var sending = false
    @Published private(set) var masked = ""
    @Published var error: String?

    private let phoneKey = "auth.phone.v1"
    private let signedKey = "auth.signed.v1"

    init() {
        if let saved = UserDefaults.standard.string(forKey: phoneKey), !saved.isEmpty {
            phone = saved
            masked = Self.mask(saved)
            signedIn = UserDefaults.standard.bool(forKey: signedKey)
        }
    }

    var canSend: Bool {
        phone.filter(\.isNumber).count == 11 && !sending
    }

    func sendCode() async {
        guard canSend else { return }
        sending = true
        error = nil
        try? await Task.sleep(nanoseconds: 900_000_000)
        sending = false
        masked = Self.mask(phone)
        step = .code
        Haptics.success()
    }

    func verify(_ code: String) {
        let digits = code.filter(\.isNumber)
        guard digits.count == 6 else {
            error = "验证码是 6 位数字"
            Haptics.failure()
            return
        }
        signedIn = true
        error = nil
        UserDefaults.standard.set(phone, forKey: phoneKey)
        UserDefaults.standard.set(true, forKey: signedKey)
        Haptics.success()
    }

    func signOut() {
        signedIn = false
        step = .phone
        UserDefaults.standard.set(false, forKey: signedKey)
    }

    func back() {
        step = .phone
        error = nil
    }

    private static func mask(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count == 11 else { return digits }
        let start = digits.prefix(3)
        let end = digits.suffix(4)
        return "\(start) **** \(end)"
    }
}
