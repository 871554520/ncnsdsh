# DSH / NcnsDSH — Apple Music × Apple TV 方向的重构方案

目标：把「AI 生成感」（通用气泡、廉价渐变、过多装饰）换成系统质感——
纯黑画布、SF Pro、系统材质、12pt 圆角、**只留一个强调色**，让内容本身成为主角。

---

## A. Design System

### A1. 颜色 token

| Token | 值 | 用途 |
|---|---|---|
| `canvas` | `#000000` | 全屏底色，不叠任何渐变 |
| `surface` | `white 6%` | 卡片、行、面板 |
| `surfaceRaised` | `white 10%` | 被选中的卡片、输入栏 |
| `hairline` | `white 12%` | 分割线（0.5pt） |
| `accent` | `#FA2D48` | 当前会话、关键按钮、状态点 |
| `textPrimary` | `white 96%` | 标题与正文 |
| `textSecondary` | `white 60%` | 次要信息 |
| `textTertiary` | `white 36%` | 元数据、时间 |
| `danger` | `#FF6961` | 错误、失败态 |
| `success` | `#32D74B` | 完成态（只在状态点用） |

规则：一屏最多出现**一处**红色实心元素；红色只用于「当前」，不用于「好看」。

### A2. 字体层级（全部 SF Pro，走 Dynamic Type）

| 层级 | TextStyle | 用法 |
|---|---|---|
| `display` | `.largeTitle` bold, rounded 关闭 | 首页大标题（34pt） |
| `title` | `.title2` semibold | 区块标题 |
| `headline` | `.headline` | 卡片标题 |
| `body` | `.body` | 消息正文、说明 |
| `callout` | `.callout` | 次要正文 |
| `footnote` | `.footnote` | 元数据 |
| `caption` | `.caption2` + `.monospacedDigit()` | 时间、计数 |

不要用 `.system(size:)` 写死字号——那会锁死 Dynamic Type。用 `Font.system(.title2, design: .default)`。

### A3. 间距 / 圆角 / 材质 / 阴影

- 间距：4 / 8 / 12 / 16 / 20 / 24 / 32 / 44（4 的倍数）。
- 圆角：**12**（卡片、输入栏）/ 8（小标签）/ 22（sheet）/ full（胶囊）。
- 材质：导航与浮层用 `.ultraThinMaterial`，输入栏用 `.regularMaterial`；内容区**不透明**，保证对比度。
- 阴影：只给浮层（mini bar、sheet），`black 40% / radius 24 / y 12`；卡片不投影，靠 surface 分层。

### A4. 动效曲线

| 名称 | 曲线 | 用途 |
|---|---|---|
| `snap` | `.spring(response: 0.28, dampingFraction: 0.86)` | 按压、选中 |
| `flow` | `.spring(response: 0.42, dampingFraction: 0.9)` | 展开/收起、布局变化 |
| `fade` | `.easeOut(duration: 0.18)` | 透明度、高光 |
| `scroll` | 系统 `scrollTransition` | 视差、淡出 |

原则：**不做 bounce 过度的玩具弹簧**；阻尼 ≥ 0.85，位移回正一次到位。

### A5. 触觉（`.sensoryFeedback`）

```swift
.sensoryFeedback(.selection, trigger: selectedTab)      // 切 Tab
.sensoryFeedback(.impact(weight: .light), trigger: tapCount) // 卡片按下
.sensoryFeedback(.success, trigger: finishedRun) { old, new in new > old }
.sensoryFeedback(.warning, trigger: pendingApproval)
```

### A6. Swift 落地

```swift
enum DSH {
    enum Palette {
        static let canvas = Color.black
        static let surface = Color.white.opacity(0.06)
        static let raised = Color.white.opacity(0.10)
        static let hairline = Color.white.opacity(0.12)
        static let accent = Color(red: 0.980, green: 0.176, blue: 0.282) // #FA2D48
        static let text = Color.white.opacity(0.96)
        static let secondary = Color.white.opacity(0.60)
        static let tertiary = Color.white.opacity(0.36)
    }

    enum Radius { static let card: CGFloat = 12; static let sheet: CGFloat = 22 }

    enum Motion {
        static let snap = Animation.spring(response: 0.28, dampingFraction: 0.86)
        static let flow = Animation.spring(response: 0.42, dampingFraction: 0.90)
    }

    enum Inset { static let gutter: CGFloat = 20; static let row: CGFloat = 12 }
}
```

---

## B. 主要屏幕结构

### B1. 工作区列表（Library 感）

```swift
ScrollView {
    LazyVStack(spacing: 24) {
        // 大卡片：2 列，封面优先
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)], spacing: 16) {
            ForEach(workspaces) { workspace in
                NavigationLink(value: Route.workspace(workspace.id)) {
                    VStack(alignment: .leading, spacing: 8) {
                        RemoteArtwork(seed: workspace.seed)      // 真实封面
                            .frame(height: 160)
                            .clipShape(.rect(cornerRadius: DSH.Radius.card))
                        Text(workspace.name).font(.headline)
                        Text("\(workspace.count) 个会话")
                            .font(.footnote).foregroundStyle(DSH.Palette.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    .padding(.horizontal, DSH.Inset.gutter)
}
```

### B2. 会话列表（Listen Now 感：一行一个，封面 56pt）

```swift
LazyVStack(spacing: 0) {
    ForEach(sessions) { session in
        Button { open(session) } label: {
            HStack(spacing: 12) {
                RemoteArtwork(seed: session.seed)
                    .frame(width: 56, height: 56)
                    .clipShape(.rect(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title).font(.body).lineLimit(1)
                    Text(session.subtitle).font(.footnote).foregroundStyle(DSH.Palette.secondary)
                }
                Spacer()
                if session.isRunning { RunningDot() }        // 唯一红色
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        Divider().overlay(DSH.Palette.hairline).padding(.leading, 68)
    }
}
```

### B3. 聊天主界面（去掉气泡）

```swift
ScrollView {
    LazyVStack(alignment: .leading, spacing: 18) {
        ForEach(messages) { message in
            MessageRow(message)              // 不做气泡，靠字号与缩进分层
        }
    }
    .padding(.horizontal, DSH.Inset.gutter)
}
.safeAreaInset(edge: .bottom) { ComposerBar() }
```

`MessageRow` 的层次：

```swift
switch message.role {
case .user:
    // 右对齐、最多 80% 宽、无底色；只用一层极淡的 accent 10% 背景做「我说的」
    Text(message.text)
        .frame(maxWidth: 300, alignment: .trailing)
        .padding(.leading, 60)
case .assistant:
    // 全宽，正文 17pt，行距 4；工具调用是折叠行，不是卡片堆
    VStack(alignment: .leading, spacing: 10) {
        Text(message.text).font(.body).lineSpacing(4)
        ForEach(message.tools) { ToolRow($0) }
    }
}
```

### B4. 设置（系统 grouped 质感）

```swift
Form {
    Section { AccountRow() }
    Section("工作区") { WorkspaceRows() }
    Section("关于") { AboutRow(); CreditsRow() }
}
.scrollContentBackground(.hidden)
.background(DSH.Palette.canvas)
```

### B5. mini 状态栏（当前会话指示器）

```swift
ZStack(alignment: .bottom) {
    TabView(selection: $tab) { ... }
    if let current = miniSession {
        MiniBar(session: current, isExpanded: $expanded)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .matchedGeometryEffect(id: "mini", in: miniNamespace)
    }
}
```

展开时把同一个 `matchedGeometryEffect` 的容器铺满：

```swift
if expanded {
    ChatSurface(session: current)
        .matchedGeometryEffect(id: "mini", in: miniNamespace)
        .ignoresSafeArea()
        .transition(.opacity)
}
```

---

## C. 关键交互实现建议

### C1. mini bar → 全屏（matchedGeometryEffect）

要点：**一个 namespace、一个 id、两个层级**。mini 态是胶囊（56pt 高）；展开态是整屏容器。
用 `withAnimation(DSH.Motion.flow)` 切换 `expanded`，同时在展开态顶部保留一个「收起」把手。

```swift
@Namespace private var miniNamespace

Button { withAnimation(DSH.Motion.flow) { expanded = true } } label: {
    HStack(spacing: 10) {
        RemoteArtwork(seed: current.seed).frame(width: 32, height: 32).clipShape(.rect(cornerRadius: 6))
        VStack(alignment: .leading, spacing: 0) {
            Text(current.title).font(.footnote.weight(.semibold)).lineLimit(1)
            Text(current.subtitle).font(.caption2).foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: "chevron.up").font(.caption2.bold())
    }
    .padding(.horizontal, 12).padding(.vertical, 8)
    .background(.regularMaterial, in: .rect(cornerRadius: 28))
    .matchedGeometryEffect(id: "mini", in: miniNamespace)
}
.buttonStyle(.plain)
```

注意：`matchedGeometryEffect` 只对**同一棵视图树里同时存在**的两个视图生效，所以展开时要
把 mini 从底部移除、把展开层加进来，用 `if/else` 包在同一个 `ZStack` 里。

### C2. 滚动时最小化 Tab / 导航

iOS 26 有系统 API：`.tabBarMinimizeBehavior(.onScrollDown)`。
iOS 17/18 用状态驱动：

```swift
@State private var collapsed = false

ScrollView { ... }
    .onScrollGeometryChange(for: Bool.self) { geo in
        geo.contentOffset.y > 60
    } action: { _, isDown in
        withAnimation(DSH.Motion.snap) { collapsed = isDown }
    }
    .safeAreaInset(edge: .top) {
        TopBar(collapsed: collapsed)
            .frame(height: collapsed ? 44 : 56)
    }
```

`onScrollGeometryChange` 是 iOS 18；17 上退化成 `GeometryReader` + preference。

### C3. 消息流

- `LazyVStack` + 稳定 id，**不要**用 index 当 id。
- 流式更新合并到 30Hz，只改最后一条的 `text`，不重建列表。
- 插入新消息用 `.transition(.opacity.combined(with: .offset(y: 8)))`，配合 `.animation(DSH.Motion.flow, value: count)`。
- 自动滚动只在「用户已经在底部」时触发；否则显示回到底部的小胶囊。

### C4. 输入栏

```swift
HStack(alignment: .bottom, spacing: 8) {
    Button { } label: { Image(systemName: "plus").font(.title3) }
    TextField("消息", text: $draft, axis: .vertical)
        .lineLimit(1...5)
        .textFieldStyle(.plain)
    Button(action: send) { Image(systemName: "arrow.up.circle.fill").font(.title2) }
        .disabled(draft.isEmpty)
}
.padding(.horizontal, 12).padding(.vertical, 8)
.background(.regularMaterial, in: .rect(cornerRadius: 12))   // 12pt，不是胶囊
```

---

## D. 迁移建议（不推倒重来）

1. **先换 token，不动结构**：把 `Theme.accent` 换成 `#FA2D48`、`Theme.ink` 换成纯黑、圆角统一 12。
   这一步改完，App 的气质立刻从「AI 紫蓝」变成「系统黑白 + 一点红」。
2. **再换「封面」**：卡片、行、hero 的渐变占位换成真实图片（见 `RemoteArtwork`），
   这是投入产出比最高的一步——有图之后版面自然有层次。
3. **然后删装饰**：去掉大发光、渐变描边、彩色徽章；一屏只留一处强调色。
4. **再改消息流**：先去掉气泡底色，再调字号与缩进，最后才做工具行的折叠。
5. **最后做 mini bar**：它是结构性改动（namespace、层级、展开动画），放在视觉稳定之后。
6. 每一步都可单独构建、单独回滚；不要一次改三层。

验收清单：

- [ ] 截图里数一下红色元素：一屏 ≤ 1 处
- [ ] Dynamic Type 调到 AX3，卡片标题不截断、输入栏不遮挡
- [ ] 纯黑背景下，正文与背景对比度 ≥ 7:1（白 96% 达标）
- [ ] mini bar 展开/收起过程中，列表不跳动
- [ ] 滚动时 Tab/顶栏收缩平滑，没有两段式跳变
