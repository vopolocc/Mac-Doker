# macOS 应用启动器 - 建设计划

## 项目概述

构建一个类似 DockThings 的原生 macOS 桌面应用，用于对 Mac 上的应用进行分类管理、快速启动和使用频次追踪。

---

## 技术选型

### 方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **Electron** | 跨平台、成熟生态、HTML/CSS/JS 开发 | 包体较大、内存占用高 | ⭐⭐⭐ |
| **Tauri** | 包体小、性能高、Rust 后端安全 | 学习曲线较陡 | ⭐⭐⭐⭐ |
| **Swift/SwiftUI** | 原生性能、系统集成度高 | 仅 macOS、开发成本高 | ⭐⭐⭐ |
| **React Native for Desktop** | 组件化、跨平台 | macOS 支持较新、生态不如 Electron | ⭐⭐⭐ |

**推荐方案：Electron**
- 理由：可复用已有 HTML 代码，开发周期短，打包后可直接双击运行
- 用户可直接在 Mac 上安装使用，支持拖拽、右键、快捷键等桌面交互

---

## 核心功能规划

### Phase 1：基础框架（MVP）
- [x] 应用列表扫描（读取 `/Applications/` 目录）
- [x] 应用图标获取（macOS 文件系统 API）
- [x] 分类管理（增删改查分类）
- [x] 应用拖放排序
- [ ] 真正的应用启动能力（`open -a "应用名"` 或 Applescript）

### Phase 2：交互优化
- [x] 收藏/取消收藏功能
- [x] 右键菜单操作
- [x] 搜索过滤
- [x] 三种视图切换（默认/大图标/紧凑列表）
- [ ] 快捷键支持（Cmd+F 搜索、Cmd+, 设置等）
- [ ] 托盘/菜单栏常驻

### Phase 3：数据统计
- [x] 使用频次统计（本地存储）
- [x] 按频次排序
- [x] 频次重置
- [ ] 使用热力图/时间分布分析
- [ ] 数据导出

### Phase 4：高级功能
- [ ] 启动 DockThings 风格浮动停靠栏
- [ ] 多显示器支持
- [ ] 自动分组（AI 智能分类）
- [ ] 启动历史记录
- [ ] 开机自启
- [ ] 自定义主题/配色

---

## 项目结构（Electron）

```
mac-app-launcher/
├── src/
│   ├── main/
│   │   ├── main.js          # Electron 主进程
│   │   ├── appScanner.js     # 应用扫描模块
│   │   ├── windowManager.js  # 窗口管理
│   │   └── ipcHandlers.js    # IPC 通信处理
│   ├── renderer/
│   │   ├── index.html        # 主界面 HTML
│   │   ├── css/
│   │   │   └── styles.css    # 样式
│   │   ├── js/
│   │   │   ├── app.js        # 渲染进程主逻辑
│   │   │   ├── components/   # 可复用组件
│   │   │   └── utils/        # 工具函数
│   │   └── icons/            # 应用图标缓存
│   └── preload/
│       └── preload.js        # 预加载脚本（安全 IPC）
├── assets/
│   ├── icon.icns             # macOS 应用图标
│   └── tray-icon.png         # 托盘图标
├── package.json
├── electron-builder.json     # 打包配置
└── README.md
```

---

## 关键技术实现

### 1. 应用扫描（macOS 原生 API）

```javascript
// src/main/appScanner.js
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function scanApplications() {
  const appsDir = '/Applications';
  const apps = [];
  
  // 扫描 /Applications 目录
  const entries = fs.readdirSync(appsDir, { withFileTypes: true });
  
  for (const entry of entries) {
    if (entry.isDirectory() && entry.name.endsWith('.app')) {
      const appPath = path.join(appsDir, entry.name);
      // 获取应用图标、名称、分类等信息
      const appInfo = parseAppInfo(appPath);
      apps.push(appInfo);
    }
  }
  
  return apps;
}
```

### 2. 应用启动

```javascript
// 方案一：使用 child_process
function launchApp(appName) {
  exec(`open -a "${appName}"`);
}

// 方案二：使用 AppleScript（更强大）
function launchAppWithAppleScript(appName) {
  exec(`osascript -e 'tell application "${appName}" to activate'`);
}
```

### 3. 图标提取

```javascript
// 使用 macOS 的 API 提取应用图标
function extractAppIcon(appPath) {
  // 使用 tiffutil 或 sips 提取图标
  const iconPath = path.join(appPath, 'Contents/Resources/AppIcon.icns');
  // 转换为 PNG 或 base64
  return iconPath;
}
```

### 4. 托盘常驻

```javascript
// src/main/main.js
const { Tray, Menu, nativeImage } = require('electron');

function createTray() {
  const trayIcon = nativeImage.createFromPath('assets/tray-icon.png');
  tray = new Tray(trayIcon);
  
  const contextMenu = Menu.buildFromTemplate([
    { label: '打开启动器', click: () => showMainWindow() },
    { label: '退出', click: () => app.quit() }
  ]);
  
  tray.setToolTip('应用启动器');
  tray.setContextMenu(contextMenu);
}
```

---

## 开发里程碑

### Week 1：项目搭建
- 初始化 Electron 项目
- 搭建项目目录结构
- 集成现有 HTML 界面
- 实现基础 IPC 通信

### Week 2：核心功能开发
- 实现应用扫描模块
- 实现应用启动功能
- 实现图标提取
- 数据持久化（JSON/SQLite）

### Week 3：交互优化
- 添加系统托盘
- 添加快捷键支持
- 优化动画和过渡效果
- 添加加载状态和错误处理

### Week 4：测试与发布
- 功能测试
- 性能优化
- 打包配置（macOS DMG/ZIP）
- 文档编写

---

## 依赖清单

```json
{
  "dependencies": {
    "electron": "^28.0.0",
    "electron-store": "^8.0.0",
    "systeminformation": "^5.0.0"
  },
  "devDependencies": {
    "electron-builder": "^24.0.0",
    "electron-packager": "^17.0.0"
  }
}
```

---

## 打包与发布

### macOS 打包配置

```json
{
  "appId": "com.app-launcher.mac",
  "mac": {
    "category": "public.app-category.utilities",
    "target": ["dmg", "zip"],
    "icon": "assets/icon.icns",
    "hardenedRuntime": true,
    "gatekeeperAssess": false
  },
  "dmg": {
    "title": "App Launcher",
    "icon": "assets/icon.icns",
    "window": { "width": 540, "height": 380 }
  }
}
```

### 签名与公证（可选）
- 申请 Apple Developer ID
- 使用 `codesign` 对应用签名
- 提交到 Apple 进行公证

---

## 已知挑战与解决方案

| 挑战 | 解决方案 |
|------|----------|
| 应用图标提取 | 使用 macOS 原生 API `NSWorkspace` 提取图标 |
| 后台常驻 | 使用 Electron Tray API + 最小化到托盘 |
| 权限问题 | macOS 10.15+ 需要用户授权应用扫描 |
| 性能优化 | 图标缓存、虚拟列表、按需加载 |
| 包体积 | 使用 asar 打包、按需加载依赖 |

---

## 下一步行动

1. **立即执行**：将现有 HTML 项目改造为 Electron 项目
2. **核心优先**：实现应用启动功能和图标提取
3. **后续迭代**：添加托盘常驻、快捷键、开机自启等高级功能
