# NcnsDSH

制作：**郑壹鸣**（设计与开发）· Made by NevercryNow


DeepSeek Harness 的 iOS 原生客户端。视觉参照 tv 的暗色影院首页与 Apple Music 的
artwork 驱动详情页，材质用 iOS 26 Liquid Glass；会话、工具卡、审批全部原生。

```
┌──────────── iPhone ────────────┐        ┌──────── 电脑 ────────┐
│ SwiftUI：首页 / 会话 / 审批      │   WS   │ dsh web              │
│ 演示数据（接网关前的占位）        │◄──────►│ 会话 · 工具 · 审批    │
│ WKWebView：插件页 / 终端兜底     │        │ 工作区                │
└────────────────────────────────┘        └──────────────────────┘
```

**两种工作方式**

- **本机**：登录 DeepSeek API Key，模型直连，会话和文件都在手机上；能读写
  `Documents/NcnsDSH/workspace`。不需要电脑。
- **远端**：连一台跑 `dsh web` 的电脑，会话、工具、审批都在那台机器上执行
  （当前还是 `DemoStore` 的演示数据，接 `dsh-plugin-mobile-gateway` 后替换两个写入口即可）。

登录入口在「设置 → DeepSeek 账号」，Key 只进钥匙串；登录时会用 `/models` 验一次。

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

打开 NcnsDSH 直接就是工作区，不用先登录、也不用先连电脑。
需要连宿主时：设置 → 远端宿主 → 「连接电脑」，粘贴地址（token 会自动从 `?token=` 里拆出来），
或点「扫描二维码」。连上后：

- **首页**：hero + 「继续 / 本机 / 工作区 / 最近完成」四条 shelf；
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

### CI：两条线

| workflow | runner | 产物 | 玻璃 |
|---|---|---|---|
| `ios.yml` | `macos-15`（Xcode 16.4 / iOS 18.5 SDK） | `NcnsDSH-unsigned.ipa` | 编译期走 `.ultraThinMaterial` 回退 |
| `ios26.yml` | `macos-26`（Xcode 26.6 / iOS 26.5 SDK） | `NcnsDSH-unsigned-glass.ipa` | 真 Liquid Glass（`.glassEffect`） |

想看到真正的玻璃效果，用 `ios26.yml` 的产物；`ios.yml` 那一条是给旧工具链和 App Store
审核之外的分发留的退路。两条都在 Actions 页面里手动可跑，push 时只有 `ios.yml` 自动触发。

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

## 在 App 里出包

「构建」Tab 把 GitHub Actions 搬进了 App：

1. 设置里填一个细粒度 Token（Actions: Read and write、Contents: Read）；
2. 填 owner / repo / workflow，点「开始构建」；
3. 实时看每一步（装 XcodeGen → 生成工程 → 编译 → 打包 → 上传 → 挂 Release）；
4. 成功后「下载 IPA」，文件落在 `Documents/NcnsDSH/builds`，可以直接分享出去。

workflow 里的 `softprops/action-gh-release` 会把 IPA 挂成一个 prerelease，
App 用 `/releases` 找到最新那条的 `.ipa` 资产直接下载（公开仓库不需要额外鉴权）。
App 内还带一份 5 步教程（右上角问号）。

## 品牌与动效

- 标识在 `brand/`：`mark.svg`（渐变 N）、`wordmark.svg`、`badge.svg`（MADE BY NEVERCRYNOW）。
- App 内同一套比例由 `App/DesignSystem/Brand.swift` 画出来：`BrandMark` / `BrandWordmark` / `BrandBadge`，
  用在关于页、构建页页脚和连接页。
- 设计板：`docs/design/brand-board.drawio`（drawio 可编辑）+ 导出的 `brand-board.svg`。

液态玻璃的交互：

- `.liquidDrag()`：横向拖动时 `scaleX` 拉伸到 1.14、`scaleY` 压到 0.90、旋转夹在 ±10°，
  过 90pt 触发一次轻触感；松手用 `interpolatingSpring(stiffness: 210, damping: 14)` 回位，
  初速度取 `predictedEndTranslation`。
- 只挂在能"拿起来"的东西上：运行中胶囊、两个 hero 卡、审批把手；列表行和消息气泡不参与。

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
