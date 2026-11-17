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

/// 真实封面：按 seed 拉一张稳定的图，带占位、淡入和缓存。
/// 没有网络时保留占位渐变，不会闪白。
struct RemoteArtwork: View {
    let seed: String
    var cornerRadius: CGFloat = DSH.Radius.card
    var showsScrim = false

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1B1B20), Color(hex: 0x0D0D10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }

            if showsScrim {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
        }
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: seed) { await load() }
    }

    private func load() async {
        guard image == nil else { return }
        let key = normalizedSeed
        if let cached = ArtworkCache.shared.image(for: key) {
            image = cached
            return
        }
        guard let url = URL(string: "https://picsum.photos/seed/\(key)/900/600") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let loaded = UIImage(data: data) else { return }
            ArtworkCache.shared.store(loaded, for: key)
            withAnimation(DSH.Motion.fade) { image = loaded }
        } catch {
            // 离线就留在占位渐变上。
        }
    }

    private var normalizedSeed: String {
        let allowed = CharacterSet.alphanumerics
        let cleaned = seed.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
        return cleaned.isEmpty ? "ncnsdsh" : String(cleaned.prefix(40))
    }
}
