# 开发阶段规划

> 项目名称：ClipHistory  
> 版本：v1.0  
> 最后更新：2026-06-02  
> 原则：每个阶段结束后都必须有可运行、可验证的结果，再进入下一阶段

---

## 总览

| 阶段 | 名称 | 核心目标 | 预计工作量 | 状态 |
|---|---|---|---|---|
| Phase 1 | 项目骨架 | 菜单栏图标 + 空 Popover | 1-2 小时 | 待开始 |
| Phase 2 | 数据层 | CoreData 模型建立 | 1 小时 | 待开始 |
| Phase 3 | 监听服务 | 剪贴板轮询 + 隐私检测 | 1-2 小时 | 待开始 |
| Phase 4 | 基础 UI | 文字卡片列表展示 | 2-3 小时 | 待开始 |
| Phase 5 | 交互动作 | 置顶、删除、粘贴 | 1 小时 | 待开始 |
| Phase 6 | 图片支持 | 图片捕获 + 缩略图显示 | 1 小时 | 待开始 |
| Phase 7 | 搜索功能 | 实时过滤历史记录 | 30 分钟 | 待开始 |
| Phase 8 | 设置与清理 | 保留时长配置 + 自动清理 | 1 小时 | 待开始 |
| Phase 9 | UI 打磨 | 配色、动效、空状态 | 1-2 小时 | 待开始 |
| Phase 10 | 打包发布 | 生成 .app 文件 | 30 分钟 | 待开始 |

---

## Phase 1 — 项目骨架

**目标**：能在菜单栏看到图标，点击弹出空面板，Dock 栏无图标。

**需要完成的文件**：
- `ClipHistory.xcodeproj`（Xcode 新建项目）
- `ClipHistoryApp.swift`（@main 入口）
- `AppDelegate.swift`（NSStatusItem + NSPopover）
- `Info.plist`（设置 LSUIElement = YES）
- `ClipHistory.entitlements`（关闭沙盒）

**验收标准**：
- [ ] 运行后菜单栏右上角出现剪贴板图标
- [ ] 点击图标弹出空白 Popover（无崩溃）
- [ ] 点击 Popover 以外区域自动关闭
- [ ] Dock 栏看不到 ClipHistory 图标

---

## Phase 2 — 数据层

**目标**：CoreData 模型就位，数据可持久化到磁盘。

**需要完成的文件**：
- `ClipHistory.xcdatamodeld`（实体 ClipItemEntity）
- `PersistenceController.swift`（单例，CoreData stack）

**验收标准**：
- [ ] 编译无报错
- [ ] 运行后在 `~/Library/Application Support/ClipHistory/` 能看到 `.sqlite` 文件生成

---

## Phase 3 — 监听服务

**目标**：复制任意文字后，数据被写入 CoreData（通过调试日志验证）。

**需要完成的文件**：
- `ClipboardMonitor.swift`（轮询 + 隐私检测 + 写入）
- `ClipItemType.swift`（.text / .image 枚举）

**验收标准**：
- [ ] 复制文字后，Xcode 控制台打印确认日志
- [ ] 复制相同文字两次，数据库中只有一条（去重生效）
- [ ] 从 1Password 复制密码后，控制台日志显示已跳过（若无 1Password，用其他方式测试）
- [ ] 停止轮询时不崩溃（App 退出时清理 timer）

---

## Phase 4 — 基础 UI

**目标**：Popover 中显示文字类型的历史记录卡片，按时间倒序排列。

**需要完成的文件**：
- `PopoverRootView.swift`
- `ClipCardView.swift`（仅文字，暂不支持图片）
- `ClipHistoryViewModel.swift`（基础版，仅获取数据）

**验收标准**：
- [ ] 复制文字后打开 Popover，卡片出现在列表最顶部
- [ ] 多条记录按时间倒序排列
- [ ] 卡片文字超过 3 行时显示省略号
- [ ] 卡片显示来源 App 名称和时间戳

---

## Phase 5 — 交互动作

**目标**：三个核心操作全部生效。

**需要完成的文件**：
- 更新 `ClipHistoryViewModel.swift`（添加 pin/delete/paste 方法）
- 更新 `ClipCardView.swift`（添加按钮和点击手势）

**验收标准**：
- [ ] 点击卡片主体 → 关闭 Popover → 当前 App 收到粘贴内容
- [ ] 点击置顶按钮 → 卡片跳到列表最顶部，再次点击恢复原位
- [ ] 点击删除按钮 → 卡片从列表消失，数据库记录被删除
- [ ] 粘贴操作不会产生新的历史记录（自身粘贴不被记录）

---

## Phase 6 — 图片支持

**目标**：复制图片后，Popover 中显示图片缩略图卡片。

**需要完成的文件**：
- 更新 `ClipboardMonitor.swift`（添加图片读取）
- 更新 `ClipCardView.swift`（添加图片展示分支）
- `NSImage+Thumbnail.swift`（缩略图扩展）

**验收标准**：
- [ ] 截图（Cmd+Ctrl+Shift+4）后，Popover 中出现图片卡片
- [ ] 图片缩略图高度固定 80pt，比例正确
- [ ] 复制图片后点击卡片，可粘贴到 Pages 或 Keynote

---

## Phase 7 — 搜索功能

**目标**：搜索框输入时实时过滤文字记录。

**需要完成的文件**：
- `SearchBarView.swift`
- 更新 `PopoverRootView.swift`（集成搜索状态和 FetchRequest predicate）

**验收标准**：
- [ ] 搜索框输入文字时，列表实时过滤（只显示包含该文字的卡片）
- [ ] 搜索框清空后，恢复显示所有记录
- [ ] 搜索结果中图片卡片不显示（仅搜索文字内容）
- [ ] 搜索不区分大小写

---

## Phase 8 — 设置与清理

**目标**：保留时长可配置，过期记录自动清理。

**需要完成的文件**：
- `SettingsView.swift`
- `RetentionManager.swift`
- 更新 `AppDelegate.swift`（启动时调用 RetentionManager）

**验收标准**：
- [ ] 点击底栏"设置"按钮，弹出设置面板
- [ ] Segmented Control 切换 1/3/5 天，设置保存后重启 App 依然生效
- [ ] 修改系统时间测试（或通过代码注入测试）：过期记录被清理
- [ ] 置顶记录不被清理
- [ ] 超过 100 条时，最旧的未置顶记录被自动删除

---

## Phase 9 — UI 打磨

**目标**：视觉效果达到设计规范标准。

**工作内容**：
- 应用 `#5B9BD5` 主色（Assets.xcassets 中设置 AccentColor）
- 置顶卡片添加 `#EBF3FB` 背景
- 卡片出现/删除添加动效
- 添加空状态视图（无记录时显示提示）
- 按钮 hover 状态视觉反馈
- 整体间距、字体、圆角对照设计规范微调

**验收标准**：
- [ ] 视觉与设计规范（03-design-spec.md）一致
- [ ] 深色模式下界面正常，无颜色异常
- [ ] 空状态图标和提示文字正常显示
- [ ] 卡片删除时有动画，不是突然消失

---

## Phase 10 — 打包发布

**目标**：生成可独立运行的 .app 文件，放入 /Applications。

**步骤**：
1. Xcode 菜单：Product > Archive
2. Organizer 窗口：Distribute App > Copy App
3. 保存到桌面，拖入 /Applications/
4. 双击启动，验证全功能

**验收标准**：
- [ ] .app 文件可从 /Applications 直接启动
- [ ] 所有 Phase 1–9 验收项在打包版本中依然通过
- [ ] 首次启动时辅助功能权限提示正常弹出

---

## 开发规则

1. **每个 Phase 完成后**，必须在 devlog/ 中记录当天完成的内容
2. **遇到报错**，先查阅技术规范文档，再修改代码
3. **不要跨 Phase 开发**：Phase N 未验收通过，不开始 Phase N+1
4. **修改设计或技术方案时**，同步更新对应 docs/ 文件
