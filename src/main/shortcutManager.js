/**
 * src/main/shortcutManager.js
 * Global shortcut manager
 */

const { globalShortcut } = require('electron');

function register(mainWindow) {
  // Toggle window visibility (Cmd+Shift+A)
  globalShortcut.register('CommandOrControl+Shift+A', () => {
    if (mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      mainWindow.show();
      mainWindow.focus();
    }
  });

  // Focus search (Cmd+Shift+F)
  globalShortcut.register('CommandOrControl+Shift+F', () => {
    mainWindow.show();
    mainWindow.focus();
    mainWindow.webContents.send('shortcut:focus-search');
  });

  // Refresh apps (Cmd+Shift+R)
  globalShortcut.register('CommandOrControl+Shift+R', () => {
    mainWindow.webContents.send('shortcut:refresh-apps');
  });
}

function unregister() {
  globalShortcut.unregisterAll();
}

module.exports = { register, unregister };
