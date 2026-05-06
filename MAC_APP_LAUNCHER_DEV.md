# macOS 应用启动器 - 代码级开发文档

> 版本：v1.0.0  
> 最后更新：2026-05-06  
> 技术栈：Electron 28 + HTML/CSS/JS + macOS 原生 API

---

## 目录

1. [项目初始化](#1-项目初始化)
2. [项目结构详解](#2-项目结构详解)
3. [配置文件详解](#3-配置文件详解)
4. [主进程核心代码](#4-主进程核心代码)
5. [渲染进程核心代码](#5-渲染进程核心代码)
6. [IPC 通信协议](#6-ipc-通信协议)
7. [界面层完整代码](#7-界面层完整代码)
8. [UI 组件层代码](#8-ui-组件层代码)
9. [性能优化实现](#9-性能优化实现)
10. [测试指南](#10-测试指南)
11. [打包与发布](#11-打包与发布)
12. [常见问题排查](#12-常见问题排查)

---

## 1. 项目初始化

### 1.1 环境要求

| 组件 | 最低版本 | 推荐版本 | 说明 |
|------|---------|---------|------|
| macOS | 10.15 | 13.0+ | Catalina 及以上 |
| Node.js | 18.x | 22.x | LTS 版本 |
| npm | 9.x | 10.x | 建议使用 npm |
| Xcode Command Line Tools | - | 最新 | `xcode-select --install` |

### 1.2 初始化命令

```bash
# 1. 创建项目目录
mkdir mac-app-launcher && cd mac-app-launcher

# 2. 初始化 npm 项目
npm init -y

# 3. 安装核心依赖
npm install electron@^28.0.0 electron-store@^8.1.0

# 4. 安装开发依赖
npm install -D electron-builder@^24.9.1 concurrently@^9.0.0 wait-on@^7.2.0

# 5. 创建项目目录结构
mkdir -p src/{main,renderer/{css,js,icons},preload} assets
```

### 1.3 package.json 配置

```json
{
  "name": "mac-app-launcher",
  "version": "1.0.0",
  "description": "macOS 应用启动器 - 分类管理、快速启动、频次追踪",
  "main": "src/main/main.js",
  "author": "Mac龙虾",
  "license": "MIT",
  "scripts": {
    "start": "electron .",
    "dev": "electron . --dev",
    "build": "electron-builder --mac",
    "build:dir": "electron-builder --mac --dir",
    "postinstall": "electron-builder install-app-deps"
  },
  "keywords": ["macos", "app-launcher", "electron", "dock"],
  "build": {
    "appId": "com.app-launcher.mac",
    "productName": "App Launcher",
    "directories": {
      "output": "dist",
      "buildResources": "assets"
    },
    "files": [
      "src/**/*",
      "assets/**/*",
      "package.json"
    ],
    "mac": {
      "category": "public.app-category.utilities",
      "target": ["dmg", "zip"],
      "icon": "assets/icon.icns",
      "hardenedRuntime": true,
      "gatekeeperAssess": false,
      "entitlements": "build/entitlements.mac.plist",
      "entitlementsInherit": "build/entitlements.mac.plist"
    },
    "dmg": {
      "title": "App Launcher ${version}",
      "icon": "assets/icon.icns",
      "iconSize": 128,
      "window": { "width": 540, "height": 380 }
    }
  }
}
```

---

## 2. 项目结构详解

```
mac-app-launcher/
├── src/
│   ├── main/                          # 主进程（Node.js 环境）
│   │   ├── main.js                    # Electron 入口文件
│   │   ├── appScanner.js              # 应用扫描核心逻辑
│   │   ├── iconExtractor.js           # macOS 图标提取模块
│   │   ├── appLauncher.js             # 应用启动执行器
│   │   ├── dataStore.js               # 数据持久化管理
│   │   ├── trayManager.js             # 系统托盘管理
│   │   ├── shortcutManager.js         # 全局快捷键管理
│   │   └── windowManager.js           # 窗口生命周期管理
│   │
│   ├── renderer/                      # 渲染进程（浏览器环境）
│   │   ├── index.html                 # 主界面 HTML
│   │   ├── css/
│   │   │   ├── base.css              # 基础样式（重置、变量）
│   │   │   ├── layout.css            # 布局样式（网格、弹性盒）
│   │   │   ├── components.css        # 组件样式（卡片、模态框）
│   │   │   └── animations.css        # 动画样式（过渡、关键帧）
│   │   ├── js/
│   │   │   ├── app.js                # 渲染进程主控制器
│   │   │   ├── state.js              # 状态管理模块
│   │   │   ├── ui/
│   │   │   │   ├── gridRenderer.js   # 网格渲染器
│   │   │   │   ├── tabRenderer.js    # 标签页渲染器
│   │   │   │   ├── modalManager.js   # 模态框管理器
│   │   │   │   ├── contextMenu.js    # 右键菜单
│   │   │   │   └── notification.js   # 通知提示
│   │   │   ├── handlers/
│   │   │   │   ├── dragDrop.js       # 拖放处理
│   │   │   │   ├── search.js         # 搜索过滤
│   │   │   │   ├── sort.js           # 排序逻辑
│   │   │   │   └── ipcBridge.js      # IPC 通信封装
│   │   │   └── utils/
│   │   │       ├── iconMapper.js     # 图标映射表
│   │   │       ├── categoryMapper.js # 分类映射表
│   │   │       └── formatters.js     # 格式化工具
│   │   └── icons/                     # 预置图标（备用）
│   │
│   └── preload/                       # 预加载脚本（隔离上下文）
│       └── preload.js                 # 安全 IPC 桥梁
│
├── assets/
│   ├── icon.icns                      # macOS 应用图标（512x512 转 .icns）
│   ├── icon.png                       # 图标源文件（PNG 格式）
│   └── tray-icon.png                  # 托盘图标（16x16/32x32）
│
├── build/
│   └── entitlements.mac.plist         # macOS 权限声明
│
├── package.json                       # 项目配置
├── electron-builder.json              # 打包配置（可选，可合并到 package.json）
└── README.md                          # 项目说明
```

---

## 3. 配置文件详解

### 3.1 entitlements.mac.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- 读取文件系统权限 -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    
    <!-- 允许读取 Applications 目录 -->
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    
    <!-- 允许执行外部应用（启动其他 .app） -->
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
    
    <!-- 允许脚本执行（AppleScript / open 命令） -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    
    <!-- 允许网络通信 -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- 允许 AppleEvent (macOS 14+ 启动应用必需) -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- 允许访问临时目录（图标转换） -->
    <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
    <array>
        <string>/private/tmp/</string>
    </array>
</dict>
</plist>
```

### 3.2 图标生成指南

```bash
# 将 PNG 转换为 .icns（需要 macOS）
mkdir icon.iconset
sips -z 16 16     icon.png --out icon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out icon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out icon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out icon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out icon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out icon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out icon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out icon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out icon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out icon.iconset/icon_512x512@2x.png

iconutil -c icns icon.iconset -o assets/icon.icns
rm -rf icon.iconset
```

---

## 4. 主进程核心代码

### 4.1 main.js — Electron 入口

```javascript
/**
 * src/main/main.js
 * Electron 主进程入口
 * 负责：窗口创建、生命周期管理、模块初始化
 */

const { app, BrowserWindow, ipcMain, nativeTheme } = require('electron');
const path = require('path');

// 导入核心模块
const WindowManager = require('./windowManager');
const TrayManager = require('./trayManager');
const ShortcutManager = require('./shortcutManager');
const AppScanner = require('./appScanner');
const DataStore = require('./dataStore');

// 全局引用（防止被垃圾回收）
let mainWindow = null;
let tray = null;

/**
 * 创建主窗口
 */
function createMainWindow() {
  mainWindow = WindowManager.createWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    title: '应用启动器',
    show: false, // 先隐藏，加载完成后显示
    webPreferences: {
      preload: path.join(__dirname, '../preload/preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      spellcheck: false,
    },
    frame: true,
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    backgroundColor: '#1a1a2e',
  });

  // 加载界面
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:3000');
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  }

  // 窗口就绪后显示
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // 窗口关闭行为
  mainWindow.on('close', (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide(); // 隐藏到托盘
    }
  });

  return mainWindow;
}

/**
 * 应用就绪
 */
app.whenReady().then(async () => {
  // 初始化数据存储
  await DataStore.init();

  // 创建主窗口
  mainWindow = createMainWindow();

  // 初始化托盘（仅 macOS）
  if (process.platform === 'darwin') {
    tray = TrayManager.createTray(mainWindow);
  }

  // 初始化快捷键
  ShortcutManager.register(mainWindow);

  // 注册 IPC 处理器
  registerIpcHandlers();

  // macOS: 点击 Dock 图标恢复窗口
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    } else {
      mainWindow.show();
    }
  });
});

/**
 * 所有窗口关闭
 */
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

/**
 * 应用退出前
 */
app.on('before-quit', () => {
  app.isQuitting = true;
});

/**
 * 应用退出时清理
 */
app.on('will-quit', () => {
  // 注销所有全局快捷键
  ShortcutManager.unregister();
});

/**
 * 注册 IPC 处理器
 */
function registerIpcHandlers() {
  // 获取应用列表
  ipcMain.handle('apps:scan', async () => {
    try {
      const apps = await AppScanner.scan();
      return { success: true, data: apps };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  // 启动应用
  ipcMain.handle('apps:launch', async (event, appName) => {
    try {
      await AppScanner.launch(appName);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  // 获取应用图标
  ipcMain.handle('apps:getIcon', async (event, appPath) => {
    try {
      const icon = await AppScanner.getIcon(appPath);
      return { success: true, data: icon };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  // 保存数据
  ipcMain.handle('data:save', async (event, key, value) => {
    try {
      await DataStore.set(key, value);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  // 读取数据
  ipcMain.handle('data:get', async (event, key, defaultValue) => {
    try {
      const value = DataStore.get(key, defaultValue);
      return { success: true, data: value };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  // 获取系统信息
  ipcMain.handle('system:info', async () => {
    return {
      platform: process.platform,
      arch: process.arch,
      nodeVersion: process.versions.node,
      electronVersion: process.versions.electron,
    };
  });

  // 窗口控制
  ipcMain.on('window:minimize', () => mainWindow?.minimize());
  ipcMain.on('window:maximize', () => {
    if (mainWindow?.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow?.maximize();
    }
  });
  ipcMain.on('window:close', () => mainWindow?.close());
}
```

### 4.2 appScanner.js — 应用扫描模块

```javascript
/**
 * src/main/appScanner.js
 * 应用扫描核心模块
 * 负责：扫描 /Applications 目录、解析应用信息、启动应用
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

const execAsync = promisify(exec);

// 应用扫描配置
const APP_DIRS = [
  '/Applications',
  '/System/Applications',
  path.join(require('os').homedir(), '/Applications'),
];

/**
 * 扫描所有应用目录
 * @returns {Promise<Array>} 应用列表
 */
async function scan() {
  const allApps = [];
  const seenPaths = new Set();

  for (const dir of APP_DIRS) {
    if (!fs.existsSync(dir)) continue;

    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        if (!entry.isDirectory() || !entry.name.endsWith('.app')) continue;

        const appPath = path.join(dir, entry.name);

        // 去重（同名应用取第一个）
        if (seenPaths.has(entry.name)) continue;
        seenPaths.add(entry.name);

        const appInfo = await parseAppInfo(appPath, entry.name);
        if (appInfo) {
          allApps.push(appInfo);
        }
      }
    } catch (err) {
      console.warn(`扫描目录 ${dir} 失败:`, err.message);
    }
  }

  return allApps;
}

/**
 * 解析应用信息
 * @param {string} appPath - 应用路径
 * @param {string} appName - 应用名称
 * @returns {Promise<Object>} 应用信息对象
 */
async function parseAppInfo(appPath, appName) {
  const infoPlistPath = path.join(appPath, 'Contents', 'Info.plist');

  if (!fs.existsSync(infoPlistPath)) {
    return null;
  }

  try {
    // 使用 plutil 解析 Info.plist
    const { stdout } = await execAsync(
      `plutil -extract CFBundleDisplayName json -o - "${infoPlistPath}" 2>/dev/null || ` +
      `plutil -extract CFBundleName json -o - "${infoPlistPath}" 2>/dev/null`
    );

    const displayName = JSON.parse(stdout.trim()) || appName;

    // 获取图标路径
    const iconPath = await getIconPath(appPath, infoPlistPath);

    return {
      name: displayName,
      path: appPath,
      icon: iconPath,
      size: await getFolderSize(appPath),
      lastModified: fs.statSync(appPath).mtimeMs,
    };
  } catch (err) {
    console.warn(`解析应用 ${appName} 失败:`, err.message);
    return {
      name: appName.replace('.app', ''),
      path: appPath,
      icon: null,
      size: 0,
      lastModified: 0,
    };
  }
}

/**
 * 获取应用图标路径
 * @param {string} appPath - 应用路径
 * @param {string} infoPlistPath - Info.plist 路径
 * @returns {Promise<string|null>} 图标路径
 */
async function getIconPath(appPath, infoPlistPath) {
  try {
    // 尝试获取 CFBundleIconFile
    const { stdout } = await execAsync(
      `plutil -extract CFBundleIconFile json -o - "${infoPlistPath}" 2>/dev/null`
    );
    let iconFile = JSON.parse(stdout.trim());

    if (iconFile) {
      // 确保有 .icns 扩展名
      if (!iconFile.endsWith('.icns')) {
        iconFile += '.icns';
      }
      const iconPath = path.join(appPath, 'Contents', 'Resources', iconFile);
      if (fs.existsSync(iconPath)) {
        return iconPath;
      }
    }

    // 尝试 Assets.car
    const assetsPath = path.join(appPath, 'Contents', 'Resources', 'Assets.car');
    if (fs.existsSync(assetsPath)) {
      return assetsPath;
    }

    // 尝试默认图标
    const defaultIcons = [
      'AppIcon.icns',
      'icon.icns',
      'Icon.icns',
    ];

    for (const icon of defaultIcons) {
      const iconPath = path.join(appPath, 'Contents', 'Resources', icon);
      if (fs.existsSync(iconPath)) {
        return iconPath;
      }
    }

    return null;
  } catch {
    return null;
  }
}

/**
 * 获取文件夹大小
 * @param {string} dirPath - 目录路径
 * @returns {Promise<number>} 大小（字节）
 */
async function getFolderSize(dirPath) {
  try {
    const { stdout } = await execAsync(`du -sk "${dirPath}" 2>/dev/null`);
    return parseInt(stdout.split('\t')[0]) * 1024; // KB 转 bytes
  } catch {
    return 0;
  }
}

/**
 * 启动应用
 * @param {string} appName - 应用名称
 * @returns {Promise<void>}
 */
function launch(appName) {
  return new Promise((resolve, reject) => {
    // 使用 open 命令启动
    exec(`open -a "${appName}"`, (error) => {
      if (error) {
        // 尝试使用 AppleScript
        exec(`osascript -e 'tell application "${appName}" to activate'`, (err2) => {
          if (err2) {
            reject(new Error(`无法启动应用: ${appName}`));
          } else {
            resolve();
          }
        });
      } else {
        resolve();
      }
    });
  });
}

/**
 * 获取应用图标（转换为 base64）
 * @param {string} iconPath - 图标路径
 * @returns {Promise<string|null>} base64 数据 URL
 */
async function getIcon(iconPath) {
  if (!iconPath || !fs.existsSync(iconPath)) {
    return null;
  }

  try {
    // 如果是 .icns 文件，使用 sips 转换为 PNG
    if (iconPath.endsWith('.icns')) {
      const tempPng = path.join(require('os').tmpdir(), `icon_${Date.now()}.png`);
      await execAsync(`sips -s format png "${iconPath}" --out "${tempPng}" 2>/dev/null`);

      const data = fs.readFileSync(tempPng);
      fs.unlinkSync(tempPng);

      return `data:image/png;base64,${data.toString('base64')}`;
    }

    // 其他格式直接读取
    const data = fs.readFileSync(iconPath);
    const ext = path.extname(iconPath).slice(1);
    return `data:image/${ext};base64,${data.toString('base64')}`;
  } catch {
    return null;
  }
}

module.exports = {
  scan,
  launch,
  getIcon,
  parseAppInfo,
};
```

### 4.3 dataStore.js — 数据持久化

```javascript
/**
 * src/main/dataStore.js
 * 数据持久化管理
 * 负责：应用配置、用户偏好、使用统计的存储
 */

const Store = require('electron-store');

// 默认配置
const defaultConfig = {
  // 应用自定义配置（分类、排序、收藏等）
  appCustomizations: {},
  
  // 用户偏好设置
  preferences: {
    viewMode: 'default',     // default | grid | compact
    sortBy: 'name',          // name | category | pinned | usage
    activeCategory: 'all',
    autoStart: false,
    minimizeToTray: true,
  },

  // 使用统计
  usageStats: {},
  
  // 自定义分类
  customCategories: [],
};

let store;

/**
 * 初始化数据存储
 */
function init() {
  store = new Store({
    name: 'app-launcher-data',
    defaults: defaultConfig,
    cwd: require('path').join(
      require('os').homedir(),
      '.config',
      'mac-app-launcher'
    ),
    encryptionKey: 'mac-app-launcher-encryption-key', // 可选加密
  });
}

/**
 * 获取值
 * @param {string} key - 键名（支持点号路径，如 'preferences.viewMode'）
 * @param {*} defaultValue - 默认值
 * @returns {*} 存储的值
 */
function get(key, defaultValue = undefined) {
  return store.get(key, defaultValue);
}

/**
 * 设置值
 * @param {string} key - 键名
 * @param {*} value - 值
 */
function set(key, value) {
  store.set(key, value);
}

/**
 * 删除值
 * @param {string} key - 键名
 */
function remove(key) {
  store.delete(key);
}

/**
 * 获取完整存储
 * @returns {Object} 完整数据
 */
function getAll() {
  return store.store;
}

/**
 * 清空存储
 */
function clear() {
  store.clear();
}

/**
 * 更新使用统计
 * @param {string} appName - 应用名称
 */
function incrementUsage(appName) {
  const stats = store.get('usageStats', {});
  const now = Date.now();
  
  if (!stats[appName]) {
    stats[appName] = {
      count: 0,
      lastUsed: 0,
      history: [], // 最近 30 次使用记录
    };
  }
  
  stats[appName].count += 1;
  stats[appName].lastUsed = now;
  stats[appName].history.unshift({
    timestamp: now,
    action: 'launch',
  });
  
  // 只保留最近 30 条
  if (stats[appName].history.length > 30) {
    stats[appName].history = stats[appName].history.slice(0, 30);
  }
  
  store.set('usageStats', stats);
}

module.exports = {
  init,
  get,
  set,
  remove,
  getAll,
  clear,
  incrementUsage,
};
```

### 4.4 trayManager.js — 系统托盘

```javascript
/**
 * src/main/trayManager.js
 * 系统托盘管理
 * 负责：创建托盘图标、托盘菜单、点击事件处理
 */

const { Tray, Menu, nativeImage, app } = require('electron');
const path = require('path');

let tray = null;

/**
 * 创建系统托盘
 * @param {BrowserWindow} mainWindow - 主窗口引用
 * @returns {Tray} 托盘实例
 */
function createTray(mainWindow) {
  // 创建托盘图标
  const iconPath = path.join(__dirname, '../../assets/tray-icon.png');
  let trayIcon;

  try {
    trayIcon = nativeImage.createFromPath(iconPath);
  } catch {
    // 如果图标文件不存在，使用默认图标
    trayIcon = nativeImage.createEmpty();
  }

  // 调整图标大小
  trayIcon = trayIcon.resize({ width: 16, height: 16 });

  tray = new Tray(trayIcon);
  tray.setToolTip('应用启动器');

  // 构建托盘菜单
  const contextMenu = Menu.buildFromTemplate([
    {
      label: '打开启动器',
      accelerator: 'CmdOrCtrl+O',
      click: () => {
        mainWindow.show();
        mainWindow.focus();
      },
    },
    { type: 'separator' },
    {
      label: '快速启动',
      submenu: buildQuickLaunchMenu(mainWindow),
    },
    { type: 'separator' },
    {
      label: '设置',
      click: () => {
        mainWindow.show();
        mainWindow.focus();
        mainWindow.webContents.send('navigate:settings');
      },
    },
    { type: 'separator' },
    {
      label: '退出',
      accelerator: 'CmdOrCtrl+Q',
      click: () => {
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);

  tray.setContextMenu(contextMenu);

  // 点击托盘图标显示/隐藏窗口
  tray.on('click', () => {
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
      mainWindow.focus();
    }
  });

  return tray;
}

/**
 * 构建快速启动子菜单
 * @param {BrowserWindow} mainWindow
 * @returns {Array} 菜单项数组
 */
function buildQuickLaunchMenu(mainWindow) {
  // 这里可以从存储中读取用户收藏的应用
  // 简化版：返回常用应用
  const quickApps = [
    { name: '微信', id: 'WeChat' },
    { name: 'Chrome', id: 'Google Chrome' },
    { name: '飞书', id: 'Lark' },
  ];

  return quickApps.map(app => ({
    label: app.name,
    click: async () => {
      const { exec } = require('child_process');
      exec(`open -a "${app.id}"`);
    },
  }));
}

/**
 * 更新托盘图标（可选：根据状态变化）
 * @param {string} iconPath - 新图标路径
 */
function updateIcon(iconPath) {
  if (tray) {
    const newIcon = nativeImage.createFromPath(iconPath).resize({ width: 16, height: 16 });
    tray.setImage(newIcon);
  }
}

/**
 * 显示托盘气泡通知
 * @param {string} title - 标题
 * @param {string} body - 内容
 */
function showNotification(title, body) {
  if (tray) {
    // macOS 托盘不支持直接显示气泡，可通过 dock 通知替代
    const { Notification } = require('electron');
    new Notification({ title, body }).show();
  }
}

module.exports = {
  createTray,
  updateIcon,
  showNotification,
};
```

### 4.5 shortcutManager.js — 快捷键管理

```javascript
/**
 * src/main/shortcutManager.js
 * 全局快捷键管理
 * 负责：注册全局快捷键、处理快捷键事件
 */

const { globalShortcut, app } = require('electron');

/**
 * 注册所有快捷键
 * @param {BrowserWindow} mainWindow
 */
function register(mainWindow) {
  // 显示/隐藏主窗口 (Cmd+Shift+A)
  globalShortcut.register('CommandOrControl+Shift+A', () => {
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
      mainWindow.focus();
    }
  });

  // 搜索 (Cmd+F)
  globalShortcut.register('CommandOrControl+F', () => {
    mainWindow.show();
    mainWindow.focus();
    mainWindow.webContents.send('shortcut:focus-search');
  });

  // 刷新应用列表 (Cmd+R)
  globalShortcut.register('CommandOrControl+Shift+R', () => {
    mainWindow.webContents.send('shortcut:refresh-apps');
  });
}

/**
 * 注销所有快捷键
 */
function unregister() {
  globalShortcut.unregisterAll();
}

module.exports = {
  register,
  unregister,
};
```

### 4.6 windowManager.js — 窗口管理

```javascript
/**
 * src/main/windowManager.js
 * 窗口生命周期管理
 * 负责：创建、销毁、恢复窗口
 */

const { BrowserWindow } = require('electron');

/**
 * 创建窗口
 * @param {Object} options - 窗口配置
 * @returns {BrowserWindow}
 */
function createWindow(options = {}) {
  const defaults = {
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    show: false,
    webPreferences: {
      preload: options.preload,
      contextIsolation: true,
      nodeIntegration: false,
    },
    ...options,
  };

  const window = new BrowserWindow(defaults);
  return window;
}

/**
 * 恢复窗口（如果存在则聚焦，否则创建）
 * @param {Function} createFn - 创建窗口的函数
 * @returns {BrowserWindow}
 */
function restoreOrCreateWindow(createFn) {
  const windows = BrowserWindow.getAllWindows();
  
  if (windows.length > 0) {
    const win = windows[0];
    if (win.isMinimized()) {
      win.restore();
    }
    win.focus();
    return win;
  }
  
  return createFn();
}

module.exports = {
  createWindow,
  restoreOrCreateWindow,
};
```

---

## 5. 渲染进程核心代码

### 5.1 preload.js — 预加载脚本

```javascript
/**
 * src/preload/preload.js
 * 预加载脚本 — 安全 IPC 桥梁
 * 在渲染进程加载前执行，暴露安全 API
 */

const { contextBridge, ipcRenderer } = require('electron');

// 暴露安全的 API 到渲染进程
contextBridge.exposeInMainWorld('appLauncherAPI', {
  // 应用操作
  scanApps: () => ipcRenderer.invoke('apps:scan'),
  launchApp: (appName) => ipcRenderer.invoke('apps:launch', appName),
  getAppIcon: (appPath) => ipcRenderer.invoke('apps:getIcon', appPath),
  
  // 数据操作
  saveData: (key, value) => ipcRenderer.invoke('data:save', key, value),
  getData: (key, defaultValue) => ipcRenderer.invoke('data:get', key, defaultValue),
  
  // 系统信息
  getSystemInfo: () => ipcRenderer.invoke('system:info'),
  
  // 窗口控制
  minimizeWindow: () => ipcRenderer.send('window:minimize'),
  maximizeWindow: () => ipcRenderer.send('window:maximize'),
  closeWindow: () => ipcRenderer.send('window:close'),
  
  // 事件监听
  onNavigateSettings: (callback) => {
    ipcRenderer.on('navigate:settings', callback);
  },
  onFocusSearch: (callback) => {
    ipcRenderer.on('shortcut:focus-search', callback);
  },
  onRefreshApps: (callback) => {
    ipcRenderer.on('shortcut:refresh-apps', callback);
  },
});
```

### 5.2 app.js — 渲染进程主控制器

```javascript
/**
 * src/renderer/js/app.js
 * 渲染进程主控制器
 * 负责：初始化、状态同步、事件绑定
 */

// 状态管理
import State from './state.js';

// UI 模块
import GridRenderer from './ui/gridRenderer.js';
import TabRenderer from './ui/tabRenderer.js';
import ModalManager from './ui/modalManager.js';
import ContextMenu from './ui/contextMenu.js';
import Notification from './ui/notification.js';

// 处理器
import DragDropHandler from './handlers/dragDrop.js';
import SearchHandler from './handlers/search.js';
import SortHandler from './handlers/sort.js';
import IPCBridge from './handlers/ipcBridge.js';

class AppController {
  constructor() {
    this.state = new State();
    this.ipc = new IPCBridge();
    this.grid = new GridRenderer(this.state);
    this.tabs = new TabRenderer(this.state);
    this.modal = new ModalManager(this.state);
    this.contextMenu = new ContextMenu(this.state);
    this.notification = new Notification();
    this.dragDrop = new DragDropHandler(this.state);
    this.search = new SearchHandler(this.state);
    this.sort = new SortHandler(this.state);
  }

  /**
   * 初始化应用
   */
  async init() {
    // 绑定快捷键监听
    this.bindShortcutListeners();

    // 加载保存状态
    await this.loadState();

    // 扫描应用
    await this.scanApps();

    // 渲染界面
    this.render();

    // 绑定事件
    this.bindEvents();
  }

  /**
   * 加载保存状态
   */
  async loadState() {
    try {
      const saved = await this.ipc.getData('appState', null);
      if (saved) {
        this.state.restore(saved);
      }
    } catch (err) {
      console.warn('加载状态失败:', err);
    }
  }

  /**
   * 保存状态
   */
  async saveState() {
    try {
      await this.ipc.saveData('appState', this.state.serialize());
    } catch (err) {
      console.warn('保存状态失败:', err);
    }
  }

  /**
   * 扫描应用
   */
  async scanApps() {
    this.notification.show('⏳ 正在扫描应用...');
    
    try {
      const result = await this.ipc.scanApps();
      if (result.success) {
        this.state.setApps(result.data);
        this.render();
        this.notification.show(`✅ 已扫描 ${result.data.length} 个应用`);
      } else {
        this.notification.show('❌ 扫描失败: ' + result.error);
      }
    } catch (err) {
      this.notification.show('❌ 扫描出错: ' + err.message);
    }
  }

  /**
   * 启动应用
   */
  async launchApp(appName) {
    this.notification.show(`🚀 正在启动 ${appName}...`);
    
    try {
      const result = await this.ipc.launchApp(appName);
      if (result.success) {
        // 更新使用频次
        this.state.incrementUsage(appName);
        await this.saveState();
        this.render();
      } else {
        this.notification.show('❌ 启动失败: ' + result.error);
      }
    } catch (err) {
      this.notification.show('❌ 启动出错: ' + err.message);
    }
  }

  /**
   * 渲染界面
   */
  render() {
    this.tabs.render();
    this.grid.render();
  }

  /**
   * 绑定快捷键监听
   */
  bindShortcutListeners() {
    if (window.appLauncherAPI) {
      window.appLauncherAPI.onFocusSearch(() => {
        document.getElementById('searchInput')?.focus();
      });
      
      window.appLauncherAPI.onRefreshApps(() => {
        this.scanApps();
      });
      
      window.appLauncherAPI.onNavigateSettings(() => {
        this.modal.open('settings');
      });
    }
  }

  /**
   * 绑定事件
   */
  bindEvents() {
    // 搜索
    document.getElementById('searchInput')?.addEventListener('input', (e) => {
      this.search.filter(e.target.value);
      this.grid.render();
    });

    // 刷新按钮
    document.getElementById('btnScanApps')?.addEventListener('click', () => {
      this.scanApps();
    });

    // 键盘快捷键
    document.addEventListener('keydown', (e) => {
      if (e.key === '/' && !e.target.matches('input,textarea,select')) {
        e.preventDefault();
        document.getElementById('searchInput')?.focus();
      }
      if (e.key === 'Escape') {
        this.modal.closeAll();
      }
    });
  }
}

// 启动应用
document.addEventListener('DOMContentLoaded', () => {
  const app = new AppController();
  app.init();
  
  // 暴露到全局（调试用）
  window.app = app;
});
```

### 5.3 state.js — 状态管理

```javascript
/**
 * src/renderer/js/state.js
 * 状态管理模块
 * 负责：应用状态、分类状态、用户偏好的管理
 */

export default class State {
  constructor() {
    this.apps = [];
    this.categories = this.getDefaultCategories();
    this.activeCategory = 'all';
    this.sortBy = 'name';
    this.viewMode = 'default';
    this.searchQuery = '';
    this.draggedApp = null;
  }

  /**
   * 获取默认分类
   */
  getDefaultCategories() {
    return [
      { id: 'all', name: '全部', color: 'blue', isSystem: true },
      { id: 'pinned', name: '⭐ 收藏', color: 'yellow', isSystem: true },
      { id: 'dev', name: '开发工具', color: 'blue' },
      { id: 'office', name: '办公效率', color: 'green' },
      { id: 'communication', name: '沟通协作', color: 'teal' },
      { id: 'entertainment', name: '娱乐休闲', color: 'purple' },
      { id: 'ai', name: 'AI 工具', color: 'pink' },
      { id: 'media', name: '媒体创作', color: 'orange' },
      { id: 'system', name: '系统工具', color: 'indigo' },
      { id: 'other', name: '其他', color: 'cyan' },
    ];
  }

  /**
   * 设置应用列表
   */
  setApps(apps) {
    this.apps = apps.map(app => ({
      ...app,
      category: this.guessCategory(app.name),
      pinned: false,
      usageCount: 0,
    }));
  }

  /**
   * 智能猜测分类
   */
  guessCategory(appName) {
    const map = {
      'Xcode': 'dev', 'Android Studio': 'dev', 'Cursor': 'dev',
      'WeChat': 'communication', 'Lark': 'communication', 'QQ': 'communication',
      'Doubao': 'ai', 'Midjourney': 'ai',
      'Adobe Photoshop': 'media', 'Adobe Illustrator': 'media',
      'Chrome': 'system', 'Safari': 'system',
      'Steam': 'entertainment',
    };

    for (const [keyword, category] of Object.entries(map)) {
      if (appName.includes(keyword)) return category;
    }
    return 'other';
  }

  /**
   * 增加使用频次
   */
  incrementUsage(appName) {
    const app = this.apps.find(a => a.name === appName);
    if (app) {
      app.usageCount = (app.usageCount || 0) + 1;
    }
  }

  /**
   * 切换收藏状态
   */
  togglePin(appName) {
    const app = this.apps.find(a => a.name === appName);
    if (app) {
      app.pinned = !app.pinned;
    }
  }

  /**
   * 获取过滤后的应用列表
   */
  getFilteredApps() {
    let apps = [...this.apps];

    // 分类过滤
    if (this.activeCategory === 'pinned') {
      apps = apps.filter(a => a.pinned);
    } else if (this.activeCategory !== 'all') {
      apps = apps.filter(a => a.category === this.activeCategory);
    }

    // 搜索过滤
    if (this.searchQuery) {
      const q = this.searchQuery.toLowerCase();
      apps = apps.filter(a => a.name.toLowerCase().includes(q));
    }

    // 排序
    apps = this.sortApps(apps);

    return apps;
  }

  /**
   * 排序应用
   */
  sortApps(apps) {
    switch (this.sortBy) {
      case 'name':
        return apps.sort((a, b) => a.name.localeCompare(b.name, 'zh'));
      case 'usage':
        return apps.sort((a, b) => (b.usageCount || 0) - (a.usageCount || 0));
      case 'pinned':
        return apps.sort((a, b) => {
          if (a.pinned !== b.pinned) return b.pinned ? 1 : -1;
          return a.name.localeCompare(b.name, 'zh');
        });
      default:
        return apps;
    }
  }

  /**
   * 序列化状态（用于存储）
   */
  serialize() {
    return {
      apps: this.apps.map(a => ({
        name: a.name,
        category: a.category,
        pinned: a.pinned,
        usageCount: a.usageCount,
      })),
      categories: this.categories,
      activeCategory: this.activeCategory,
      sortBy: this.sortBy,
      viewMode: this.viewMode,
    };
  }

  /**
   * 恢复状态
   */
  restore(data) {
    if (data.apps) this.apps = data.apps;
    if (data.categories) this.categories = data.categories;
    if (data.activeCategory) this.activeCategory = data.activeCategory;
    if (data.sortBy) this.sortBy = data.sortBy;
    if (data.viewMode) this.viewMode = data.viewMode;
  }
}
```

### 5.4 ipcBridge.js — IPC 通信封装

```javascript
/**
 * src/renderer/js/handlers/ipcBridge.js
 * IPC 通信封装层
 * 负责：与主进程的安全通信
 */

export default class IPCBridge {
  constructor() {
    this.api = window.appLauncherAPI;
  }

  /**
   * 检查 API 是否可用
   */
  isAvailable() {
    return !!this.api;
  }

  /**
   * 扫描应用
   */
  async scanApps() {
    if (!this.isAvailable()) {
      throw new Error('IPC API 不可用');
    }
    return this.api.scanApps();
  }

  /**
   * 启动应用
   */
  async launchApp(appName) {
    if (!this.isAvailable()) {
      throw new Error('IPC API 不可用');
    }
    return this.api.launchApp(appName);
  }

  /**
   * 获取应用图标
   */
  async getAppIcon(appPath) {
    if (!this.isAvailable()) {
      throw new Error('IPC API 不可用');
    }
    return this.api.getAppIcon(appPath);
  }

  /**
   * 保存数据
   */
  async saveData(key, value) {
    if (!this.isAvailable()) {
      throw new Error('IPC API 不可用');
    }
    return this.api.saveData(key, value);
  }

  /**
   * 读取数据
   */
  async getData(key, defaultValue) {
    if (!this.isAvailable()) {
      throw new Error('IPC API 不可用');
    }
    return this.api.getData(key, defaultValue);
  }

  /**
   * 获取系统信息
   */
  async getSystemInfo() {
    if (!this.isAvailable()) {
      return { platform: 'web', note: '非 Electron 环境' };
    }
    return this.api.getSystemInfo();
  }
}
```

### 5.5 dragDrop.js — 拖放处理

```javascript
/**
 * src/renderer/js/handlers/dragDrop.js
 * 拖放排序处理
 */

export default class DragDropHandler {
  constructor(state) {
    this.state = state;
  }

  /**
   * 绑定拖放事件到卡片
   */
  bindCardEvents(cardElement, appName) {
    cardElement.addEventListener('dragstart', (e) => this.onDragStart(e, appName));
    cardElement.addEventListener('dragover', (e) => this.onDragOver(e));
    cardElement.addEventListener('dragenter', (e) => this.onDragEnter(e));
    cardElement.addEventListener('dragleave', (e) => this.onDragLeave(e));
    cardElement.addEventListener('drop', (e) => this.onDrop(e, appName));
    cardElement.addEventListener('dragend', (e) => this.onDragEnd(e));
  }

  onDragStart(e, appName) {
    this.state.draggedApp = appName;
    e.target.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', appName);
  }

  onDragOver(e) {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
  }

  onDragEnter(e) {
    e.preventDefault();
    const card = e.target.closest('.app-card');
    if (card) card.classList.add('drag-over');
  }

  onDragLeave(e) {
    const card = e.target.closest('.app-card');
    if (card) card.classList.remove('drag-over');
  }

  onDrop(e, targetName) {
    e.preventDefault();
    const card = e.target.closest('.app-card');
    if (card) card.classList.remove('drag-over');

    const draggedName = e.dataTransfer.getData('text/plain');
    if (draggedName && draggedName !== targetName) {
      this.reorderApps(draggedName, targetName);
    }
  }

  onDragEnd(e) {
    e.target.classList.remove('dragging');
    document.querySelectorAll('.drag-over').forEach(el => el.classList.remove('drag-over'));
    this.state.draggedApp = null;
  }

  /**
   * 重新排序应用
   */
  reorderApps(fromName, toName) {
    const fromIdx = this.state.apps.findIndex(a => a.name === fromName);
    const toIdx = this.state.apps.findIndex(a => a.name === toName);

    if (fromIdx > -1 && toIdx > -1) {
      const [moved] = this.state.apps.splice(fromIdx, 1);
      this.state.apps.splice(toIdx, 0, moved);
    }
  }
}
```

### 5.6 gridRenderer.js — 网格渲染器

```javascript
/**
 * src/renderer/js/ui/gridRenderer.js
 * 应用网格渲染器
 * 负责：将应用列表渲染为卡片网格
 */

export default class GridRenderer {
  constructor(state) {
    this.state = state;
  }

  /**
   * 渲染应用网格
   */
  render() {
    const grid = document.getElementById('appGrid');
    if (!grid) return;

    const apps = this.state.getFilteredApps();

    // 更新计数
    const countEl = document.getElementById('appCount');
    if (countEl) {
      countEl.textContent = `共 ${apps.length} 个应用`;
    }

    // 空状态
    if (apps.length === 0) {
      grid.innerHTML = this.renderEmptyState();
      return;
    }

    // 渲染卡片
    grid.innerHTML = apps.map((app, i) => this.renderCard(app, i)).join('');

    // 绑定拖放事件
    this.bindDragDropEvents();
  }

  /**
   * 渲染单个应用卡片
   */
  renderCard(app, index) {
    const usageBadge = app.usageCount > 0
      ? `<div class="app-usage-badge">${app.usageCount}</div>`
      : '';

    return `
      <div class="app-card ${app.pinned ? 'pinned' : ''}"
           data-name="${app.name}"
           draggable="true"
           style="animation-delay: ${index * 0.02}s">
        <span class="app-pin">${app.pinned ? '⭐' : ''}</span>
        <div class="app-icon color-${app.color || 'blue'}">${app.emoji || '📱'}</div>
        <div class="app-name" title="${app.name}">${app.name}</div>
        ${usageBadge}
      </div>
    `;
  }

  /**
   * 渲染空状态
   */
  renderEmptyState() {
    const query = this.state.searchQuery;
    return `
      <div class="empty-state" style="grid-column: 1 / -1">
        <div class="icon">${query ? '🔍' : '📂'}</div>
        <p>${query ? '未找到匹配的应用' : '此分类暂无应用'}</p>
      </div>
    `;
  }

  /**
   * 绑定拖放和交互事件（使用事件委托优化）
   */
  bindDragDropEvents() {
    const grid = document.getElementById('appGrid');
    if (!grid) return;

    // 使用事件委托，绑定到网格容器而非每个卡片
    // 避免大量卡片的性能问题

    // 移除旧的事件监听器（如果存在）
    grid.removeEventListener('click', this._clickHandler);
    grid.removeEventListener('dblclick', this._dblclickHandler);
    grid.removeEventListener('contextmenu', this._contextmenuHandler);

    // 创建处理器并保存引用（用于后续移除）
    this._clickHandler = (e) => {
      const card = e.target.closest('.app-card');
      if (!card) return;

      const appName = card.dataset.name;
      if (e.detail === 1) {
        // 延迟执行，等待双击判断
        this._clickTimer = setTimeout(() => {
          window.app?.launchApp(appName);
        }, 250);
      }
    };

    this._dblclickHandler = (e) => {
      const card = e.target.closest('.app-card');
      if (!card) return;

      const appName = card.dataset.name;
      clearTimeout(this._clickTimer);
      window.app?.modal.open('edit', appName);
    };

    this._contextmenuHandler = (e) => {
      const card = e.target.closest('.app-card');
      if (!card) return;

      e.preventDefault();
      e.stopPropagation();
      const appName = card.dataset.name;
      window.app?.contextMenu.show(e, appName);
    };

    // 绑定事件委托
    grid.addEventListener('click', this._clickHandler);
    grid.addEventListener('dblclick', this._dblclickHandler);
    grid.addEventListener('contextmenu', this._contextmenuHandler);

    // 拖放事件仍需要在每个卡片上绑定（因为 drag 事件不冒泡到事件委托）
    const cards = grid.querySelectorAll('.app-card');
    cards.forEach(card => {
      const appName = card.dataset.name;
      window.app?.dragDrop.bindCardEvents(card, appName);
    });
  }
}
```

---

## 6. IPC 通信协议

### 6.1 主进程 → 渲染进程

| 事件名 | 参数 | 说明 |
|--------|------|------|
| `navigate:settings` | 无 | 导航到设置页面 |
| `shortcut:focus-search` | 无 | 聚焦搜索框 |
| `shortcut:refresh-apps` | 无 | 刷新应用列表 |

### 6.2 渲染进程 → 主进程

| 方法名 | 参数 | 返回值 | 说明 |
|--------|------|--------|------|
| `apps:scan` | 无 | `{success, data: apps[]}` | 扫描应用列表 |
| `apps:launch` | `appName: string` | `{success, error?}` | 启动应用 |
| `apps:getIcon` | `appPath: string` | `{success, data: base64}` | 获取图标 |
| `data:save` | `key, value` | `{success}` | 保存数据 |
| `data:get` | `key, default?` | `{success, data}` | 读取数据 |
| `system:info` | 无 | `{platform, arch, versions}` | 系统信息 |
| `window:minimize` | 无 | 无 | 最小化窗口 |
| `window:maximize` | 无 | 无 | 最大化/还原窗口 |
| `window:close` | 无 | 无 | 关闭窗口 |

### 6.3 数据存储结构

```json
{
  "appCustomizations": {
    "WeChat": { "category": "communication", "pinned": true },
    "Xcode": { "category": "dev", "pinned": false }
  },
  "preferences": {
    "viewMode": "default",
    "sortBy": "usage",
    "activeCategory": "all",
    "autoStart": true,
    "minimizeToTray": true
  },
  "usageStats": {
    "WeChat": {
      "count": 128,
      "lastUsed": 1714982400000,
      "history": [
        { "timestamp": 1714982400000, "action": "launch" }
      ]
    }
  },
  "customCategories": [
    { "id": "cat_1234567890", "name": "我的工具", "color": "red" }
  ]
}
```

---

## 7. 界面层完整代码

### 7.1 index.html — 主界面

```html
<!-- src/renderer/index.html -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="Content-Security-Policy"
      content="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'">
<title>应用启动器</title>
<link rel="stylesheet" href="css/base.css">
<link rel="stylesheet" href="css/layout.css">
<link rel="stylesheet" href="css/components.css">
<link rel="stylesheet" href="css/animations.css">
</head>
<body>
<div class="app-container">
  <!-- Header -->
  <header class="header">
    <div class="header-left">
      <h1><span class="header-icon">🚀</span> 应用启动器</h1>
    </div>
    <div class="search-box" id="searchBox">
      <span class="search-icon">🔍</span>
      <input type="text" id="searchInput" placeholder="搜索应用... (按 / 快速聚焦)" autocomplete="off" maxlength="50">
      <button class="search-clear" id="searchClear" title="清除">×</button>
    </div>
    <div class="header-actions">
      <div class="view-toggle">
        <button class="view-btn active" data-view="default" title="默认视图">⊞</button>
        <button class="view-btn" data-view="grid" title="大图标视图">⊟</button>
        <button class="view-btn" data-view="compact" title="紧凑列表">☰</button>
      </div>
      <button class="btn" id="btnAddCategory" title="新建分类">＋ 分类</button>
      <button class="btn btn-primary" id="btnScanApps" title="刷新应用列表">
        <span class="btn-icon">⟳</span> 刷新
      </button>
      <button class="btn" id="btnSettings" title="设置">⚙</button>
    </div>
  </header>

  <!-- Category Tabs -->
  <nav class="category-tabs" id="categoryTabs"></nav>

  <!-- Sort Bar -->
  <div class="sort-bar">
    <span id="appCount">共 0 个应用</span>
    <div class="sort-options">
      <button class="sort-btn active" data-sort="name">按名称</button>
      <button class="sort-btn" data-sort="category">按分类</button>
      <button class="sort-btn" data-sort="pinned">⭐ 收藏</button>
      <button class="sort-btn" data-sort="usage">🔥 使用频次</button>
    </div>
  </div>

  <!-- Loading State -->
  <div class="loading-overlay" id="loadingOverlay">
    <div class="loading-spinner"></div>
    <p>正在扫描应用...</p>
  </div>

  <!-- App Grid -->
  <main class="app-grid" id="appGrid"></main>
</div>

<!-- Context Menu -->
<div class="context-menu" id="contextMenu">
  <div class="context-item" data-action="open">🚀 打开应用</div>
  <div class="context-item" data-action="pin">⭐ 收藏/取消</div>
  <div class="context-item" data-action="edit">✏️ 编辑</div>
  <div class="context-item" data-action="resetUsage">🔥 重置频次</div>
  <div class="context-divider"></div>
  <div class="context-item" data-action="delete" style="color:#ef5350">🗑️ 移除</div>
</div>

<!-- Notification -->
<div class="notification" id="notification"></div>

<!-- Settings Modal -->
<div class="modal-overlay" id="settingsModal">
  <div class="modal">
    <div class="modal-header">
      <h2>⚙ 设置</h2>
      <button class="modal-close" onclick="document.getElementById('settingsModal').classList.remove('show')">×</button>
    </div>
    <div class="modal-body">
      <div class="setting-group">
        <label class="setting-label">默认视图模式</label>
        <select id="settingViewMode" class="setting-select">
          <option value="default">默认</option>
          <option value="grid">大图标</option>
          <option value="compact">紧凑列表</option>
        </select>
      </div>
      <div class="setting-group">
        <label class="setting-label">默认排序方式</label>
        <select id="settingSortBy" class="setting-select">
          <option value="name">按名称</option>
          <option value="usage">按使用频次</option>
          <option value="pinned">收藏优先</option>
          <option value="category">按分类</option>
        </select>
      </div>
      <div class="setting-group">
        <label class="setting-toggle">
          <input type="checkbox" id="settingAutoStart"> 开机自启
        </label>
      </div>
      <div class="setting-group">
        <label class="setting-toggle">
          <input type="checkbox" id="settingMinimizeToTray" checked> 关闭时最小化到托盘
        </label>
      </div>
      <div class="setting-group">
        <label class="setting-label">数据管理</label>
        <div class="setting-actions">
          <button class="btn" id="btnExportData">📥 导出数据</button>
          <button class="btn btn-danger" id="btnClearData">🗑️ 清除所有数据</button>
        </div>
      </div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-primary" id="btnSaveSettings">保存设置</button>
    </div>
  </div>
</div>

<!-- Add/Edit Category Modal -->
<div class="modal-overlay" id="addCategoryModal">
  <div class="modal">
    <div class="modal-header">
      <h2 id="categoryModalTitle">✨ 新建分类</h2>
      <button class="modal-close" onclick="document.getElementById('addCategoryModal').classList.remove('show')">×</button>
    </div>
    <div class="modal-body">
      <div class="setting-group">
        <label class="setting-label">分类名称</label>
        <input type="text" id="categoryName" placeholder="输入分类名称..." maxlength="20" class="setting-input">
      </div>
      <div class="setting-group">
        <label class="setting-label">颜色</label>
        <div class="color-options" id="colorOptions">
          <span class="color-opt color-blue selected" data-color="blue"></span>
          <span class="color-opt color-green" data-color="green"></span>
          <span class="color-opt color-red" data-color="red"></span>
          <span class="color-opt color-orange" data-color="orange"></span>
          <span class="color-opt color-purple" data-color="purple"></span>
          <span class="color-opt color-pink" data-color="pink"></span>
          <span class="color-opt color-teal" data-color="teal"></span>
          <span class="color-opt color-indigo" data-color="indigo"></span>
          <span class="color-opt color-yellow" data-color="yellow"></span>
          <span class="color-opt color-cyan" data-color="cyan"></span>
        </div>
      </div>
    </div>
    <div class="modal-footer">
      <input type="hidden" id="editingCategoryId">
      <button class="btn" onclick="document.getElementById('addCategoryModal').classList.remove('show')">取消</button>
      <button class="btn btn-primary" id="btnConfirmCategory">创建</button>
    </div>
  </div>
</div>

<script type="module" src="js/app.js"></script>
</body>
</html>
```

### 7.2 CSS 变量与基准样式 (base.css)

```css
/* src/renderer/css/base.css */
*, *::before, *::after {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  /* 颜色系统 */
  --bg-primary: #1a1a2e;
  --bg-secondary: #16213e;
  --bg-card: rgba(255, 255, 255, 0.08);
  --bg-card-hover: rgba(255, 255, 255, 0.15);
  --bg-input: rgba(255, 255, 255, 0.06);
  --bg-overlay: rgba(0, 0, 0, 0.6);
  --text-primary: #e8e8e8;
  --text-secondary: #a0a0b0;
  --text-muted: #6a6a7a;
  --accent: #4fc3f7;
  --accent-hover: #29b6f6;
  --accent-deep: #42a5f5;
  --danger: #ef5350;
  --warning: #ffa726;
  --success: #66bb6a;
  --pin-color: #ffd700;
  --border: rgba(255, 255, 255, 0.1);
  --border-focus: rgba(79, 195, 247, 0.4);
  /* 阴影 */
  --shadow-card: 0 4px 24px rgba(0, 0, 0, 0.3);
  --shadow-modal: 0 8px 40px rgba(0, 0, 0, 0.5);
  --shadow-hover: 0 0 20px rgba(79, 195, 247, 0.15);
  /* 圆角 */
  --radius-xs: 4px;
  --radius-sm: 10px;
  --radius-md: 16px;
  --radius-lg: 24px;
  --radius-full: 50%;
  /* 间距 */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  /* 过渡 */
  --transition-fast: 0.15s ease;
  --transition-normal: 0.25s ease;
  --transition-slow: 0.4s ease;
  /* 字体 */
  --font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  --font-size-xs: 11px;
  --font-size-sm: 13px;
  --font-size-md: 14px;
  --font-size-lg: 16px;
  --font-size-xl: 22px;
  /* 层级 */
  --z-dropdown: 100;
  --z-modal: 200;
  --z-tooltip: 300;
  --z-notification: 400;
}

html {
  font-size: 14px;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

body {
  font-family: var(--font-family);
  background: linear-gradient(135deg, var(--bg-primary) 0%, var(--bg-secondary) 50%, #0a1628 100%);
  color: var(--text-primary);
  min-height: 100vh;
  overflow-x: hidden;
  line-height: 1.5;
}

body::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background:
    radial-gradient(ellipse at 20% 50%, rgba(79, 195, 247, 0.08) 0%, transparent 60%),
    radial-gradient(ellipse at 80% 20%, rgba(129, 212, 250, 0.06) 0%, transparent 50%);
  pointer-events: none;
  z-index: 0;
}

a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }

/* 原生滚动条美化 */
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 3px;
}
::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.25);
}

/* 选中颜色 */
::selection {
  background: rgba(79, 195, 247, 0.3);
  color: #fff;
}
```

### 7.3 布局样式 (layout.css)

```css
/* src/renderer/css/layout.css */
.app-container {
  position: relative;
  z-index: 1;
  padding: 20px;
  max-width: 1400px;
  margin: 0 auto;
}

/* Header */
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 24px;
  margin-bottom: 20px;
  background: var(--bg-card);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: var(--radius-md);
  border: 1px solid var(--border);
}

.header-left {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.header h1 {
  font-size: var(--font-size-xl);
  font-weight: 700;
  background: linear-gradient(135deg, #4fc3f7, #81d4fa);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.header h1 .header-icon {
  -webkit-text-fill-color: initial;
}
```

### 7.4 组件样式 (components.css)

```css
/* src/renderer/css/components.css */
/* 通用按钮 */
.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border-radius: 20px;
  border: 1px solid var(--border);
  background: var(--bg-card);
  color: var(--text-primary);
  cursor: pointer;
  font-size: var(--font-size-sm);
  font-family: inherit;
  transition: all var(--transition-fast);
  white-space: nowrap;
  outline: none;
}
.btn:hover {
  background: var(--bg-card-hover);
  border-color: var(--accent);
}
.btn:active { transform: scale(0.97); }
.btn:focus-visible {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--border-focus);
}

.btn-primary {
  background: linear-gradient(135deg, #4fc3f7, #42a5f5);
  border: none;
  color: #fff;
}
.btn-primary:hover {
  background: linear-gradient(135deg, #29b6f6, #1e88e5);
}

.btn-danger {
  background: var(--danger);
  border: none;
  color: #fff;
}
.btn-danger:hover {
  background: #e53935;
}

.btn-icon { font-size: 16px; }
```

```css
/* 卡片网格 */
.app-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
  gap: var(--spacing-md);
  padding: var(--spacing-xs);
  min-height: 400px;
}

.app-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--spacing-sm);
  padding: 16px 10px 12px;
  border-radius: var(--radius-sm);
  background: var(--bg-card);
  border: 1px solid var(--border);
  cursor: pointer;
  transition: all var(--transition-normal);
  position: relative;
  user-select: none;
  -webkit-user-drag: element;
}

.app-card:hover {
  transform: translateY(-4px) scale(1.03);
  background: var(--bg-card-hover);
  box-shadow: var(--shadow-card), var(--shadow-hover);
  border-color: rgba(79, 195, 247, 0.3);
}

.app-card:active {
  transform: translateY(-2px) scale(0.99);
}

.app-card.dragging {
  opacity: 0.5;
  transform: scale(0.95);
}

.app-card.drag-over {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px var(--accent);
}

.app-icon {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  position: relative;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.2);
  transition: transform var(--transition-fast);
}

.app-card:hover .app-icon {
  transform: scale(1.05);
}

.app-name {
  font-size: var(--font-size-xs);
  text-align: center;
  color: var(--text-secondary);
  line-height: 1.3;
  max-width: 90px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-card:hover .app-name {
  color: var(--text-primary);
}

.app-pin {
  position: absolute;
  top: 6px;
  right: 6px;
  font-size: 10px;
  opacity: 0;
  transition: opacity var(--transition-fast);
}

.app-card:hover .app-pin,
.app-card.pinned .app-pin {
  opacity: 1;
  color: var(--pin-color);
}

.app-usage-badge {
  position: absolute;
  bottom: 4px;
  right: 6px;
  font-size: 9px;
  background: rgba(255, 152, 0, 0.8);
  color: #fff;
  padding: 1px 5px;
  border-radius: 8px;
  font-weight: 600;
  line-height: 1.3;
}
```

```css
/* 模态框通用样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: var(--bg-overlay);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  display: none;
  align-items: center;
  justify-content: center;
  z-index: var(--z-modal);
  animation: fadeIn 0.2s ease;
}

.modal-overlay.show {
  display: flex;
}

.modal {
  background: var(--bg-secondary);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: var(--spacing-lg);
  width: 90%;
  max-width: 500px;
  box-shadow: var(--shadow-modal);
  animation: slideUpIn 0.25s ease;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--spacing-md);
}

.modal-header h2 {
  font-size: var(--font-size-lg);
}

.modal-close {
  background: none;
  border: none;
  color: var(--text-secondary);
  font-size: 20px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: all var(--transition-fast);
}

.modal-close:hover {
  background: var(--bg-card);
  color: var(--text-primary);
}

.modal-body {
  margin-bottom: var(--spacing-md);
}

.modal-footer {
  display: flex;
  gap: var(--spacing-sm);
  justify-content: flex-end;
}

.setting-group {
  margin-bottom: var(--spacing-md);
}

.setting-label {
  display: block;
  font-size: var(--font-size-sm);
  color: var(--text-secondary);
  margin-bottom: 6px;
}

.setting-input,
.setting-select {
  width: 100%;
  padding: 10px 14px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  background: var(--bg-input);
  color: var(--text-primary);
  font-size: var(--font-size-md);
  font-family: inherit;
  outline: none;
  transition: border-color var(--transition-fast);
}

.setting-input:focus,
.setting-select:focus {
  border-color: var(--accent);
}

.setting-toggle {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  cursor: pointer;
  font-size: var(--font-size-md);
}

.setting-toggle input[type="checkbox"] {
  width: 18px;
  height: 18px;
  accent-color: var(--accent);
}

.setting-actions {
  display: flex;
  gap: var(--spacing-sm);
}
```

```css
/* 上下文菜单 */
.context-menu {
  position: fixed;
  background: var(--bg-secondary);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 6px 0;
  min-width: 180px;
  box-shadow: var(--shadow-card);
  z-index: var(--z-dropdown);
  display: none;
  animation: fadeIn 0.15s ease;
}

.context-menu.show {
  display: block;
}

.context-item {
  padding: 8px 16px;
  cursor: pointer;
  font-size: var(--font-size-sm);
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  transition: background var(--transition-fast);
}

.context-item:hover {
  background: var(--bg-card-hover);
}

.context-divider {
  height: 1px;
  background: var(--border);
  margin: 4px 0;
}

/* 通知 */
.notification {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  background: var(--bg-secondary);
  border: 1px solid var(--accent);
  padding: 10px 24px;
  border-radius: 24px;
  font-size: var(--font-size-sm);
  box-shadow: var(--shadow-card);
  z-index: var(--z-notification);
  display: none;
  animation: slideUpIn 0.3s ease;
}

.notification.show {
  display: block;
}

/* 加载遮罩 */
.loading-overlay {
  position: absolute;
  inset: 0;
  background: rgba(26, 26, 46, 0.9);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-md);
  z-index: 10;
  border-radius: var(--radius-md);
}

.loading-overlay p {
  color: var(--text-secondary);
  font-size: var(--font-size-md);
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--accent);
  border-radius: var(--radius-full);
  animation: spin 0.8s linear infinite;
}

/* 颜色主题类 */
.color-blue { background: linear-gradient(135deg, #42a5f5, #1e88e5); }
.color-green { background: linear-gradient(135deg, #66bb6a, #43a047); }
.color-red { background: linear-gradient(135deg, #ef5350, #e53935); }
.color-orange { background: linear-gradient(135deg, #ffa726, #fb8c00); }
.color-purple { background: linear-gradient(135deg, #ab47bc, #8e24aa); }
.color-pink { background: linear-gradient(135deg, #ec407a, #d81b60); }
.color-teal { background: linear-gradient(135deg, #26a69a, #00897b); }
.color-indigo { background: linear-gradient(135deg, #5c6bc0, #3949ab); }
.color-yellow { background: linear-gradient(135deg, #ffee58, #fdd835); }
.color-cyan { background: linear-gradient(135deg, #26c6da, #00acc1); }

.color-opt {
  width: 32px;
  height: 32px;
  border-radius: var(--radius-full);
  cursor: pointer;
  border: 2px solid transparent;
  transition: all var(--transition-fast);
  display: inline-block;
}
.color-opt:hover,
.color-opt.selected {
  border-color: #fff;
  transform: scale(1.15);
}
```

### 7.5 动画样式 (animations.css)

```css
/* src/renderer/css/animations.css */
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes slideUpIn {
  from { opacity: 0; transform: translateX(-50%) translateY(20px); }
  to { opacity: 1; transform: translateX(-50%) translateY(0); }
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@keyframes pulse {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 1; }
}

@keyframes popIn {
  0% { transform: scale(0.8); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}

/* 卡片入场动画 */
.app-card {
  animation: fadeIn 0.3s ease both;
}

.app-card:nth-child(1) { animation-delay: 0.02s; }
.app-card:nth-child(2) { animation-delay: 0.04s; }
.app-card:nth-child(3) { animation-delay: 0.06s; }
.app-card:nth-child(4) { animation-delay: 0.08s; }
.app-card:nth-child(5) { animation-delay: 0.10s; }
.app-card:nth-child(6) { animation-delay: 0.12s; }
.app-card:nth-child(7) { animation-delay: 0.14s; }
.app-card:nth-child(8) { animation-delay: 0.16s; }
.app-card:nth-child(9) { animation-delay: 0.18s; }
.app-card:nth-child(10) { animation-delay: 0.20s; }

/* 减少动画偏好 */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 8. UI 组件层代码

### 8.1 tabRenderer.js — 标签页渲染器

```javascript
/**
 * src/renderer/js/ui/tabRenderer.js
 * 标签页渲染器
 * 负责：渲染分类标签页、处理标签切换
 */

export default class TabRenderer {
  constructor(state) {
    this.state = state;
  }

  /**
   * 渲染分类标签页
   */
  render() {
    const container = document.getElementById('categoryTabs');
    if (!container) return;

    // 计算每个分类的应用数量
    const counts = {};
    this.state.apps.forEach(app => {
      counts[app.category] = (counts[app.category] || 0) + 1;
    });
    counts['all'] = this.state.apps.length;
    counts['pinned'] = this.state.apps.filter(a => a.pinned).length;

    const html = this.state.categories.map(cat => {
      const count = cat.id === 'all'
        ? counts['all']
        : cat.id === 'pinned'
          ? counts['pinned']
          : (counts[cat.id] || 0);
      const isActive = this.state.activeCategory === cat.id;

      return `
        <div class="tab ${isActive ? 'active' : ''}"
             data-cat="${cat.id}"
             title="${cat.name}（${count} 个应用）">
          ${cat.name}
          <span class="count">${count}</span>
        </div>
      `;
    }).join('') + `
      <div class="tab tab-add" title="添加分类" onclick="document.getElementById('addCategoryModal').classList.add('show')">＋</div>
    `;

    container.innerHTML = html;

    // 绑定点击事件
    container.querySelectorAll('.tab[data-cat]').forEach(tab => {
      tab.addEventListener('click', () => {
        this.state.activeCategory = tab.dataset.cat;
        window.app?.saveState();
        window.app?.render();
      });
    });
  }
}
```

### 8.2 modalManager.js — 模态框管理器

```javascript
/**
 * src/renderer/js/ui/modalManager.js
 * 模态框管理器
 * 负责：模态框的打开、关闭、数据传递
 */

export default class ModalManager {
  constructor(state) {
    this.state = state;
  }

  /**
   * 打开指定模态框
   * @param {string} id - 模态框 ID
   * @param {*} data - 传递的数据
   */
  open(id, data = null) {
    const modal = document.getElementById(`${id}Modal`);
    if (!modal) return;

    switch (id) {
      case 'settings':
        this.openSettingsModal(data);
        break;
      case 'addCategory':
        this.openCategoryModal(data);
        break;
      case 'edit':
        this.openEditModal(data);
        break;
      default:
        break;
    }

    modal.classList.add('show');
  }

  /**
   * 关闭所有模态框
   */
  closeAll() {
    document.querySelectorAll('.modal-overlay.show').forEach(m => {
      m.classList.remove('show');
    });
  }

  /**
   * 打开设置模态框（在独立窗口或页面中）
   */
  openSettingsModal(data) {
    const viewMode = document.getElementById('settingViewMode');
    const sortBy = document.getElementById('settingSortBy');
    const autoStart = document.getElementById('settingAutoStart');
    const minimizeToTray = document.getElementById('settingMinimizeToTray');

    if (viewMode) viewMode.value = this.state.viewMode;
    if (sortBy) sortBy.value = this.state.sortBy;
    if (autoStart) autoStart.checked = this.state.autoStart || false;
    if (minimizeToTray) minimizeToTray.checked = this.state.minimizeToTray !== false;

    // 保存设置
    const saveBtn = document.getElementById('btnSaveSettings');
    if (saveBtn) {
      saveBtn.onclick = async () => {
        this.state.viewMode = viewMode?.value || 'default';
        this.state.sortBy = sortBy?.value || 'name';
        
        // 保存到主进程
        if (window.appLauncherAPI) {
          await window.appLauncherAPI.saveData('preferences', {
            viewMode: this.state.viewMode,
            sortBy: this.state.sortBy,
            autoStart: autoStart?.checked || false,
            minimizeToTray: minimizeToTray?.checked || true,
          });
        }

        this.closeAll();
        window.app?.render();
      };
    }
  }

  /**
   * 打开分类编辑模态框
   */
  openCategoryModal(data) {
    const title = document.getElementById('categoryModalTitle');
    const nameInput = document.getElementById('categoryName');
    const idInput = document.getElementById('editingCategoryId');
    const confirmBtn = document.getElementById('btnConfirmCategory');

    if (data) {
      // 编辑模式
      if (title) title.textContent = '📝 编辑分类';
      if (nameInput) nameInput.value = data.name;
      if (idInput) idInput.value = data.id;
      if (confirmBtn) confirmBtn.textContent = '保存';

      // 选中颜色
      document.querySelectorAll('.color-opt').forEach(opt => {
        opt.classList.toggle('selected', opt.dataset.color === data.color);
      });
    } else {
      // 新建模式
      if (title) title.textContent = '✨ 新建分类';
      if (nameInput) nameInput.value = '';
      if (idInput) idInput.value = '';
      if (confirmBtn) confirmBtn.textContent = '创建';
      
      // 重置颜色
      document.querySelectorAll('.color-opt').forEach((opt, i) => {
        opt.classList.toggle('selected', i === 0);
      });
    }

    // 确认按钮
    if (confirmBtn) {
      confirmBtn.onclick = () => {
        const name = nameInput?.value.trim();
        if (!name) return;

        const selectedColor = document.querySelector('.color-opt.selected')?.dataset.color || 'blue';
        const editingId = idInput?.value;

        if (editingId) {
          // 编辑已有分类
          const cat = this.state.categories.find(c => c.id === editingId);
          if (cat) {
            cat.name = name;
            cat.color = selectedColor;
          }
        } else {
          // 创建新分类
          this.state.categories.push({
            id: 'cat_' + Date.now(),
            name,
            color: selectedColor,
          });
        }

        window.app?.saveState();
        this.closeAll();
        window.app?.render();
      };
    }
  }

  /**
   * 打开应用编辑模态框
   */
  openEditModal(appName) {
    const app = this.state.apps.find(a => a.name === appName);
    if (!app) return;

    // 构建分类选项
    const categoryOptions = this.state.categories
      .filter(c => !c.isSystem)
      .map(c => `<option value="${c.id}" ${c.id === app.category ? 'selected' : ''}>${c.name}</option>`)
      .join('');

    const modal = document.createElement('div');
    modal.className = 'modal-overlay show';
    modal.innerHTML = `
      <div class="modal" style="width: 400px;">
        <div class="modal-header">
          <h2>📝 编辑应用</h2>
          <button class="modal-close">×</button>
        </div>
        <div class="modal-body">
          <div class="setting-group">
            <label class="setting-label">应用名称</label>
            <input type="text" class="setting-input" id="editAppName" value="${app.name}">
          </div>
          <div class="setting-group">
            <label class="setting-label">所属分类</label>
            <select class="setting-select" id="editAppCategory">${categoryOptions}</select>
          </div>
          <div class="setting-group">
            <label class="setting-label">${app.pinned ? '⭐ 已收藏' : '☆ 未收藏'}</label>
            <button class="btn" id="btnTogglePin">${app.pinned ? '取消收藏' : '设为收藏'}</button>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-danger" id="btnRemoveApp">🗑️ 移除</button>
          <button class="btn">取消</button>
          <button class="btn btn-primary" id="btnSaveEdit">保存</button>
        </div>
      </div>
    `;

    document.body.appendChild(modal);

    // 关闭按钮
    modal.querySelector('.modal-close').onclick = () => modal.remove();
    modal.querySelector('.btn:last-of-type')?.addEventListener('click', () => {
      modal.remove();
    });

    // 保存
    modal.querySelector('#btnSaveEdit').onclick = () => {
      const newName = modal.querySelector('#editAppName').value.trim();
      const newCat = modal.querySelector('#editAppCategory').value;

      if (newName) app.name = newName;
      app.category = newCat;

      window.app?.saveState();
      modal.remove();
      window.app?.render();
    };

    // 收藏切换
    modal.querySelector('#btnTogglePin').onclick = () => {
      window.app?.togglePin(appName);
      modal.remove();
    };

    // 移除
    modal.querySelector('#btnRemoveApp').onclick = () => {
      if (confirm(`确定移除 "${appName}" 吗？`)) {
        const idx = this.state.apps.findIndex(a => a.name === appName);
        if (idx > -1) {
          this.state.apps.splice(idx, 1);
          window.app?.saveState();
          window.app?.render();
        }
        modal.remove();
      }
    };

    // 点击遮罩关闭
    modal.addEventListener('click', (e) => {
      if (e.target === modal) modal.remove();
    });
  }
}
```

### 8.3 contextMenu.js — 右键菜单

```javascript
/**
 * src/renderer/js/ui/contextMenu.js
 * 右键菜单管理器
 * 负责：菜单定位、显示/隐藏、动作分发
 */

export default class ContextMenu {
  constructor(state) {
    this.state = state;
    this.menu = document.getElementById('contextMenu');
    this.currentApp = null;

    // 全局点击关闭
    document.addEventListener('click', () => this.hide());
    
    // ESC 关闭
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') this.hide();
    });
  }

  /**
   * 显示右键菜单
   * @param {MouseEvent} e - 鼠标事件
   * @param {string} appName - 应用名称
   */
  show(e, appName) {
    e.preventDefault();
    e.stopPropagation();
    
    this.currentApp = appName;

    // 设置菜单位置
    const x = e.clientX;
    const y = e.clientY;
    this.menu.style.left = x + 'px';
    this.menu.style.top = y + 'px';

    // 显示菜单
    this.menu.classList.add('show');

    // 检查边界：超出屏幕则调整
    requestAnimationFrame(() => {
      const rect = this.menu.getBoundingClientRect();
      const winW = window.innerWidth;
      const winH = window.innerHeight;

      if (rect.right > winW - 10) {
        this.menu.style.left = (winW - rect.width - 10) + 'px';
      }
      if (rect.bottom > winH - 10) {
        this.menu.style.top = (winH - rect.height - 10) + 'px';
      }
    });
  }

  /**
   * 隐藏右键菜单
   */
  hide() {
    this.menu?.classList.remove('show');
    this.currentApp = null;
  }
}
```

### 8.4 notification.js — 通知提示

```javascript
/**
 * src/renderer/js/ui/notification.js
 * 通知提示管理器
 * 负责：显示通知消息、自动消失、消息队列
 */

export default class Notification {
  constructor() {
    this.el = document.getElementById('notification');
    this.queue = [];
    this.isShowing = false;
    this.defaultDuration = 2000;
  }

  /**
   * 显示通知
   * @param {string} message - 通知内容
   * @param {Object} options - 配置项
   */
  show(message, options = {}) {
    const { duration = this.defaultDuration, type = 'info' } = options;

    // 如果正在显示，加入队列
    if (this.isShowing) {
      this.queue.push({ message, type, duration });
      return;
    }

    this.display(message, type, duration);
  }

  display(message, type, duration) {
    this.isShowing = true;
    this.el.textContent = message;
    this.el.className = `notification ${type}`;
    this.el.classList.add('show');

    setTimeout(() => {
      this.el.classList.remove('show');
      this.isShowing = false;

      // 处理队列
      if (this.queue.length > 0) {
        const next = this.queue.shift();
        setTimeout(() => this.display(next.message, next.type, next.duration), 300);
      }
    }, duration);
  }
}
```

---

## 9. 性能优化实现

### 9.1 图标懒加载（Intersection Observer）

```javascript
/**
 * src/renderer/js/optimizations/lazyIcons.js
 * 图标懒加载 — 进入视口才渲染图标
 */

let iconObserver = null;

export function setupLazyIcons() {
  iconObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const card = entry.target;
        const appName = card.dataset.name;

        // 请求主进程获取真实图标
        if (window.appLauncherAPI && card.dataset.iconLoaded !== 'true') {
          card.dataset.iconLoaded = 'loading';

          // 获取应用路径并请求图标
          const app = window.app?.state.apps.find(a => a.name === appName);
          if (app?.path) {
            window.appLauncherAPI.getAppIcon(app.path).then(result => {
              if (result.success && result.data) {
                const iconEl = card.querySelector('.app-icon');
                if (iconEl) {
                  iconEl.style.backgroundImage = `url(${result.data})`;
                  card.dataset.iconLoaded = 'true';
                }
              }
            }).catch(() => {
              card.dataset.iconLoaded = 'failed';
            });
          }
        }

        // 停止观察
        iconObserver.unobserve(card);
      }
    });
  }, {
    rootMargin: '100px', // 提前 100px 开始加载
    threshold: 0.01,
  });

  return iconObserver;
}

export function observeCard(cardElement) {
  if (iconObserver) {
    iconObserver.observe(cardElement);
  }
}
```

### 9.2 虚拟滚动（应用 > 100 时启用）

```javascript
/**
 * src/renderer/js/optimizations/virtualGrid.js
 * 虚拟化网格 — 只渲染可见区域的卡片
 */

export default class VirtualGrid {
  constructor(options = {}) {
    this.rowHeight = options.rowHeight || 130;
    this.columnsPerRow = options.columnsPerRow || 8;
    this.bufferRows = options.bufferRows || 3; // 上下各预渲染的行数
    this.container = null;
    this.data = [];
    this.visibleRange = { start: 0, end: 0 };
    this.renderFn = null;
  }

  /**
   * 初始化虚拟化网格
   */
  init(container, data, renderFn) {
    this.container = container;
    this.data = data;
    this.renderFn = renderFn;

    this.container.style.overflowY = 'auto';
    this.container.style.position = 'relative';

    // 创建空白容器（撑开真实高度）
    const totalRows = Math.ceil(data.length / this.columnsPerRow);
    this.container.style.minHeight = `${totalRows * this.rowHeight}px`;

    // 监听滚动
    this.container.addEventListener('scroll', () => this.onScroll());
    window.addEventListener('resize', () => this.updateColumns());
  }

  /**
   * 滚动事件
   */
  onScroll() {
    this.updateColumns();
    this.render();
  }

  /**
   * 更新列数
   */
  updateColumns() {
    if (!this.container) return;
    const containerWidth = this.container.clientWidth;
    // 每列约 110px + 16px 间距
    this.columnsPerRow = Math.max(1, Math.floor(containerWidth / 126));
  }

  /**
   * 计算可见范围
   */
  getVisibleRange() {
    const scrollTop = this.container.scrollTop;
    const viewHeight = this.container.clientHeight;

    const startRow = Math.max(0, Math.floor(scrollTop / this.rowHeight) - this.bufferRows);
    const endRow = Math.min(
      Math.ceil(this.data.length / this.columnsPerRow),
      Math.ceil((scrollTop + viewHeight) / this.rowHeight) + this.bufferRows
    );

    const start = startRow * this.columnsPerRow;
    const end = Math.min(this.data.length, endRow * this.columnsPerRow);

    return { start, end };
  }

  /**
   * 渲染可见项
   */
  render() {
    const range = this.getVisibleRange();

    if (range.start === this.visibleRange.start && range.end === this.visibleRange.end) {
      return; // 范围未变，跳过渲染
    }

    this.visibleRange = range;

    // 只渲染可见部分的数据
    const visibleData = this.data.slice(range.start, range.end);
    const offsetY = Math.floor(range.start / this.columnsPerRow) * this.rowHeight;

    // 调用外部渲染函数，传入可见数据和偏移
    this.renderFn(visibleData, range.start, offsetY);
  }

  /**
   * 销毁
   */
  destroy() {
    if (this.container) {
      this.container.removeEventListener('scroll', this.onScroll);
    }
    window.removeEventListener('resize', this.updateColumns);
  }
}
```

### 9.3 防抖搜索

```javascript
/**
 * src/renderer/js/optimizations/debouncedSearch.js
 */

export function debounce(fn, delay = 200) {
  let timer;
  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => fn.apply(this, args), delay);
  };
}

// 使用示例
import { debounce } from './optimizations/debouncedSearch.js';

const debouncedSearch = debounce((query) => {
  window.app?.search.filter(query);
  window.app?.grid.render();
}, 200);

document.getElementById('searchInput')?.addEventListener('input', (e) => {
  debouncedSearch(e.target.value);
});
```

### 9.4 图标缓存层

```javascript
/**
 * src/main/iconCache.js
 * 主进程图标缓存层
 * 避免重复转换同一个图标的 PNG
 */

class IconCache {
  constructor(maxSize = 200) {
    this.cache = new Map();
    this.maxSize = maxSize;
    this.accessOrder = [];
  }

  get(key) {
    if (!this.cache.has(key)) return null;
    
    // 更新访问顺序
    this.accessOrder = this.accessOrder.filter(k => k !== key);
    this.accessOrder.push(key);
    
    return this.cache.get(key);
  }

  set(key, value) {
    // LRU 淘汰
    if (this.cache.size >= this.maxSize) {
      const oldest = this.accessOrder.shift();
      this.cache.delete(oldest);
    }

    this.cache.set(key, value);
    this.accessOrder.push(key);
  }

  delete(key) {
    this.cache.delete(key);
    this.accessOrder = this.accessOrder.filter(k => k !== key);
  }

  clear() {
    this.cache.clear();
    this.accessOrder = [];
  }
}

module.exports = new IconCache();
```

---

## 10. 测试指南

### 10.1 单元测试

```javascript
/**
 * test/state.test.js
 * 状态管理模块测试示例
 */

// 安装测试框架
// npm install -D jest @babel/core @babel/preset-env

import State from '../src/renderer/js/state.js';

describe('State', () => {
  let state;

  beforeEach(() => {
    state = new State();
  });

  test('默认状态初始化', () => {
    expect(state.apps).toEqual([]);
    expect(state.activeCategory).toBe('all');
    expect(state.sortBy).toBe('name');
    expect(state.viewMode).toBe('default');
    expect(state.categories.length).toBeGreaterThan(0);
  });

  test('设置应用列表', () => {
    const apps = [
      { name: 'WeChat', path: '/Applications/WeChat.app' },
      { name: 'Safari', path: '/Applications/Safari.app' },
    ];
    state.setApps(apps);
    expect(state.apps).toHaveLength(2);
    expect(state.apps[0].category).toBe('communication');
    expect(state.apps[1].category).toBe('system');
  });

  test('智能猜测分类', () => {
    expect(state.guessCategory('Xcode')).toBe('dev');
    expect(state.guessCategory('Google Chrome')).toBe('system');
    expect(state.guessCategory('unknownApp')).toBe('other');
  });

  test('增加使用频次', () => {
    state.apps = [{ name: 'WeChat', usageCount: 5 }];
    state.incrementUsage('WeChat');
    expect(state.apps[0].usageCount).toBe(6);
  });

  test('使用频次排序', () => {
    state.apps = [
      { name: 'A', usageCount: 1 },
      { name: 'B', usageCount: 10 },
      { name: 'C', usageCount: 5 },
    ];
    state.sortBy = 'usage';
    const sorted = state.getFilteredApps();
    expect(sorted[0].name).toBe('B');
    expect(sorted[1].name).toBe('C');
    expect(sorted[2].name).toBe('A');
  });

  test('收藏排序优先', () => {
    state.apps = [
      { name: 'A', pinned: false },
      { name: 'B', pinned: true },
      { name: 'C', pinned: false },
    ];
    state.sortBy = 'pinned';
    const sorted = state.getFilteredApps();
    expect(sorted[0].name).toBe('B');
  });

  test('序列化和恢复', () => {
    state.apps = [{ name: 'WeChat', category: 'communication', pinned: true, usageCount: 42 }];
    state.activeCategory = 'communication';
    state.sortBy = 'usage';

    const serialized = state.serialize();
    const newState = new State();
    newState.restore(serialized);

    expect(newState.apps[0].name).toBe('WeChat');
    expect(newState.activeCategory).toBe('communication');
    expect(newState.sortBy).toBe('usage');
  });
});
```

### 10.2 集成测试

```javascript
/**
 * test/ipc.test.js
 * IPC 通信测试示例
 */

// 注意：需要 Spectron 或 electron-mocha 运行时

describe('IPC 通信', () => {
  test('apps:scan 返回正确格式', async () => {
    const result = await ipcRenderer.invoke('apps:scan');
    expect(result).toHaveProperty('success');
    expect(result).toHaveProperty('data');
    expect(Array.isArray(result.data)).toBe(true);
  });

  test('apps:launch 处理无效应用', async () => {
    const result = await ipcRenderer.invoke('apps:launch', '__non_existent_app__');
    expect(result.success).toBe(false);
    expect(result.error).toBeDefined();
  });

  test('data:save 和 data:get 往返', async () => {
    const testValue = { foo: 'bar', num: 42 };
    await ipcRenderer.invoke('data:save', 'testKey', testValue);
    const result = await ipcRenderer.invoke('data:get', 'testKey');
    expect(result.success).toBe(true);
    expect(result.data).toEqual(testValue);
  });
});
```

### 10.3 手动功能测试清单

```markdown
# 功能测试清单

## 基础功能
- [ ] 应用扫描：刷新按钮可正确扫描 /Applications
- [ ] 应用启动：点击应用可正常启动
- [ ] 应用图标：正确显示应用图标
- [ ] 搜索过滤：输入关键词可正确过滤
- [ ] 分类切换：点击各分类标签正确显示

## 交互功能
- [ ] 拖放排序：拖拽应用可正确排序
- [ ] 右键菜单：右键显示菜单，各选项可正常执行
- [ ] 双击编辑：双击打开编辑面板
- [ ] 通知提示：操作后显示通知

## 数据功能
- [ ] 频次统计：启动应用后频次正确累加
- [ ] 收藏功能：收藏后出现在收藏分类中
- [ ] 数据持久化：重启后配置正确恢复

## 视图模式
- [ ] 默认视图：正常显示
- [ ] 大图标视图：图标正确放大
- [ ] 紧凑视图：列表模式正常

## 快捷键
- [ ] Cmd+Shift+A：显示/隐藏窗口
- [ ] Cmd+F：聚焦搜索框
- [ ] / 键：聚焦搜索框
- [ ] ESC：关闭模态框
```

---

## 11. 打包与发布

### 7.1 构建命令

```bash
# 开发模式运行
npm run dev

# 构建 DMG（推荐）
npm run build

# 构建目录（不打包，用于调试）
npm run build:dir
```

### 7.2 输出文件

```
dist/
├── mac-app-launcher-1.0.0.dmg     # macOS 安装包
├── mac-app-launcher-1.0.0.zip     # 压缩包
└── mac-unpacked/                  # 未打包目录
    └── App Launcher.app/
        └── Contents/
            ├── MacOS/
            │   ── App Launcher
            ├── Resources/
            │   ├── app.asar
            │   └── icon.icns
            ── Info.plist
```

### 7.3 DMG 安装体验

用户下载 DMG 后：
1. 双击打开 DMG
2. 拖拽 App Launcher.app 到 Applications 文件夹
3. 双击打开（首次需右键"打开"以绕过 Gatekeeper）

---

## 8. 常见问题排查

### 8.1 应用图标不显示

**原因**：macOS 12+ 部分应用使用 Assets.car 存储图标

**解决方案**：
```javascript
// 使用第三方库提取 Assets.car
npm install assetcatalog
```

### 8.2 应用启动失败

**原因**：应用名称包含特殊字符或路径不正确

**解决方案**：
```javascript
// 使用 Bundle ID 启动（更可靠）
function launchByBundleId(bundleId) {
  const { exec } = require('child_process');
  exec(`open -b "${bundleId}"`);
}
```

### 8.3 托盘图标不显示

**原因**：图标路径错误或格式不支持

**解决方案**：
```javascript
// 确保使用 PNG 格式，且尺寸正确
const icon = nativeImage.createFromPath('assets/tray-icon.png');
console.log(icon.isEmpty()); // 应为 false
```

### 8.4 权限问题（macOS 13+）

**原因**：沙箱限制应用扫描

**解决方案**：
1. 在 `entitlements.mac.plist` 中添加权限
2. 使用用户选择的目录扫描
3. 提示用户授权

### 8.5 内存占用过高

**优化方案**：
```javascript
// 1. 图标懒加载
// 2. 虚拟列表（应用数量 > 100 时）
// 3. 及时释放不用的引用
BrowserWindow.getAllWindows().forEach(win => {
  if (win.isDestroyed()) return;
  win.webContents.on('render-process-gone', () => {
    win.reload();
  });
});
```

---

## 附录 A：.gitignore 配置

```gitignore
# Node
node_modules/
npm-debug.log*

# Electron 构建输出
dist/
out/

# macOS 文件
.DS_Store
*.icns
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# 环境变量
.env
.env.local

# 调试日志
*.log

# 缓存
.cache/
tmp/
```

## 附录 B：CI/CD 自动化构建

```yaml
# .github/workflows/build.yml
name: Build macOS App

on:
  push:
    branches: [main]
    tags:
      - 'v*'
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build Electron app
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: npm run build

      - name: Upload DMG artifact
        uses: actions/upload-artifact@v4
        with:
          name: mac-app-launcher
          path: dist/*.dmg

      - name: Create Release (tags only)
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*.dmg
          generate_release_notes: true
```

## 附录 C：应用分类映射表

```javascript
const CATEGORY_MAPPING = {
  // 开发工具
  dev: ['Xcode', 'Android Studio', 'Cursor', 'TRAE', 'VS Code', 'WebStorm', 'IntelliJ'],
  
  // 办公效率
  office: ['WPS', 'Word', 'Excel', 'TencentDocs', 'MailMaster', '有道云笔记', '移动办公'],
  
  // 沟通协作
  communication: ['WeChat', 'Lark', 'QQ', 'TencentMeeting', '钉钉', 'Slack', 'Teams'],
  
  // AI 工具
  ai: ['Doubao', 'Midjourney', 'ima.copilot', 'pixcake', 'WorkBuddy', 'ChatGPT'],
  
  // 媒体创作
  media: ['Adobe Photoshop', 'Adobe Illustrator', 'Adobe Lightroom', 'GarageBand', 'VideoFusion', 'Final Cut'],
  
  // 娱乐休闲
  entertainment: ['Steam', '小丑牌', 'NeteaseMusic', '汽水音乐', '微信读书', 'CloudVideo'],
  
  // 系统工具
  system: ['Chrome', 'Safari', '360', 'Quark', 'ToDesk', 'UUBooster', 'Utilities'],
  
  // 其他
  other: [], // 默认分类
};
```

## 附录 D：图标 Emoji 映射表

```javascript
const ICON_EMOJI_MAP = {
  'WeChat': '', 'QQ': '💬', 'Lark': '💬',
  'Chrome': '🌐', 'Safari': '',
  'Xcode': '🛠️', 'Cursor': '💻',
  'Doubao': '🤖', 'Midjourney': '🎨',
  'Steam': '🎮', 'GarageBand': '🎵',
  'Photoshop': '🖌️', 'Illustrator': '🎨',
  'WPS': '📝', 'Excel': '📊',
  // ... 更多映射
};
```

---

> 文档结束。如需补充特定模块的详细实现，请告知具体需求。
