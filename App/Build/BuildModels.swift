import Foundation

struct BuildStep: Identifiable, Equatable {
    let id: Int
    var name: String
    var status: String
    var conclusion: String?

    var isDone: Bool { status == "completed" }
    var failed: Bool { conclusion == "failure" || conclusion == "cancelled" }
}

struct BuildArtifact: Equatable {
    var name: String
    var url: URL
    var size: Int
}

enum BuildPhase: Equatable {
    case idle
    case dispatching
    case running
    case succeeded
    case failed(String)
    case downloading
    case ready

    var isBusy: Bool {
        switch self {
        case .dispatching, .running, .downloading: return true
        default: return false
        }
    }
}

struct GitHubError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Wire models

struct GHUser: Decodable {
    let login: String
}

struct GHRun: Decodable {
    let id: Int
    let status: String
    let conclusion: String?
    let run_number: Int
    let html_url: String
    let created_at: String
}

struct GHRuns: Decodable {
    let workflow_runs: [GHRun]
}

struct GHStep: Decodable {
    let number: Int
    let name: String
    let status: String
    let conclusion: String?
}

struct GHJob: Decodable {
    let name: String
    let status: String
    let conclusion: String?
    let steps: [GHStep]?
}

struct GHJobs: Decodable {
    let jobs: [GHJob]
}

struct GHAsset: Decodable {
    let name: String
    let size: Int
    let browser_download_url: String
}

struct GHRelease: Decodable {
    let tag_name: String
    let html_url: String
    let assets: [GHAsset]
}

/// GitHub REST 的最小封装：校验 token、触发 workflow、查运行、查 release 资产。
struct GitHubAPI {
    var token: String

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) throws -> URLRequest {
        guard let url = URL(string: "https://api.github.com" + path) else {
            throw GitHubError(message: "地址拼错了")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("NcnsDSH/0.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    private func send<T: Decodable>(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        let request = try request(path, method: method, body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GitHubError(message: "没有收到 GitHub 的回答")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(status: http.statusCode, data: data)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func error(status: Int, data: Data) -> GitHubError {
        let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
        switch status {
        case 401: return GitHubError(message: "Token 无效（401），重新生成一个。")
        case 403: return GitHubError(message: "权限不够（403）：Actions 需要 Read and write。")
        case 404: return GitHubError(message: "找不到仓库或 workflow（404）。检查 owner / repo / 文件名。")
        case 422: return GitHubError(message: "这个分支上没有可手动触发的 workflow（422）。")
        default: return GitHubError(message: message ?? "GitHub 返回 \(status)")
        }
    }

    // MARK: - Calls

    func login() async throws -> String {
        let user: GHUser = try await send("/user")
        return user.login
    }

    func dispatch(owner: String, repo: String, workflow: String, ref: String) async throws {
        let request = try request(
            "/repos/\(owner)/\(repo)/actions/workflows/\(workflow)/dispatches",
            method: "POST",
            body: ["ref": ref]
        )
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(status: http.statusCode, data: data)
        }
    }

    func runs(owner: String, repo: String, workflow: String) async throws -> [GHRun] {
        let list: GHRuns = try await send("/repos/\(owner)/\(repo)/actions/workflows/\(workflow)/runs?per_page=5")
        return list.workflow_runs
    }

    func run(owner: String, repo: String, id: Int) async throws -> GHRun {
        let run: GHRun = try await send("/repos/\(owner)/\(repo)/actions/runs/\(id)")
        return run
    }

    func jobs(owner: String, repo: String, runID: Int) async throws -> [GHJob] {
        let jobs: GHJobs = try await send("/repos/\(owner)/\(repo)/actions/runs/\(runID)/jobs")
        return jobs.jobs
    }

    func releases(owner: String, repo: String) async throws -> [GHRelease] {
        let list: [GHRelease] = try await send("/repos/\(owner)/\(repo)/releases?per_page=3")
        return list
    }
}
