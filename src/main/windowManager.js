/**
 * src/main/windowManager.js
 * Window lifecycle manager
 */

const { BrowserWindow } = require('electron');

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
  };

  return new BrowserWindow({ ...defaults, ...options });
}

module.exports = { createWindow };
