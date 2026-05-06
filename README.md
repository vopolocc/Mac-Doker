<div align="center">

# 🚀 Mac Doker

**A smart macOS application launcher with categorization, frequency tracking, and instant access**

[![macOS](https://img.shields.io/badge/platform-macOS-black?logo=apple)](https://github.com/vopolocc/Mac-Doker)
[![Electron](https://img.shields.io/badge/Electron-28-blue?logo=electron)](https://www.electronjs.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 😩 The Problem

macOS has no built-in way to **organize and quickly find** applications when you have dozens installed. The pain points are real:

| Pain Point | Description |
|---|---|
| **🔍 Hard to find apps** | Launchpad shows all apps in a flat grid — no grouping, no categories. When you have 50+ apps, finding the right one is a chore. |
| **📂 No categorization** | macOS provides no native way to group apps by purpose (dev tools, communication, media, etc.). Everything is dumped together. |
| **📊 No usage insights** | You don't know which apps you actually use most. No frequency data, no launch history — just a static list. |
| **🖱️ Inefficient access** | Dock space is limited. Spotlight search requires typing the exact name. Alfred/Raycast are overkill for simple app launching. |
| **🔄 No custom ordering** | You can't reorder apps the way YOU want. No drag-and-drop, no pinning favorites, no "most used first" sorting. |
| **🧩 No extensibility** | Can't create custom categories, can't assign apps to multiple groups, can't customize the view. |

**Bottom line:** When your Mac has 40+ apps, finding and launching the right one wastes time every single day.

---

## ✅ The Solution

**Mac Doker** is a native macOS application launcher that solves these problems with:

### 🗂️ Smart Categorization
- **Pre-built categories**: Dev Tools, Office, Communication, AI Tools, Media, Entertainment, System Utilities
- **Auto-classification**: Apps are intelligently sorted into categories on first scan
- **Custom categories**: Create your own groups with custom names and color themes
- **One-click switching**: Instantly filter by any category via tab navigation

### 🔥 Usage Frequency Tracking
- **Automatic counting**: Every app launch is tracked — no manual input needed
- **Frequency sorting**: Sort by usage count to surface your most-used apps instantly
- **Visual badges**: Orange badge on each app shows launch count at a glance
- **Reset per-app**: Right-click any app to reset its frequency counter

### ⚡ Instant Access
- **Click to launch**: Single click opens the app via native macOS `open -a` command
- **Global hotkey**: `Cmd+Shift+A` to show/hide the launcher from anywhere
- **System tray**: Minimizes to menu bar — always one click away
- **Quick search**: `Cmd+Shift+F` or `/` to jump straight to search

### 🎨 Flexible Views & Sorting
- **3 view modes**: Default grid, large icons, compact list
- **4 sort options**: By name, by category, pinned first, by usage frequency
- **Drag-and-drop reorder**: Arrange apps in any order you want
- **Pin favorites**: Star important apps for quick access in the ⭐ tab

### 🖱️ Context Menu Actions
- **Right-click any app** for: Open, Pin/Unpin, Edit, Reset Frequency, Remove
- **Double-click** to open the edit panel (rename, change category)

---

## 🌟 Highlights

| Feature | Why It Matters |
|---|---|
| **Real app launching** | Uses native `open -a` + AppleScript fallback — apps actually open, not just a demo |
| **Native macOS integration** | System tray, Dock icon, global shortcuts, menu bar — feels like a real Mac app |
| **Real app icons** | Extracts `.icns` icons from each app's `Info.plist` and converts to PNG via `sips` |
| **Persists everything** | All categories, pins, usage stats, and preferences survive app restarts (electron-store) |
| **Event delegation** | Grid uses event delegation instead of per-card listeners — handles 100+ apps smoothly |
| **Icon lazy loading** | IntersectionObserver loads app icons only when they scroll into view |
| **Virtual scrolling** | For 100+ apps, only visible cards are rendered — stays fast |
| **LRU icon cache** | Converted icons are cached in memory (200 max) — no redundant `sips` calls |
| **Security-first IPC** | `contextIsolation: true`, `nodeIntegration: false`, preload script with `contextBridge` |
| **macOS 14+ ready** | `entitlements.mac.plist` includes Apple Events permission for app launching |
| **CI/CD ready** | GitHub Actions workflow for automated builds and releases |

---

## 📸 Screenshots

> *Coming soon — once the Electron build is finalized*

---

## 🚀 Quick Start

### Prerequisites

- macOS 10.15+ (Catalina or later)
- Node.js 18+ (LTS recommended)
- Xcode Command Line Tools: `xcode-select --install`

### Install & Run

```bash
# Clone the repository
git clone https://github.com/vopolocc/Mac-Doker.git
cd Mac-Doker

# Install dependencies
npm install

# Run in development mode
npm start

# Build macOS DMG
npm run build
```

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+Shift+A` | Show/Hide the launcher |
| `Cmd+Shift+F` | Focus search box |
| `Cmd+Shift+R` | Refresh app list |
| `/` | Quick focus search |
| `Esc` | Close modals |

---

## 🏗️ Architecture

```
Mac-Doker/
├── src/
│   ├── main/                    # Electron main process (Node.js)
│   │   ├── main.js              # App entry point
│   │   ├── appScanner.js        # Scans /Applications, extracts icons
│   │   ├── dataStore.js         # Persistent storage (electron-store)
│   │   ├── trayManager.js       # System tray management
│   │   ├── shortcutManager.js   # Global hotkeys
│   │   └── windowManager.js     # Window lifecycle
│   ├── renderer/                # UI layer (browser environment)
│   │   ├── index.html           # Main interface
│   │   └── ...
│   └── preload/                 # Secure IPC bridge
│       └── preload.js
├── build/
│   └── entitlements.mac.plist   # macOS sandbox permissions
├── assets/                      # App icons
└── package.json
```

### IPC Communication

All communication between the renderer and main process goes through a secure preload bridge:

```
Renderer (UI)  ←→  Preload (contextBridge)  ←→  Main Process (Node.js)
```

| Channel | Direction | Purpose |
|---|---|---|
| `apps:scan` | Renderer → Main | Scan /Applications directory |
| `apps:launch` | Renderer → Main | Launch an app by name |
| `apps:getIcon` | Renderer → Main | Get app icon as base64 |
| `data:save` | Renderer → Main | Persist user data |
| `data:get` | Renderer → Main | Read stored data |
| `shortcut:focus-search` | Main → Renderer | Focus search input |

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **Electron 28** | Desktop app framework |
| **electron-store** | Encrypted local data persistence |
| **HTML/CSS/JS** | Renderer UI (no framework — fast & lightweight) |
| **macOS native APIs** | App scanning (`plutil`), icon extraction (`sips`), app launching (`open -a`) |
| **electron-builder** | DMG/ZIP packaging for distribution |

---

## 📋 Roadmap

- [x] Application scanning & categorization
- [x] Usage frequency tracking & sorting
- [x] Drag-and-drop reordering
- [x] Pin/unpin favorites
- [x] 3 view modes (default, large, compact)
- [x] System tray integration
- [x] Global keyboard shortcuts
- [ ] Real app icon extraction (icns → PNG)
- [ ] DockThings-style floating dock bar
- [ ] Multi-display support
- [ ] AI-powered auto-classification
- [ ] Launch history timeline
- [ ] Custom themes & color schemes
- [ ] Auto-start on login

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ for Mac users who have too many apps**

</div>
