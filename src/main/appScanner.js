/**
 * src/main/appScanner.js
 * Application scanner core module
 * Scans /Applications, parses app info, launches apps
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

const execAsync = promisify(exec);

const APP_DIRS = [
  '/Applications',
  '/System/Applications',
  path.join(require('os').homedir(), 'Applications'),
];

async function scan() {
  const allApps = [];
  const seenNames = new Set();

  for (const dir of APP_DIRS) {
    if (!fs.existsSync(dir)) continue;

    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        if (!entry.isDirectory() || !entry.name.endsWith('.app')) continue;

        if (seenNames.has(entry.name)) continue;
        seenNames.add(entry.name);

        const appPath = path.join(dir, entry.name);
        const appInfo = await parseAppInfo(appPath, entry.name);
        if (appInfo) {
          allApps.push(appInfo);
        }
      }
    } catch (err) {
      console.warn(`Failed to scan ${dir}:`, err.message);
    }
  }

  return allApps;
}

async function parseAppInfo(appPath, appName) {
  const infoPlistPath = path.join(appPath, 'Contents', 'Info.plist');

  if (!fs.existsSync(infoPlistPath)) {
    return null;
  }

  try {
    const { stdout } = await execAsync(
      `plutil -extract CFBundleDisplayName json -o - "${infoPlistPath}" 2>/dev/null || ` +
      `plutil -extract CFBundleName json -o - "${infoPlistPath}" 2>/dev/null`
    );

    const displayName = JSON.parse(stdout.trim()) || appName;
    const iconPath = await getIconPath(appPath, infoPlistPath);

    return {
      name: displayName,
      path: appPath,
      icon: iconPath,
      size: await getFolderSize(appPath),
      lastModified: fs.statSync(appPath).mtimeMs,
    };
  } catch (err) {
    return {
      name: appName.replace('.app', ''),
      path: appPath,
      icon: null,
      size: 0,
      lastModified: 0,
    };
  }
}

async function getIconPath(appPath, infoPlistPath) {
  try {
    const { stdout } = await execAsync(
      `plutil -extract CFBundleIconFile json -o - "${infoPlistPath}" 2>/dev/null`
    );
    let iconFile = JSON.parse(stdout.trim());

    if (iconFile) {
      if (!iconFile.endsWith('.icns')) {
        iconFile += '.icns';
      }
      const iconPath = path.join(appPath, 'Contents', 'Resources', iconFile);
      if (fs.existsSync(iconPath)) {
        return iconPath;
      }
    }

    const assetsPath = path.join(appPath, 'Contents', 'Resources', 'Assets.car');
    if (fs.existsSync(assetsPath)) {
      return assetsPath;
    }

    for (const icon of ['AppIcon.icns', 'icon.icns', 'Icon.icns']) {
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

async function getFolderSize(dirPath) {
  try {
    const { stdout } = await execAsync(`du -sk "${dirPath}" 2>/dev/null`);
    return parseInt(stdout.split('\t')[0]) * 1024;
  } catch {
    return 0;
  }
}

function launch(appName) {
  return new Promise((resolve, reject) => {
    exec(`open -a "${appName}"`, (error) => {
      if (error) {
        exec(`osascript -e 'tell application "${appName}" to activate'`, (err2) => {
          if (err2) {
            reject(new Error(`Cannot launch app: ${appName}`));
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

async function getIcon(iconPath) {
  if (!iconPath || !fs.existsSync(iconPath)) {
    return null;
  }

  try {
    if (iconPath.endsWith('.icns')) {
      const tempPng = path.join(require('os').tmpdir(), `icon_${Date.now()}.png`);
      await execAsync(`sips -s format png "${iconPath}" --out "${tempPng}" 2>/dev/null`);

      const data = fs.readFileSync(tempPng);
      fs.unlinkSync(tempPng);

      return `data:image/png;base64,${data.toString('base64')}`;
    }

    const data = fs.readFileSync(iconPath);
    const ext = path.extname(iconPath).slice(1);
    return `data:image/${ext};base64,${data.toString('base64')}`;
  } catch {
    return null;
  }
}

module.exports = { scan, launch, getIcon, parseAppInfo };
