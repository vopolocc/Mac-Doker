/**
 * src/main/trayManager.js
 * System tray manager
 */

const { Tray, Menu, nativeImage, app } = require('electron');
const path = require('path');

let tray = null;

function createTray(mainWindow) {
  const iconPath = path.join(__dirname, '../../assets/tray-icon.png');
  let trayIcon;

  try {
    trayIcon = nativeImage.createFromPath(iconPath);
  } catch {
    trayIcon = nativeImage.createEmpty();
  }

  trayIcon = trayIcon.resize({ width: 16, height: 16 });

  tray = new Tray(trayIcon);
  tray.setToolTip('Mac Doker');

  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Open Mac Doker',
      click: () => {
        mainWindow.show();
        mainWindow.focus();
      },
    },
    { type: 'separator' },
    {
      label: 'Quick Launch',
      submenu: buildQuickLaunchMenu(),
    },
    { type: 'separator' },
    {
      label: 'Quit',
      accelerator: 'CmdOrCtrl+Q',
      click: () => {
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);

  tray.setContextMenu(contextMenu);

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

function buildQuickLaunchMenu() {
  const quickApps = [
    { name: 'WeChat', id: 'WeChat' },
    { name: 'Chrome', id: 'Google Chrome' },
    { name: 'Lark', id: 'Lark' },
  ];

  return quickApps.map(app => ({
    label: app.name,
    click: () => {
      const { exec } = require('child_process');
      exec(`open -a "${app.id}"`);
    },
  }));
}

module.exports = { createTray };
