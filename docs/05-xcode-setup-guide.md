# Xcode 项目创建指南

> 适合人群：不熟悉 Xcode 的用户  
> 最后更新：2026-06-02

---

## 前提条件

1. 打开 **App Store**，搜索 **Xcode**，点击安装（免费，约 7–10 GB，需要等待）
2. 安装完成后，打开 Xcode 一次，接受许可协议，等待组件安装完毕（约 5 分钟）

---

## 创建项目

1. 打开 Xcode，选择 **Create New Project...**
2. 顶部选择 **macOS** 标签页
3. 选择 **App** 模板，点击 **Next**
4. 填写以下信息：

   | 字段 | 填写内容 |
   |---|---|
   | Product Name | `ClipHistory` |
   | Team | 选你的 Apple ID（点 Add Account 登录） |
   | Organization Identifier | `com.cliphistory`（随意，不影响本地使用） |
   | Bundle Identifier | 自动生成，不用改 |
   | Interface | **SwiftUI** |
   | Language | **Swift** |
   | Storage | **None**（CoreData 我们后面手动添加） |

5. 取消勾选 **Include Tests**
6. 点击 **Next**，选择保存位置：`/Users/你的用户名/Documents/repos/ClipHistory/`
7. 点击 **Create**

---

## 初始配置

### 隐藏 Dock 图标（关键步骤）

1. 左侧文件列表，点击最顶部的 **ClipHistory**（蓝色图标）
2. 在中间区域，点击 **ClipHistory Target**（不是 ClipHistory Project）
3. 点击顶部 **Info** 标签页
4. 在列表末尾，右键点击最后一行，选择 **Add Row**
5. 输入 Key：`Application is agent (UIElement)`，Type 选 **Boolean**，Value 选 **YES**

### 关闭沙盒（关键步骤）

1. 还在 Target 的 **Signing & Capabilities** 标签页
2. 如果看到 **App Sandbox** 一栏，点击右侧的 **−** 按钮删除它
3. 如果没有 App Sandbox，不用管

---

## 添加 CoreData 模型文件

1. 在 Xcode 左侧文件列表，右键 **ClipHistory** 文件夹，选择 **New File...**
2. 选择 **Data Model**（在 Core Data 分类下）
3. 文件名写 `ClipHistory`，点击 **Create**
4. 此时文件列表中出现 `ClipHistory.xcdatamodeld`，这是后续配置数据库结构用的

---

## 第一次运行

1. 按 `Command + R`（或点击左上角的 ▶ 按钮）
2. 如果弹出"ClipHistory 要控制这台电脑"→ 点击 **好** 或 **允许**
3. 等待编译（第一次较慢，约 30–60 秒）
4. 菜单栏右上角出现图标表示成功

---

## 常见问题

**Q：编译时提示"Signing & Capabilities requires a team"**  
A：点击 Xcode 顶部的 ClipHistory Target → Signing & Capabilities → Team 下拉选你的 Apple ID。

**Q：提示 Apple ID 需要双重认证**  
A：在 iPhone 上确认即可，之后 Xcode 会自动创建免费开发者证书。

**Q：提示"Could not find module"**  
A：关闭 Xcode，重新打开项目文件（.xcodeproj），再次编译。

**Q：菜单栏没有出现图标**  
A：检查 `LSUIElement` 是否设置为 `YES`，以及 AppDelegate 是否被正确接入（见 CLAUDE.md 的代码指引）。
