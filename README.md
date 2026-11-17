# NcnsDSH

DeepSeek Harness 的 iOS 原生客户端。视觉参照 tv 的暗色影院首页与 Apple Music 的
artwork 驱动详情页，材质用 iOS 26 Liquid Glass；会话、工具卡、审批全部原生。

```
┌──────────── iPhone ────────────┐        ┌──────── 电脑 ────────┐
│ SwiftUI：首页 / 会话 / 审批      │   WS   │ dsh web              │
│ 演示数据（接网关前的占位）        │◄──────►│ 会话 · 工具 · 审批    │
│ WKWebView：插件页 / 终端兜底     │        │ 工作区                │
└────────────────────────────────┘        └──────────────────────┘
```

**当前阶段**：视觉与交互已按最终形态跑通，数据是本地的演示数据（`DemoStore`）。
接 `dsh-plugin-mobile-gateway` 的 WebSocket 之后，只需换掉 `DemoStore.send/approve` 两个写入口，
视图层不动。

## 快速开始

### 1. 宿主：让 `dsh web` 监听局域网

默认只监听 `127.0.0.1`，手机连不上。指定电脑的局域网地址（必须是本机某个网卡的具体地址，不能用 `0.0.0.0`）：

```sh
dsh web --host 192.168.1.8
```

终端会打印 `http://192.168.1.8:3080/?token=…`。把这个地址（或二维码里的内容）交给手机。

`--host` 也可以换成 Tailscale / ZeroTier 的地址；公网访问请套 HTTPS 反向代理，并用 `--trusted-host` 声明域名，
否则 `/api` 的 Host 校验会返回 403。

### 2. 手机：连接

打开 NcnsDSH，粘贴地址（token 会自动从 `?token=` 里拆出来），或点「扫描二维码」。
连上后进的是原生界面：

- **首页**：hero + 「继续 / 工作区 / 最近完成」三条 shelf；
- **会话**：原生消息流、可折叠工具卡、底部玻璃输入条、审批 sheet；
- **运行中胶囊**：离开会话后底部仍浮着正在跑的那一个，点它回去；
- **插件页 / 终端 / 文件预览**：还在「设置 → 网页版」里（WKWebView 兜底）。

token 存钥匙串，最近宿主存 UserDefaults，最多 8 台。

### token 是一次性的

`dsh web` 打印出来的 token 只负责换一枚登录 cookie（`/` 上 303 + `Set-Cookie`）。
换过之后同一行 token 再用就是 401；宿主重启也会发新 token。
正常使用靠的是 WKWebView 里持久化的 cookie，token 只在第一次配对时需要。
cookie 丢了（清了数据、换了宿主进程）就点错误页上的「重新配对」，回电脑上拿新地址。

## 构建

工程用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成，`App/` 下是全部源码，没有第三方依赖。

```sh
brew install xcodegen
xcodegen generate
open NcnsDSH.xcodeproj     # 选自己的 Team 即可真机调试
```

### 本机一键出包

```sh
./build-ipa.sh      # 产出 NcnsDSH-unsigned.ipa + SHA256.txt
```

### CI

`.github/workflows/ios.yml` 在 `macos-15` 上构建无签名 IPA 并上传 artifact。
macOS runner 当前拿不到机器时（job 排队 15 分钟被取消），换 `codemagic.yaml` 里的
`ncnsdsh-unsigned-ipa`，或任意一台 Mac，详见 [`docs/install.md`](docs/install.md)。

侧载（AltStore / Sideloadly / TrollStore）后即可安装；免费 Apple ID 签名 7 天有效。

## 目录

```
NcnsDSH/
├── project.yml              # XcodeGen 描述
├── App/
│   ├── Info.plist           # ATS、相机、本地网络、ncnsdsh:// scheme
│   ├── DSHApp.swift
│   ├── RootView.swift
│   ├── DesignSystem/        # 配色、字体、Liquid Glass 封装
│   ├── Model/               # Host 解析、HostStore、Keychain、实体、DemoStore
│   ├── Views/               # 首页、会话、工作区、定时、设置、配对、网页兜底
│   └── Assets.xcassets/     # AppIcon（tools/make-icon.mjs 生成）
├── tools/                   # 图标生成、宿主连通性探测
└── docs/                    # 调研、安装、OpenWorld 集成、重构提示词
```

## 玻璃与系统版本

`App/DesignSystem/Glass.swift` 把 Liquid Glass 收在一个地方：
iOS 26 SDK 编出来、跑在 iOS 26 上是真玻璃（`.glassEffect(_:in:)`）；
旧 SDK 或旧系统自动退化成 `.ultraThinMaterial`，用 `#if compiler(>=6.2)` + `#available` 隔开。

玻璃只给 chrome（tab bar、toolbar、输入条、审批、运行中胶囊）和卡片按下态；
消息气泡、列表行、滚动内容一律不透明，保证对比度。

## 已知限制

- 数据还是演示数据；`DemoStore` 就是接网关时要替换的那一层。
- 必须有一台在运行的宿主；离线不可用。
- 窄屏按 iPhone 竖屏调过，iPad 三栏还没做。
- 后台不保活：切走后连接会断，回来重连。

## 路线

1. **接网关**：`dsh-plugin-mobile-gateway` 的 WebSocket（配对、会话列表、流式回复、审批、上传）。
2. **窄屏与 iPad**：`NavigationSplitView` 三栏，宽度 < 700pt 收成一栏。
3. **原生增强**：分享扩展、主屏小组件、灵动岛 Live Activity。
4. **打磨**：真封面（会话截图/工作区图标）、Markdown 渲染、代码高亮。
