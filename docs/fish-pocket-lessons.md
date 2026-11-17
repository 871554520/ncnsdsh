# 从 fish-pocket 学到的（以及我们采纳了什么）

研究对象：[imsai-sh/fish-pocket](https://github.com/imsai-sh/fish-pocket) — 目前最完整的
「DSH 装进手机」实现：引擎跑在 App 里、界面全原生、上架 App Store / TestFlight。

## 先说许可

fish-pocket 是 **MIT + 附加条款**：个人使用、阅读、修改、fork 提 PR 都不受限，
但**商用**（靠它赚钱、分发带付费功能的构建）需要作者书面授权。

所以这里只**学结构、学做法**，代码一行都不抄；NcnsDSH 的实现全部是自己写的。

## 它的结构

```
app/
├── DshIOS/            # 主 App
│   ├── Views/         # 94 个视图文件（按功能拆，单文件都不大）
│   ├── Models/        # 29 个
│   ├── Core/          # 14 个：EngineClient / StreamMux / JSON / AppLanguage / UpdateChecker …
│   ├── Remote/        # 13 个：连电脑/服务器的远程会话
│   ├── Browser/       # 7 个：内置浏览器
│   ├── PhoneControl/  # 5 个：操控别的 App（配合 iCTRL）
│   └── Native/        # 4 个：N-API 桥
├── Watch/             # watchOS App
├── ShareExtension/    # 分享扩展
├── Shared/            # App 与扩展共用的类型（WidgetSnapshot / ShareInbox / Intents / Localizable）
├── LiveActivity/      # 灵动岛
├── engine/            # 打进 App 的 DSH 引擎
└── native/            # nodejs-mobile、libgit2、CPython、ffmpeg 的绑定
```

值得注意的取舍：**`Views/` 拆得很碎**（94 个），`Core/` 只放不依赖 SwiftUI 的东西。
这样编译增量小、改一个页面不牵动别的页面。

## 十个可迁移的做法

| # | 做法 | 为什么好 | NcnsDSH 现状 |
|---|---|---|---|
| 1 | **App Intents + AppShortcutsProvider**：Siri/快捷指令/控制中心直接「新建会话」，intent 不自己干活，只把意图交给窗口 | 系统级入口，零额外维护 | **已采纳**：`NewSessionIntent` / `ContinueSessionIntent` + `NcnsIntentBridge` |
| 2 | **一个 Router 持有 Tab 和导航栈**，深链、intent、widget 都走同一个入口 | 避免每个页面各自处理跳转 | **已采纳**：`AppRouter`（`tab` + `path`），`ncnsdsh://new`、`ncnsdsh://session/<id>` |
| 3 | **WidgetSnapshot 走 App Group**：只写展示需要的东西（标题、阶段、起始时间），带 `staleAfter` 过期规则 | 小组件不查引擎、不碰 token | 设计了，**未落地**（要 widget target + 签名） |
| 4 | **ShareInbox**：分享扩展把内容写进 App Group 的文件夹，再开 `dsh://share/<id>` 把 App 拉起来 | 分享进来的链接/图片不会丢 | 未做 |
| 5 | **Live Activity** 显示正在跑的会话 | 锁屏/灵动岛看进度 | 未做 |
| 6 | **String Catalog + `SWIFT_EMIT_LOC_STRINGS`**，UI 先写中文，翻译后补 | 上架必需，后补成本低 | 部分：已开 `SWIFT_EMIT_LOC_STRINGS`，还没建 `.xcstrings` |
| 7 | **多套 App 图标**（`ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`） | 纯装饰但有产品感 | 未做 |
| 8 | **Core 与 Views 分离**，Core 不 import SwiftUI | 可单测、编译快 | 已采纳：`Model/` 不依赖 SwiftUI（`DemoStore` 除外，它要触感） |
| 9 | **iPad 多窗口**（`UIApplicationSupportsMultipleScenes`） | 一台设备并排跑两个会话 | **已采纳** |
| 10 | **watchOS App** 与主 App 共享 `WatchShared/` 载荷 | 抬腕看进度 | 本期不做 |

## 刻意不学的

- **引擎入机**（nodejs-mobile + 四个原生框架）：那是另一个量级的工程，NcnsDSH 是客户端。
- **吉祥物与品牌**：视觉是它们的产品资产。
- **内购与账号体系**：不碰钱的那部分。
- **94 个视图的命名方式**：按功能拆没问题，但我们的页面还少，先按模块分。

## 下一步（按性价比排）

1. **Widget + Live Activity**：需要先加 App Group 与 widget extension，签名侧要真账号。
2. **Share 扩展**：技术门槛比 widget 低，收益高（从微信/Safari 直接发进来）。
3. **String Catalog**：现在不做，等界面文案稳定了再一次性抽。
4. **多套图标**：等主图标定稿。

## 参考

- 仓库：<https://github.com/imsai-sh/fish-pocket>
- 许可：MIT + 附加条款（商用需授权）
- 同类：[Whaleness / dsh-mobile](https://github.com/Clarklevis1995/dsh-mobile)（KMP + 原生，走 mobile-gateway WebSocket）
