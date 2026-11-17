import Foundation

/// 把 GitHub Actions 的出包流程搬进 App：填仓库 → 触发 workflow → 看步骤 → 下载 IPA。
@MainActor
final class BuildStore: ObservableObject {
    @Published var owner: String
    @Published var repo: String
    @Published var workflow: String
    @Published var ref: String

    @Published private(set) var phase: BuildPhase = .idle
    @Published private(set) var steps: [BuildStep] = []
    @Published private(set) var login: String?
    @Published private(set) var runNumber: Int?
    @Published private(set) var runURL: URL?
    @Published private(set) var artifact: BuildArtifact?
    @Published private(set) var startedAt: Date?
    @Published private(set) var runID: Int?
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var token: String = ""
    @Published var message: String?

    private var job: Task<Void, Never>?
    private var ticker: Task<Void, Never>?
    private let tokenAccount = "github.token"
    private let configKey = "build.config.v1"

    init() {
        let saved = UserDefaults.standard.dictionary(forKey: configKey) as? [String: String]
        owner = saved?["owner"] ?? "NevercRyNow"
        repo = saved?["repo"] ?? "ncnsdsh"
        workflow = saved?["workflow"] ?? "ios26.yml"
        ref = saved?["ref"] ?? "main"
        token = Keychain.get(tokenAccount) ?? ""
        if !token.isEmpty {
            Task { await refreshLogin() }
        }
    }

    var hasToken: Bool { !token.isEmpty }
    var canStart: Bool { hasToken && !phase.isBusy }

    var repoSlug: String { "\(owner)/\(repo)" }

    // MARK: - Account

    func saveToken(_ raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            message = "Token 不能为空"
            return
        }
        token = trimmed
        Keychain.set(trimmed, for: tokenAccount)
        await refreshLogin()
    }

    func refreshLogin() async {
        guard hasToken else {
            login = nil
            return
        }
        do {
            login = try await GitHubAPI(token: token).login()
            message = nil
        } catch {
            login = nil
            message = error.localizedDescription
        }
    }

    func signOut() {
        Keychain.delete(tokenAccount)
        token = ""
        login = nil
    }

    // MARK: - Build

    func start() {
        guard canStart else {
            message = hasToken ? "正在跑，等一下" : "先填一个 GitHub Token"
            return
        }
        persistConfig()
        message = nil
        steps = []
        artifact = nil
        runURL = nil
        runNumber = nil
        startedAt = Date()
        elapsed = 0
        phase = .dispatching

        job?.cancel()
        job = Task { [weak self] in
            await self?.drive()
        }
        startTicker()
    }

    func cancel() {
        job?.cancel()
        job = nil
        ticker?.cancel()
        ticker = nil
        if phase.isBusy { phase = .idle }
    }

    private func drive() async {
        let api = GitHubAPI(token: token)
        do {
            let dispatchedAt = Date()
            try await api.dispatch(owner: owner, repo: repo, workflow: workflow, ref: ref)

            var found: GHRun?
            for _ in 0..<12 {
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: 3_000_000_000)
                let list = try await api.runs(owner: owner, repo: repo, workflow: workflow)
                if let newest = list.first,
                   let date = Self.parse(newest.created_at),
                   date >= dispatchedAt.addingTimeInterval(-45) {
                    found = newest
                    break
                }
            }

            guard var run = found else {
                throw GitHubError(message: "没有找到刚触发的构建。仓库里有没有这个 workflow？分支对不对？")
            }

            runNumber = run.run_number
            runID = run.id
            runURL = URL(string: run.html_url)
            phase = .running

            while true {
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: 4_000_000_000)
                run = try await api.run(owner: owner, repo: repo, id: run.id)
                if let jobs = try? await api.jobs(owner: owner, repo: repo, runID: run.id),
                   let first = jobs.first,
                   let rawSteps = first.steps {
                    steps = rawSteps.map {
                        BuildStep(id: $0.number, name: $0.name, status: $0.status, conclusion: $0.conclusion)
                    }
                }
                if run.status == "completed" {
                    if run.conclusion == "success" {
                        phase = .succeeded
                    } else {
                        phase = .failed(Self.describe(run.conclusion))
                    }
                    ticker?.cancel()
                    ticker = nil
                    return
                }
            }
        } catch is CancellationError {
            phase = .idle
        } catch {
            phase = .failed(error.localizedDescription)
            message = error.localizedDescription
            ticker?.cancel()
            ticker = nil
        }
    }

    // MARK: - Download

    func download() async {
        guard phase == .succeeded || phase == .ready else { return }
        phase = .downloading
        message = nil
        let api = GitHubAPI(token: token)
        do {
            var asset: GHAsset?
            for _ in 0..<6 {
                if let id = runID,
                   let release = try? await api.release(owner: owner, repo: repo, tag: "build-\(id)"),
                   let hit = release.assets.first(where: { $0.name.hasSuffix(".ipa") }) {
                    asset = hit
                    break
                }
                let releases = try await api.releases(owner: owner, repo: repo)
                if let hit = releases.compactMap({ release in
                    release.assets.first { $0.name.hasSuffix(".ipa") }
                }).first {
                    asset = hit
                    break
                }
                try await Task.sleep(nanoseconds: 3_000_000_000)
            }
            guard let asset, let url = URL(string: asset.browser_download_url) else {
                throw GitHubError(message: "这次构建没有挂上 IPA。workflow 里有没有 release 那一步？")
            }

            let (temp, response) = try await URLSession.shared.download(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw GitHubError(message: "下载被拒绝，仓库是不是私有的？")
            }

            let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("NcnsDSH/builds", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = folder.appendingPathComponent(asset.name)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: temp, to: destination)

            artifact = BuildArtifact(name: asset.name, url: destination, size: asset.size)
            phase = .ready
        } catch {
            phase = .succeeded
            message = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self, let start = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(start)
            }
        }
    }

    private func persistConfig() {
        UserDefaults.standard.set(
            ["owner": owner, "repo": repo, "workflow": workflow, "ref": ref],
            forKey: configKey
        )
    }

    private static func parse(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: text)
    }

    private static func describe(_ conclusion: String?) -> String {
        switch conclusion {
        case "failure": return "构建失败"
        case "cancelled": return "被取消"
        case "timed_out": return "超时"
        default: return conclusion ?? "失败"
        }
    }
}
