/**
 * src/main/main.js
 * Electron main process entry
 * Responsible for: window creation, lifecycle management, module initialization
 */

const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

const WindowManager = require('./windowManager');
const TrayManager = require('./trayManager');
const ShortcutManager = require('./shortcutManager');
const AppScanner = require('./appScanner');
const DataStore = require('./dataStore');

let mainWindow = null;
let tray = null;

function createMainWindow() {
  mainWindow = WindowManager.createWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    title: 'Mac Doker',
    show: false,
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

  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:3000');
  } else {
    mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  }

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('close', (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
  });

  return mainWindow;
}

app.whenReady().then(async () => {
  await DataStore.init();

  mainWindow = createMainWindow();

  if (process.platform === 'darwin') {
    tray = TrayManager.createTray(mainWindow);
  }

  ShortcutManager.register(mainWindow);
  registerIpcHandlers();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    } else {
      mainWindow.show();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', () => {
  app.isQuitting = true;
});

app.on('will-quit', () => {
  ShortcutManager.unregister();
});

function registerIpcHandlers() {
  ipcMain.handle('apps:scan', async () => {
    try {
      const apps = await AppScanner.scan();
      return { success: true, data: apps };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('apps:launch', async (event, appName) => {
    try {
      await AppScanner.launch(appName);
      DataStore.incrementUsage(appName);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('apps:getIcon', async (event, appPath) => {
    try {
      const icon = await AppScanner.getIcon(appPath);
      return { success: true, data: icon };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('data:save', async (event, key, value) => {
    try {
      DataStore.set(key, value);
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('data:get', async (event, key, defaultValue) => {
    try {
      const value = DataStore.get(key, defaultValue);
      return { success: true, data: value };
    } catch (error) {
      return { success: false, error: error.message };
    }
  });

  ipcMain.handle('system:info', async () => {
    return {
      platform: process.platform,
      arch: process.arch,
      nodeVersion: process.versions.node,
      electronVersion: process.versions.electron,
    };
  });

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
