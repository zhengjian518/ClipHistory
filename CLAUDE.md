# CLAUDE.md — ClipHistory 项目工作指引

> 本文件供 Claude AI 在每次会话开始时阅读，以保持上下文连贯。  
> 人工也可参考此文件了解项目整体状态。

---

## 项目简介

**ClipHistory** — macOS 菜单栏剪贴板历史管理工具  
- 记录复制的文字和图片，支持保留 1/3/5 天，最多 100 条
- 功能：置顶、删除、点击粘贴、搜索
- 纯原生 Swift + SwiftUI + CoreData，无第三方依赖

---

## 标准文件路径索引

| 文件 | 路径 | 用途 |
|---|---|---|
| 产品需求 | `docs/01-requirements.md` | 功能边界、非功能需求、v1.0 范围 |
| 技术规范 | `docs/02-tech-spec.md` | 技术选型、文件结构、CoreData 模型、API 细节 |
| 设计规范 | `docs/03-design-spec.md` | 配色、布局尺寸、卡片样式、字体规范 |
| 开发阶段 | `docs/04-dev-phases.md` | 10 个 Phase 的目标、文件清单、验收标准 |
| Xcode 指南 | `docs/05-xcode-setup-guide.md` | 面向非技术用户的 Xcode 创建和配置步骤 |
| 开发日志 | `devlog/YYYY-MM-DD.md` | 每日完成事项和待办，按日期命名 |

---

## 当前开发状态

> 每次开始工作前，先读最新的 devlog 文件了解上次进度。

**当前阶段**：Phase 9（UI 打磨）— 已完成，下一步 Phase 10（打包发布）  
**最新日志**：`devlog/2026-06-04.md`

---

## 工作规则

### 开始每次会话时
1. 读最新的 `devlog/` 文件，了解上次做到哪里
2. 确认当前处于哪个 Phase（见 `docs/04-dev-phases.md`）
3. 只处理当前 Phase 的任务，不跨 Phase 开发

### 写代码时
- 技术决策参考 `docs/02-tech-spec.md`，不自行发明新方案
- UI 尺寸、颜色参考 `docs/03-design-spec.md`
- 每个文件的职责参考技术规范中的文件结构表，不随意新增文件
- 默认不写注释，除非逻辑非常不直观

### 结束每次会话时
- 更新或新建当天的 `devlog/YYYY-MM-DD.md`
- 记录：完成了什么、遇到了什么问题、下次要做什么
- 如果修改了技术方案或设计，同步更新对应 docs/ 文件

### 遇到问题时
- 优先查阅 docs/ 文档，确认是否已有规范
- 如需修改规范，先告知用户，确认后再改文档和代码
- 不要绕过验收标准直接进入下一 Phase

---

## 项目目录结构

```
ClipHistory/                     # 仓库根目录（原 历史粘贴板，已改英文名）
├── CLAUDE.md                    # 本文件，工作指引
├── docs/                        # 标准文档
│   ├── 01-requirements.md
│   ├── 02-tech-spec.md
│   ├── 03-design-spec.md
│   ├── 04-dev-phases.md
│   └── 05-xcode-setup-guide.md
├── devlog/                      # 每日开发日志
│   └── 2026-06-02.md
└── ClipHistory/                 # Xcode 项目（Phase 1 开始后创建）
    └── ClipHistory.xcodeproj
```

---

## 关键技术决策备忘

| 问题 | 决策 | 原因 |
|---|---|---|
| 为何不用沙盒 | 关闭 App Sandbox | 需要访问辅助功能（CGEvent）和剪贴板来源信息 |
| 为何用 CoreData 而非 SQLite | CoreData | SwiftUI FetchRequest 集成，原生支持二进制图片 |
| 为何轮询而非推送 | 500ms 轮询 | macOS 不提供剪贴板变化推送通知 |
| 粘贴如何实现 | CGEvent Cmd+V | 可作用于任何前台 App，只需辅助功能权限 |
| 首次运行需要什么权限 | 辅助功能（Accessibility） | 系统自动弹出授权对话框，用户点允许即可 |
