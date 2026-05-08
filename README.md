# Mac Doker — SwiftUI 原生 macOS 应用启动器

一个使用 SwiftUI 构建的原生 macOS 应用启动器，支持磨砂玻璃效果、智能应用扫描和聚类分组视图。

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-native-green) ![License](https://img.shields.io/badge/license-MIT-lightgrey)

---

## ✨ 功能特性

| 功能 | 描述 |
|------|------|
| 🧊 原生磨砂玻璃 UI | 使用 `NSVisualEffectView` 实现 macOS 原生毛玻璃效果 |
| 🔍 智能应用扫描 | 自动扫描 `/Applications`、子目录及 `~/Applications` |
| 🖼️ 真实应用图标 | 多重 fallback 策略加载每个应用的真实图标 |
| 📦 聚类分组视图 | 按分类自动分组，支持折叠/展开 |
| 🔎 快速搜索 | 实时模糊搜索应用名称 |
| ⭐ 收藏置顶 | 收藏常用应用并快速访问 |
| 🔥 使用统计 | 记录并显示应用使用频次 |
| 🏷️ 智能分类 | 自动识别 AI工具 / 开发 / 办公 / 沟通 / 娱乐 / 媒体 / 系统 |
| 🎯 悬停交互 | 悬停卡片显示启动箭头，颜色跟随分类主题 |
| 💾 数据持久化 | UserDefaults 保存状态和设置 |

---

## 📸 视图模式

| 模式 | 图标 | 说明 |
|------|------|------|
| 默认 | ⊞ | 标准图标网格 |
| 大图标 | ⊟ | 更大的图标显示 |
| 紧凑 | ☰ | 列表形式 |
| 聚类 | ▣ | 按分类分组显示 |

---

## 🛠️ 技术栈

- **SwiftUI** — UI 界面
- **AppKit** — NSVisualEffectView 磨砂玻璃、NSWorkspace 应用启动
- **XcodeGen** — 项目文件生成
- **Swift 5.9** — 编程语言

---

## 📁 项目结构

```
MacDoker/
├── project.yml                    # XcodeGen 配置
├── Sources/
│   ├── App/
│   │   ├── main.swift             # 应用入口点
│   │   └── AppDelegate.swift      # AppDelegate
│   ├── Models/
│   │   └── AppInfo.swift          # 数据模型 (AppInfo, AppCategory)
│   ├── ViewModels/
│   │   └── AppStore.swift         # 状态管理 (ObservableObject)
│   ├── Views/
│   │   ├── ContentView.swift      # 主视图
│   │   ├── AppCardView.swift      # 应用卡片（含悬停动效）
│   │   ├── ClusterGroupView.swift # 聚类分组视图
│   │   └── Components.swift       # 搜索栏、分类标签、设置、编辑视图
│   ├── Services/
│   │   └── AppScannerService.swift # 应用扫描 + 图标加载 + 智能分类
│   └── Extensions/
│       └── Extensions.swift       # GlassModifier、VisualEffectBlur、Color(hex:)
└── Resources/
    ├── Info.plist
    └── Assets.xcassets/
```

---

## 🚀 如何运行

### 方法一：XcodeGen（推荐）

```bash
# 安装 XcodeGen（如未安装）
brew install xcodegen

# 生成 Xcode 项目并打开
cd MacDoker
xcodegen generate
open MacDoker.xcodeproj
```

### 方法二：直接命令行构建

```bash
cd MacDoker

# Debug 构建
xcodebuild -project MacDoker.xcodeproj -scheme MacDoker -configuration Debug build

# 运行
open ~/Library/Developer/Xcode/DerivedData/MacDoker-*/Build/Products/Debug/MacDoker.app
```

---

## 📖 使用说明

1. **首次启动**：自动扫描 `/Applications` 及子目录，加载所有应用图标（约 10-30 秒）
2. **搜索**：顶部搜索框实时过滤
3. **分类筛选**：点击分类标签快速筛选
4. **聚类视图**：点击分类标题折叠/展开分组
5. **右键菜单**：打开、收藏、编辑、移除
6. **双击**：打开编辑面板（改名、改分类）
7. **刷新**：点击「刷新」按钮重新扫描

---

## 🧩 图标加载策略

```
1. Info.plist CFBundleIconFile → 直接读取 .icns 文件
        ↓ 失败
2. Info.plist CFBundleIcons（新格式）→ 读取图标文件
        ↓ 失败
3. NSWorkspace.shared.icon(forFile:) → 系统缓存图标
        ↓ 全部统一缩放至 128×128 px
```

---

## 📚 学习要点

1. **SwiftUI MVVM** — `@StateObject` / `@ObservedObject` 数据流
2. **原生集成** — `NSViewRepresentable` 包装 AppKit 组件
3. **磨砂玻璃效果** — `NSVisualEffectView` + `.ultraThinMaterial`
4. **异步图标加载** — `DispatchQueue.global` + 主线程更新
5. **应用扫描** — `FileManager` 遍历 + `Info.plist` 解析
6. **动画** — Spring 动画、悬停状态响应
7. **右键菜单** — `.contextMenu` 修饰器
8. **数据持久化** — `UserDefaults` + `Codable`

---

## License

MIT License © 2026
