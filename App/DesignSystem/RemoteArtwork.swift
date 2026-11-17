import SwiftUI
import UIKit

/// 封面图缓存：内存一级（NSCache），HTTP 层交给 URLSession 自己的磁盘缓存。
final class ArtworkCache {
    static let shared = ArtworkCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 80
        cache.totalCostLimit = 48 * 1024 * 1024
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func store(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

/// 项目名 → GitHub 仓库。工作区封面优先用仓库的 OG 图，看起来才像“这个项目”。
enum ProjectMeta {
    static func githubSlug(for name: String) -> String? {
        switch name.lowercased() {
        case "openworld", "openworld-site": return "NevercRyNow/openworld"
        case "openworld-ios", "ncnsdsh", "ios-dsh": return "NevercRyNow/ncnsdsh"
        default: return nil
        }
    }
}

/// 没有网络图时的项目封面：按名字生成稳定的渐变 + 首字母，不用随机照片。
struct ProjectCover: View {
    let name: String

    private var palette: [Color] {
        let seed = abs(name.hashValue)
        let palettes: [[UInt32]] = [
            [0x1D2B53, 0x3E6BFF],
            [0x14342B, 0x2FA37A],
            [0x2E1F3E, 0x7A5CFF],
            [0x3A2418, 0xD9834A],
            [0x152E36, 0x2E8FA3],
            [0x3B1F2B, 0xC2577E],
        ]
        let pair = palettes[seed % palettes.count]
        return [Color(hex: pair[0]), Color(hex: pair[1])]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)

            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 18
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += step
                    }
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
            }

            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.22))
        }
    }
}

/// 封面：有 GitHub 仓库就用仓库 OG 图，否则用生成封面；
/// 图片永远按容器尺寸铺满并裁切，不会溢出压到文字。
struct RemoteArtwork: View {
    var seed: String
    var github: String? = nil
    var cornerRadius: CGFloat = DSH.Radius.card
    var showsScrim = false

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ProjectCover(name: seed)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .transition(.opacity)
                }

                if showsScrim {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: urlKey) { await load() }
    }

    private var urlKey: String {
        if let github { return "gh:" + github }
        return "seed:" + normalizedSeed
    }

    private var url: URL? {
        if let github {
            return URL(string: "https://opengraph.githubassets.com/1/\(github)")
        }
        return URL(string: "https://picsum.photos/seed/\(normalizedSeed)/900/600")
    }

    private var normalizedSeed: String {
        let allowed = CharacterSet.alphanumerics
        let cleaned = seed.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
        return cleaned.isEmpty ? "ncnsdsh" : String(cleaned.prefix(40))
    }

    private func load() async {
        guard image == nil, let url else { return }
        let key = urlKey
        if let cached = ArtworkCache.shared.image(for: key) {
            image = cached
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let loaded = UIImage(data: data) else { return }
            ArtworkCache.shared.store(loaded, for: key)
            withAnimation(DSH.Motion.fade) { image = loaded }
        } catch {
            // 离线就留在生成封面上。
        }
    }
}
