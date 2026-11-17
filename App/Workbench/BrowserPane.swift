import SwiftUI
import WebKit

/// 内置浏览器：地址栏 + WKWebView，够用来预览本地服务或文档。
struct BrowserPane: View {
    @State private var text = "https://example.com"
    @State private var target: URL? = URL(string: "https://example.com")
    @State private var loading = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 12))
                    .foregroundStyle(DSH.Palette.tertiary)

                TextField("输入网址", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(DSH.Palette.text)
                    .onSubmit(go)

                Button("前往", action: go)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DSH.Palette.accent)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(DSH.Palette.surface)

            ZStack(alignment: .top) {
                BrowserWebView(url: target, loading: $loading)

                if loading {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(DSH.Palette.accent)
                }
            }
        }
    }

    private func go() {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if !value.contains("://") { value = "https://" + value }
        target = URL(string: value)
        text = value
        Haptics.tap()
    }
}

struct BrowserWebView: UIViewRepresentable {
    let url: URL?
    @Binding var loading: Bool

    func makeCoordinator() -> Coordinator { Coordinator($loading) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        if let url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url, webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var loading: Bool

        init(_ loading: Binding<Bool>) {
            _loading = loading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            loading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            loading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            loading = false
        }
    }
}
