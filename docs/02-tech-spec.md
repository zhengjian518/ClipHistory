# 技术规范文档

> 项目名称：ClipHistory  
> 版本：v1.0  
> 最后更新：2026-06-02

---

## 1. 技术选型

| 层次 | 选择 | 原因 |
|---|---|---|
| 语言 | Swift 6 | 原生 Mac，最佳性能和系统集成 |
| UI 框架 | SwiftUI + AppKit | SwiftUI 写界面，AppKit 管理菜单栏和 Popover |
| 数据存储 | CoreData | 原生支持二进制图片、SwiftUI FetchRequest 集成、无外部依赖 |
| 剪贴板监听 | NSPasteboard 轮询（500ms） | macOS 无推送通知，轮询是业界标准做法 |
| 沙盒 | 关闭 | 方便访问剪贴板和辅助功能，非 AppStore 个人工具无需沙盒 |
| 粘贴模拟 | CGEvent（Cmd+V） | 对所有 App 生效，只需辅助功能权限 |
| 开发工具 | Xcode 15+ | Apple 官方 IDE，免费，App Store 可下载 |
| 最低系统版本 | macOS 13 Ventura | SwiftUI 4 特性要求 |

---

## 2. 项目文件结构

```
ClipHistory.xcodeproj/
ClipHistory/
├── ClipHistoryApp.swift              # @main 入口，接入 AppDelegate
├── AppDelegate.swift                 # NSStatusItem、Popover 生命周期
├── Info.plist                        # LSUIElement=YES，权限描述
├── ClipHistory.entitlements          # 无沙盒
│
├── Models/
│   └── ClipItemType.swift            # 枚举：.text / .image
│
├── Persistence/
│   ├── PersistenceController.swift   # CoreData stack 单例
│   └── ClipHistory.xcdatamodeld/    # CoreData 模型文件
│
├── Services/
│   ├── ClipboardMonitor.swift        # 轮询 + 隐私检测 + CoreData 写入
│   └── RetentionManager.swift       # 定时清理过期记录
│
├── ViewModels/
│   └── ClipHistoryViewModel.swift   # 置顶、删除、粘贴操作
│
├── Views/
│   ├── PopoverRootView.swift         # 根视图：搜索栏 + 卡片列表 + 底栏
│   ├── ClipCardView.swift            # 单条记录卡片（文字/图片）
│   ├── SearchBarView.swift           # 搜索输入框
│   └── SettingsView.swift           # 保留时长设置
│
└── Utilities/
    └── NSImage+Thumbnail.swift       # 图片缩略图扩展
```

---

## 3. CoreData 数据模型

### 实体：ClipItemEntity

| 属性名 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | 自动生成 | 主键 |
| typeRaw | String | — | `"text"` 或 `"image"` |
| content | String? | nil | 文字内容 |
| imageData | Binary Data? | nil | 图片 PNG 数据，启用 Allows External Storage |
| createdAt | Date | 当前时间 | 复制时间戳 |
| isPinned | Boolean | false | 是否置顶 |
| appSource | String? | nil | 来源 App 的 Bundle ID |

### 存储位置
`~/Library/Application Support/ClipHistory/ClipHistory.sqlite`

---

## 4. 剪贴板监听

```
轮询间隔：500ms
QoS 队列：.utility（响应快，不影响系统性能）
比较方式：NSPasteboard.general.changeCount 变化时触发读取
```

### 读取流程
1. 检查 changeCount 是否变化
2. **隐私检测**（见第 5 节），若为敏感内容则跳过
3. 检查是否与最新一条记录内容相同（去重）
4. 检查是否为自身粘贴操作（isSelfPasting 标志）
5. 写入 CoreData
6. 检查是否超过 100 条上限，超出则删除最旧的未置顶记录

---

## 5. 隐私检测（双层）

### 第一层：标准隐藏类型
检查 `NSPasteboard.types` 是否包含 `org.nspasteboard.ConcealedType`。
1Password、Bitwarden、KeePassXC 等遵守此规范的密码管理器会写入此类型。

### 第二层：已知密码管理器 Bundle ID
```swift
let sensitiveApps: Set<String> = [
    "com.agilebits.onepassword7",
    "com.agilebits.onepassword-osx",
    "com.1password.1password",
    "com.bitwarden.desktop",
    "com.lastpass.lastpass",
    "com.apple.keychainaccess",
    "in.sinew.Enpass-Desktop",
    "com.keepassxc.keepassxc",
    "com.dashlane.dashlane",
]
```
检测时机：剪贴板变化时读取 `NSWorkspace.shared.frontmostApplication?.bundleIdentifier`。

---

## 6. 粘贴模拟

点击卡片 → 写入 NSPasteboard → 关闭 Popover → 延迟 150ms 发送 CGEvent Cmd+V

```
需要权限：辅助功能（Accessibility）
首次运行：macOS 自动弹出授权对话框，用户点击"允许"即可
检测函数：AXIsProcessTrusted()
```

---

## 7. 数据排序规则

FetchRequest 的 SortDescriptor 顺序：

```
1. isPinned 降序（置顶记录排最前）
2. createdAt 降序（最新记录排最前）
```

---

## 8. 搜索实现

使用 NSPredicate 过滤，仅对文字类型有效：

```swift
NSPredicate(format: "content CONTAINS[cd] %@", searchText)
// [cd] = 不区分大小写 + 忽略音调符号
```

搜索框为空时：显示所有记录（不附加 predicate）

---

## 9. 保留时长清理

- 保留天数存储于 `UserDefaults`（key: `retentionDays`，默认值: `3`）
- 清理时机：App 启动时 + 每 24 小时执行一次
- 清理规则：删除 `createdAt < 当前时间 - retentionDays` 且 `isPinned == false` 的记录

---

## 10. Info.plist 必需键

| Key | Value | 说明 |
|---|---|---|
| LSUIElement | YES | 隐藏 Dock 图标 |
| NSPasteboardUsageDescription | （用途说明文字） | 剪贴板访问权限 |
| NSAppleEventsUsageDescription | （用途说明文字） | 检测来源 App 权限 |

---

## 11. Entitlements

```xml
<!-- ClipHistory.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
<plist version="1.0">
<dict>
    <!-- 明确关闭沙盒 -->
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```
