/**
 * src/preload/preload.js
 * Preload script — secure IPC bridge
 */

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('macDokerAPI', {
  // App operations
  scanApps: () => ipcRenderer.invoke('apps:scan'),
  launchApp: (appName) => ipcRenderer.invoke('apps:launch', appName),
  getAppIcon: (appPath) => ipcRenderer.invoke('apps:getIcon', appPath),

  // Data operations
  saveData: (key, value) => ipcRenderer.invoke('data:save', key, value),
  getData: (key, defaultValue) => ipcRenderer.invoke('data:get', key, defaultValue),

  // System info
  getSystemInfo: () => ipcRenderer.invoke('system:info'),

  // Window controls
  minimizeWindow: () => ipcRenderer.send('window:minimize'),
  maximizeWindow: () => ipcRenderer.send('window:maximize'),
  closeWindow: () => ipcRenderer.send('window:close'),

  // Event listeners
  onFocusSearch: (callback) => ipcRenderer.on('shortcut:focus-search', callback),
  onRefreshApps: (callback) => ipcRenderer.on('shortcut:refresh-apps', callback),
});
